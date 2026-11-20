import SwiftUI

public struct WelcomeView: View {
    @State private var message = "Pakiet został poprawnie zaimportowany."

    public init() {}

    public var body: some View {
        VStack(spacing: 20) {
            Text("Moja pierwsza aplikacja")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Swift Playgrounds + GitHub + Codex")
                .multilineTextAlignment(.center)

            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Działa!") {
                message = "Działa! Przycisk zmienił komunikat."
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
