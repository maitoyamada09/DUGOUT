import SwiftUI
import SwiftData

struct ActionBar: View {
    @Bindable var viewModel: GameViewModel
    let players: [Player]
    let logs: [StrategyLog]
    let modelContext: ModelContext

    var body: some View {
        HStack(spacing: 12) {
            if viewModel.isOurOffense {
                // 攻撃時
                Button {
                    viewModel.advanceBatter()
                } label: {
                    Label("次打者", systemImage: "forward.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .background(Color(white: 0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    viewModel.showingSheet = .exec
                } label: {
                    Label(
                        viewModel.selectedStrategyId != nil ? "実行" : "作戦を選択",
                        systemImage: "play.fill"
                    )
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(height: 44)
                    .frame(maxWidth: .infinity)
                    .background(viewModel.selectedStrategyId != nil ? Color.yellow : Color(white: 0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(viewModel.selectedStrategyId == nil)
            } else {
                // 守備時
                Button {
                    viewModel.advanceBatter()
                } label: {
                    Label("次の打者", systemImage: "forward.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .background(Color(white: 0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    viewModel.showingSheet = .pitcherChange
                } label: {
                    Label("投手交代", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .background(Color(white: 0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
