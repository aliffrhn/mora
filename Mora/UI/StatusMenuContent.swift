import SwiftUI
import AppKit

struct StatusMenuContent: View {
    @ObservedObject var viewModel: AppModel
    @ObservedObject var preferences: PreferenceStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            progressSection
            Divider()
            MenuBarView(viewModel: viewModel)
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                controlSection
            }
            .labelStyle(.titleAndIcon)
            Divider()
            quitSection
        }
        .padding(12)
        .frame(width: 240)
    }

    @ViewBuilder
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Today's progress")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Label("\(viewModel.todaysBlocks) circles", systemImage: "circle")
                Spacer()
                Label("\(viewModel.morasEarned) moras", systemImage: "circle.grid.2x2")
            }
            .font(.callout)
            Text("4 circles = 1 mora")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var controlSection: some View {
        if viewModel.isPaused {
            Button(action: viewModel.resume) {
                Label("Resume", systemImage: "play.circle")
            }
            Button(action: viewModel.restart) {
                Label("Restart work session", systemImage: "gobackward")
            }
        } else if viewModel.isRunning {
            Button(action: viewModel.pause) {
                Label("Pause", systemImage: "pause.fill")
            }
            Button(action: viewModel.restart) {
                Label("Restart work session", systemImage: "gobackward")
            }
            Button(action: viewModel.startShortBreak) {
                Label("Start short break", systemImage: "cup.and.saucer")
            }
            Button(action: viewModel.startLongBreak) {
                Label("Start long break", systemImage: "bed.double")
            }
            if viewModel.isOnBreak {
                Button(action: viewModel.skipBreak) {
                    Label("Skip break", systemImage: "forward.fill")
                }
            }
        } else {
            Button(action: viewModel.start) {
                Label("Start focus", systemImage: "play.fill")
            }
        }
    }

    @ViewBuilder
    private var quitSection: some View {
        Button(role: .destructive) {
            NSApplication.shared.terminate(nil)
        } label: {
            Label("Quit Mora", systemImage: "power")
        }
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
