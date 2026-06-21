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
                Label(viewModel.todaysBlocksLabel, systemImage: "circle")
                Spacer()
                Label(viewModel.morasEarnedLabel, systemImage: "circle.grid.2x2")
            }
            .font(.callout)

            HStack(spacing: 8) {
                MoraProgressIndicator(
                    completedCount: viewModel.currentMoraCircleCount,
                    isRestReady: viewModel.isMoraRestReady
                )
                Text(viewModel.currentMoraProgressText)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(viewModel.moraProgressAccessibilityLabel)

            Text(viewModel.moraHelperText)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
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

private struct MoraProgressIndicator: View {
    let completedCount: Int
    let isRestReady: Bool

    private var clampedCompletedCount: Int {
        min(max(completedCount, 0), 4)
    }

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<4, id: \.self) { index in
                ProgressSlot(
                    isFilled: index < clampedCompletedCount,
                    isRestReady: isRestReady
                )
            }
        }
    }
}

private struct ProgressSlot: View {
    let isFilled: Bool
    let isRestReady: Bool

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(.secondary.opacity(isFilled ? 0 : 0.5), lineWidth: 1.4)

            if isFilled {
                Circle()
                    .fill(Color.accentColor.opacity(isRestReady ? 0.95 : 0.75))
                    .padding(2.5)
            }
        }
        .frame(width: 12, height: 12)
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
