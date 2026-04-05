import SwiftUI

// MARK: - Compact Score Bar (top of screen)
struct ScoreboardCard: View {
    @Bindable var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 4) {
            // Row 1: Inning + Score
            HStack(spacing: 0) {
                // Inning
                Button { viewModel.changeInning(-1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 36, height: 44)

                Button { viewModel.state.isTop.toggle() } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.state.innings)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundStyle(.yellow)
                        Image(systemName: viewModel.state.isTop ? "arrow.up" : "arrow.down")
                            .font(.system(size: 10))
                            .foregroundStyle(.yellow)
                    }
                }

                Button { viewModel.changeInning(1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 36, height: 44)

                Spacer()

                // Score (big)
                HStack(spacing: 8) {
                    VStack(spacing: 0) {
                        Text(viewModel.myTeamName)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text("\(viewModel.state.myScore)")
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { viewModel.changeMyScore(1) }
                    .onLongPressGesture { viewModel.changeMyScore(-1) }

                    Text("-")
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(.secondary)

                    VStack(spacing: 0) {
                        Text(viewModel.oppTeamName)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text("\(viewModel.state.oppScore)")
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { viewModel.changeOppScore(1) }
                    .onLongPressGesture { viewModel.changeOppScore(-1) }
                }

                Spacer()

                // WE + RE compact
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(viewModel.winExpectancy >= 60 ? .green : viewModel.winExpectancy >= 40 ? .orange : .red)
                            .frame(width: 5, height: 5)
                        Text("勝率 \(viewModel.winExpectancy)%")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 3) {
                        Circle()
                            .fill(.yellow)
                            .frame(width: 5, height: 5)
                        Text(String(format: "期待 %.2f", viewModel.currentRE))
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.vertical, 4)
        .background(Color(white: 0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 8)
        .padding(.top, 2)
    }
}
