import Foundation
import SwiftUI

private struct Entry: Identifiable, Codable {
    let id: UUID
    let text: String
    let task: Bool
    let due: Date?
    var done: Bool
}

private func suggestedDate(_ text: String) -> Date? {
    let words = text.lowercased().split(whereSeparator: { $0.isWhitespace })
    guard words.count >= 4, words[1] == "o",
          let offset = ["dziś": 0, "dzisiaj": 0, "jutro": 1, "pojutrze": 2][String(words[0])] else { return nil }
    let clock = words[2].split(separator: ":", omittingEmptySubsequences: false)
    guard clock.count == 2, let hour = Int(clock[0]), let minute = Int(clock[1]),
          (0..<24).contains(hour), (0..<60).contains(minute) else { return nil }
    let cal = Calendar.current
    guard let day = cal.date(byAdding: .day, value: offset, to: Date()) else { return nil }
    return cal.date(bySettingHour: hour, minute: minute, second: 0, of: day)
}

public struct WelcomeView: View {
    @AppStorage("pl.notatnik.entries.v1") private var stored = Data()
    @State private var draft = ""
    @State private var task = false
    @State private var error = false

    public init() {}

    private var entries: [Entry]? {
        stored.isEmpty ? [] : try? JSONDecoder().decode([Entry].self, from: stored)
    }

    private func save(_ entries: [Entry]) -> Bool {
        do {
            stored = try JSONEncoder().encode(entries)
            return true
        } catch {
            self.error = true
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
                    }.pickerStyle(.segmented)
                    TextField(task ? "Jutro o 18:30 zadzwoń do mamy" : "Treść notatki", text: $draft, axis: .vertical)
                    if let due {
                        Text("Termin: \(due.formatted(date: .abbreviated, time: .shortened))")
                    }
                    Button("Zapisz") {
                        guard var items = entries else { return }
                        items.insert(Entry(id: UUID(), text: text, task: task, due: due, done: false), at: 0)
                        if save(items) { draft = "" }
                    }.disabled(text.isEmpty || entries == nil)
                }
                Section("Moje wpisy") {
                    if let items = entries {
                        if items.isEmpty { Text("Tu pojawi się Twój pierwszy wpis.").foregroundStyle(.secondary) }
                        ForEach(items) { item in
                            HStack {
                                if item.task {
                                    Button {
                                        guard var latest = entries, let i = latest.firstIndex(where: { $0.id == item.id }) else { return }
                                        latest[i].done.toggle()
                                        _ = save(latest)
                                    } label: {
                                        Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                                    }.accessibilityLabel(item.done ? "Oznacz jako otwarte" : "Oznacz jako wykonane")
                                }
                                VStack(alignment: .leading) {
                                    Text(item.text).strikethrough(item.done)
                                    if let due = item.due {
                                        Text(due.formatted(date: .abbreviated, time: .shortened)).font(.caption)
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
            .alert("Nie udało się zapisać wpisów.", isPresented: $error) { Button("OK") {} }
        }
        .environment(\.locale, Locale(identifier: "pl_PL"))
    }
}
