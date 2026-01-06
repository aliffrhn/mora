import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.countdownText)
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .monospacedDigit()
            Text(viewModel.statusMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
