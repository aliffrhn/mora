import SwiftUI

struct BreakOverlayView: View {
    @ObservedObject var viewModel: BreakOverlayModel

    var body: some View {
        ZStack {
            VisualEffectBlur(material: .underWindowBackground, blendingMode: .withinWindow)
                .opacity(0.9)
            Color.black.opacity(0.35)
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text(viewModel.title.uppercased())
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(viewModel.message)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                }
                RingCountdownView(progress: viewModel.progress)
                    .overlay(
                        Text(viewModel.remainingText)
                            .font(.system(size: 46, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.white)
                    )
                HStack(spacing: 20) {
                    Button(action: viewModel.dismissOverlay) {
                        Label("Hide overlay", systemImage: "eye.slash")
                    }
                    .keyboardShortcut(.escape, modifiers: [])

                    Button(role: .destructive, action: viewModel.skipBreak) {
                        Label("Skip break", systemImage: "forward.end.alt")
                    }
                    .keyboardShortcut("k", modifiers: [.command, .shift])
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.2))
                .labelsHidden()
                .labelStyle(.titleAndIcon)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 80)
        }
        .ignoresSafeArea()
    }
}
