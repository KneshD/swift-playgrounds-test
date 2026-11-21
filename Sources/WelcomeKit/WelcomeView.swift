import AVFoundation
import Combine
import Speech
import SwiftUI

private struct Entry: Identifiable, Codable {
    let id: UUID
    let text: String
    let task: Bool
    let due: Date?
    var done: Bool
    let audioFileName: String?
}

private func suggestedDate(_ text: String) -> Date? {
    let words = text.lowercased().split(whereSeparator: { $0.isWhitespace })
    guard words.count >= 4,
          words[1] == "o",
          let offset = ["dziś": 0, "dzisiaj": 0, "jutro": 1, "pojutrze": 2][String(words[0])] else {
        return nil
    }

    let clock = words[2].split(separator: ":", omittingEmptySubsequences: false)
    guard clock.count == 2,
          let hour = Int(clock[0]),
          let minute = Int(clock[1]),
          (0..<24).contains(hour),
          (0..<60).contains(minute) else {
        return nil
    }

    let calendar = Calendar.current
    guard let day = calendar.date(byAdding: .day, value: offset, to: Date()) else {
        return nil
    }

    return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
}

@MainActor
private final class PolishSpeechRecorder: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    @Published var isRecording = false
    @Published var transcript = ""
    @Published var status = "Gotowe do nagrania"
    @Published var lastRecordingFileName: String?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "pl-PL"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioFile: AVAudioFile?
    private var audioFileURL: URL?

    override init() {
        super.init()
        recognizer?.delegate = self
    }

    func toggle() {
        if isRecording {
            stop()
        } else {
            start()
        }
    }

    private func start() {
        transcript = ""
        lastRecordingFileName = nil
        status = "Proszę mówić po polsku…"

        SFSpeechRecognizer.requestAuthorization { [weak self] authorization in
            Task { @MainActor in
                guard let self else { return }

                guard authorization == .authorized else {
                    self.status = "Brak zgody na rozpoznawanie mowy"
                    return
                }

                let microphoneGranted = await withCheckedContinuation { continuation in
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        continuation.resume(returning: granted)
                    }
                }

                guard microphoneGranted else {
                    self.status = "Brak zgody na mikrofon"
                    return
                }

                self.beginRecognition()
            }
        }
    }

    private func beginRecognition() {
        guard let recognizer, recognizer.isAvailable else {
            status = "Rozpoznawanie mowy jest niedostępne"
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            request = SFSpeechAudioBufferRecognitionRequest()
            guard let request else { return }
            request.shouldReportPartialResults = true
            request.requiresOnDeviceRecognition = true

            let inputNode = audioEngine.inputNode
            let inputFormat = inputNode.outputFormat(forBus: 0)
            let recordingsDirectory = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]
            let recordingURL = recordingsDirectory.appendingPathComponent(
                "nagranie-\(UUID().uuidString).caf"
            )

            audioFile = try AVAudioFile(forWriting: recordingURL, settings: inputFormat.settings)
            audioFileURL = recordingURL

            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1_024, format: inputFormat) { [weak self] buffer, _ in
                self?.request?.append(buffer)
                if let audioFile = self?.audioFile {
                    try? audioFile.write(from: buffer)
                }
            }

            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    guard let self else { return }

                    if let result {
                        self.transcript = result.bestTranscription.formattedString
                    }

                    if error != nil, self.isRecording {
                        self.stop()
                    }
                }
            }

            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
        } catch {
            status = "Nie udało się uruchomić mikrofonu"
            stop()
        }
    }

    private func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        recognitionTask?.finish()
        lastRecordingFileName = audioFileURL?.lastPathComponent
        audioFile = nil
        audioFileURL = nil
        recognitionTask = nil
        request = nil
        isRecording = false
        status = transcript.isEmpty ? "Nie rozpoznano tekstu" : "Transkrypcja gotowa"
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

public struct WelcomeView: View {
    @AppStorage("pl.notatnik.entries.v1") private var stored = Data()
    @StateObject private var recorder = PolishSpeechRecorder()
    @State private var draft = ""
    @State private var task = false
    @State private var showSaveError = false

    public init() {}

    private var entries: [Entry]? {
        stored.isEmpty ? [] : try? JSONDecoder().decode([Entry].self, from: stored)
    }

    private func save(_ entries: [Entry]) -> Bool {
        do {
            stored = try JSONEncoder().encode(entries)
            return true
        } catch {
            showSaveError = true
            return false
        }
    }

    public var body: some View {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        let due = task ? suggestedDate(text) : nil

        NavigationStack {
            List {
                Section("Nowy wpis") {
                    Picker("Rodzaj wpisu", selection: $task) {
                        Text("Notatka").tag(false)
                        Text("Zadanie").tag(true)
                    }
                    .pickerStyle(.segmented)

                    TextField(
                        task ? "Jutro o 18:30 zadzwoń do mamy" : "Treść notatki",
                        text: $draft,
                        axis: .vertical
                    )

                    HStack {
                        Button {
                            recorder.toggle()
                        } label: {
                            Label(
                                recorder.isRecording ? "Zatrzymaj nagranie" : "Nagraj po polsku",
                                systemImage: recorder.isRecording ? "stop.circle.fill" : "mic.circle.fill"
                            )
                        }
                        .buttonStyle(.borderedProminent)

                        Text(recorder.status)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if !recorder.transcript.isEmpty {
                        Button("Wstaw transkrypcję") {
                            draft = recorder.transcript
                        }
                    }

                    if let due {
                        Text("Termin: \(due.formatted(date: .abbreviated, time: .shortened))")
                    }

                    if recorder.lastRecordingFileName != nil {
                        Label("Nagranie zapisane lokalnie", systemImage: "waveform")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button("Zapisz") {
                        guard var items = entries else { return }
                        items.insert(
                            Entry(
                                id: UUID(),
                                text: text,
                                task: task,
                                due: due,
                                done: false,
                                audioFileName: recorder.lastRecordingFileName
                            ),
                            at: 0
                        )
                        if save(items) {
                            draft = ""
                        }
                    }
                    .disabled(text.isEmpty || entries == nil)
                }

                Section("Moje wpisy") {
                    if let items = entries {
                        if items.isEmpty {
                            Text("Tu pojawi się Twój pierwszy wpis.")
                                .foregroundStyle(.secondary)
                        }

                        ForEach(items) { item in
                            HStack {
                                if item.task {
                                    Button {
                                        guard var latest = entries,
                                              let index = latest.firstIndex(where: { $0.id == item.id }) else {
                                            return
                                        }

                                        latest[index].done.toggle()
                                        _ = save(latest)
                                    } label: {
                                        Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                                    }
                                    .accessibilityLabel(
                                        item.done ? "Oznacz jako otwarte" : "Oznacz jako wykonane"
                                    )
                                }

                                VStack(alignment: .leading) {
                                    Text(item.text)
                                        .strikethrough(item.done)

                                    if let due = item.due {
                                        Text(due.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                    }

                                    if item.audioFileName != nil {
                                        Label("Nagranie lokalne", systemImage: "waveform")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    } else {
                        Text("Nie udało się odczytać zapisanych wpisów.")
                    }
                }
            }
            .navigationTitle("Mój notatnik")
            .alert("Nie udało się zapisać wpisów.", isPresented: $showSaveError) {
                Button("OK") {}
            }
        }
        .environment(\.locale, Locale(identifier: "pl_PL"))
    }
}
