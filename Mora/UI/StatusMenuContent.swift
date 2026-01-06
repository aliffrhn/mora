import SwiftUI
import AppKit

struct StatusMenuContent: View {
    @ObservedObject var viewModel: AppModel
    @ObservedObject var preferences: PreferenceStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            MenuBarView(viewModel: viewModel)
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Button(action: viewModel.start) {
                    Label("Start focus", systemImage: "play.fill")
                }
                .disabled(viewModel.isRunning && !viewModel.isPaused)

                Button(action: viewModel.pause) {
                    Label("Pause", systemImage: "pause.fill")
                }
                .disabled(!viewModel.isRunning || viewModel.isPaused)

                Button(action: viewModel.resume) {
                    Label("Resume", systemImage: "play.circle")
                }
                .disabled(!viewModel.isPaused)

                Button(action: viewModel.restart) {
                    Label("Restart phase", systemImage: "gobackward")
                }
                .disabled(!(viewModel.isRunning || viewModel.isPaused))

                Button(action: viewModel.skipBreak) {
                    Label("Skip break", systemImage: "forward.fill")
                }
                .disabled(!viewModel.isOnBreak)
                Button(role: .destructive) {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Label("Quit Mora", systemImage: "power")
                }
            }
            .labelStyle(.titleAndIcon)
            Divider()
            VStack(alignment: .leading, spacing: 6) {
                Text("Today's progress")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Label("\(viewModel.todaysBlocks) blocks", systemImage: "checkmark.circle")
                    Spacer()
                    Label("\(viewModel.morasEarned) moras", systemImage: "circle.hexagonpath")
                }
                .font(.callout)
                Toggle(isOn: $preferences.soundEnabled) {
                    Label("Play sounds", systemImage: preferences.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                }
                .toggleStyle(.switch)
            }
        }
        .padding(12)
        .frame(width: 240)
    }
}

struct SettingsView: View {
    @ObservedObject var preferences: PreferenceStore

    var body: some View {
        Form {
            Toggle("Play sounds", isOn: $preferences.soundEnabled)
        }
        .toggleStyle(.switch)
        .padding()
    }
}
