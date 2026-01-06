import SwiftUI

struct RingCountdownView: View {
    var progress: Double
    var lineWidth: CGFloat = 12

    var body: some View {
        ZStack {
            Circle()
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .foregroundStyle(.white.opacity(0.15))
            Circle()
                .trim(from: 0, to: max(0, min(progress, 1)))
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .foregroundStyle(
                    AngularGradient(
                        gradient: Gradient(colors: [.white.opacity(0.9), .white.opacity(0.5), .white.opacity(0.9)]),
                        center: .center
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: progress)
        }
        .frame(width: 220, height: 220)
    }
}
