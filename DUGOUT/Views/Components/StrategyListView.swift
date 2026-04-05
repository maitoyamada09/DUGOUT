import SwiftUI
import SwiftData

struct StrategyListView: View {
    @Bindable var viewModel: GameViewModel
    let players: [Player]
    let logs: [StrategyLog]
    let modelContext: ModelContext

    var body: some View {
        let strategies = viewModel.strategiesWithShares(players: players)

        VStack(spacing: 6) {
            HStack {
                Text("作戦（おすすめ度 = 合計100%）")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 16)

            ForEach(strategies) { s in
                StrategyRow(
                    strategy: s,
                    isSelected: viewModel.selectedStrategyId == s.id,
                    onTap: {
                        viewModel.selectStrategy(
                            id: s.id, name: s.name, saber: s.saberText,
                            rate: s.rate, reDelta: s.reDelta
                        )
                    }
                )
            }
        }
    }
}

struct StrategyRow: View {
    let strategy: StrategyResult
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                // Header: name + risk + share%
                HStack(spacing: 6) {
                    // Share percentage (main number)
                    Text("\(strategy.share)%")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundStyle(strategy.enabled ? strategy.shareColor : Color(white: 0.3))
                        .frame(width: 55, alignment: .trailing)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(strategy.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(strategy.enabled ? .white : Color(white: 0.4))

                            // Risk badge
                            Text(strategy.riskLabel)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(strategy.riskColor)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(strategy.riskColor.opacity(0.15))
                                .clipShape(Capsule())
                        }

                        // Share bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(white: 0.15))
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(strategy.shareColor)
                                    .frame(width: max(4, geo.size.width * CGFloat(strategy.share) / 100.0), height: 6)
                            }
                        }
                        .frame(height: 6)
                    }

                    Spacer()

                    // RE delta
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("得点変動")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                        Text(strategy.reDeltaFormatted)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(strategy.reDeltaColor)
                    }
                }

                // MARK: - Key Decision Info (ALWAYS visible, BIG)
                Text(strategy.saberText)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.yellow)
                    .fixedSize(horizontal: false, vertical: true)

                // Expanded detail when selected
                if isSelected {
                    VStack(alignment: .leading, spacing: 6) {
                        // Description
                        Text(strategy.description)
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.8))

                        // Top players
                        if !strategy.topPlayers.isEmpty {
                            HStack(spacing: 8) {
                                Text("向いてる選手:")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.secondary)
                                ForEach(strategy.topPlayers, id: \.name) { tp in
                                    HStack(spacing: 2) {
                                        Text(tp.grade)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(tp.grade == "A" ? .green : tp.grade == "B" ? .yellow : .orange)
                                        Text(tp.name)
                                            .font(.system(size: 11))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                        }

                        // Score breakdown (evidence)
                        if !strategy.reasons.isEmpty {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("この%の根拠:")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.yellow.opacity(0.7))
                                ForEach(strategy.reasons, id: \.self) { reason in
                                    Text("・\(reason)")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(Color(white: 0.55))
                                }
                            }
                            .padding(8)
                            .background(Color(white: 0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.yellow.opacity(0.1) : Color(white: 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.yellow.opacity(0.4) : Color.clear, lineWidth: 1)
                    )
            )
            .opacity(strategy.enabled ? 1 : 0.4)
        }
        .disabled(!strategy.enabled)
        .padding(.horizontal, 12)
    }
}
