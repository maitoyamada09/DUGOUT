import SwiftUI
import SwiftData

struct AtBatCard: View {
    @Bindable var viewModel: GameViewModel
    let players: [Player]
    @Query private var atBatRecords: [AtBatRecord]
    @Query(sort: \StrategyLog.timestamp, order: .reverse) private var strategyLogs: [StrategyLog]

    private var batter: Player? { viewModel.currentBatter(players: players) }
    private var nextBatter: Player? { viewModel.nextBatter(players: players) }
    private var orderNum: Int {
        let lu = viewModel.lineup.compactMap { $0 }
        guard !lu.isEmpty else { return 0 }
        return (viewModel.state.orderIndex % lu.count) + 1
    }

    /// Get stats for a specific player
    private func statsFor(_ player: Player) -> PlayerStats {
        PlayerStats(records: atBatRecords.filter { $0.playerId == player.id })
    }

    /// Get strategy success rate for a player
    private func strategyRate(_ player: Player, _ strategyId: String) -> PlayerStrategyStats {
        PlayerStrategyStats(
            logs: strategyLogs.filter { $0.playerName == player.name },
            strategyId: strategyId
        )
    }

    var body: some View {
        VStack(spacing: 8) {
            if let b = batter {
                // MARK: - Row 1: Name + Stats
                HStack(alignment: .top) {
                    // Left: name & position
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("\(orderNum)番")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.yellow)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.yellow.opacity(0.15))
                                .clipShape(Capsule())
                            Text(b.position)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("#\(b.number)")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(.secondary)
                            Text(b.name.isEmpty ? "未登録" : b.name)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }

                    Spacer()

                    // Right: BA / OBP / OPS (always show)
                    let stats = statsFor(b)
                    if stats.plateAppearances > 0 {
                        // Real stats — BIG font
                        HStack(spacing: 12) {
                            statPill("打率", stats.baText, stats.battingAverage >= 0.300 ? .green : stats.battingAverage >= 0.250 ? .yellow : .orange)
                            statPill("出塁", stats.obpText, stats.onBasePercentage >= 0.400 ? .green : .secondary)
                            statPill("OPS", stats.opsText, stats.ops >= 0.800 ? .green : stats.ops >= 0.650 ? .yellow : .secondary)
                        }
                    } else {
                        // No records yet — show ability rating
                        abilityBadges(player: b)
                    }
                }

                // MARK: - Row 2: Detailed stats line
                let stats = statsFor(b)
                if stats.plateAppearances > 0 {
                    HStack(spacing: 10) {
                        Text(stats.summaryLine)
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white)

                        Spacer()

                        // Strategy success rates
                        let rates: [(String, PlayerStrategyStats)] = [
                            ("犠打", strategyRate(b, "bunt")),
                            ("盗塁", strategyRate(b, "steal")),
                            ("H&R", strategyRate(b, "hitrun")),
                        ].filter { $0.1.total > 0 }

                        ForEach(rates, id: \.0) { label, stat in
                            Text("\(label) \(stat.text)")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundStyle(stat.rate >= 70 ? .green : stat.rate >= 50 ? .yellow : .red)
                        }
                    }
                }

                // MARK: - Row 3: Quick Strategy Buttons
                let topStrategies = viewModel.strategiesWithShares(players: players).prefix(4)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(topStrategies), id: \.id) { s in
                            Button {
                                viewModel.selectStrategy(
                                    id: s.id, name: s.name, saber: s.saberText,
                                    rate: s.rate, reDelta: s.reDelta
                                )
                                viewModel.showingSheet = .exec
                            } label: {
                                HStack(spacing: 4) {
                                    Text("\(s.share)%")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundStyle(s.shareColor)
                                    Text(s.name)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                                .padding(.horizontal, 10)
                                .frame(height: 36)
                                .background(
                                    viewModel.selectedStrategyId == s.id
                                        ? Color.yellow.opacity(0.2)
                                        : Color(white: 0.12)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            viewModel.selectedStrategyId == s.id ? Color.yellow.opacity(0.5) : Color.clear,
                                            lineWidth: 1
                                        )
                                )
                            }
                            .disabled(!s.enabled)
                            .opacity(s.enabled ? 1 : 0.4)
                        }
                    }
                }

                // MARK: - Row 4: Next batter
                if let nb = nextBatter {
                    let nbStats = statsFor(nb)
                    HStack(spacing: 4) {
                        Text("NEXT")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
                        Text("#\(nb.number) \(nb.name)")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(white: 0.5))
                        if nbStats.plateAppearances > 0 {
                            Text(nbStats.baText)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            } else {
                HStack {
                    Text("打順を設定してください")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
        .padding(12)
        .background(Color(white: 0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 12)
    }

    private func statPill(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
        }
        .frame(minWidth: 55)
    }

    @ViewBuilder
    private func abilityBadges(player: Player) -> some View {
        let abilities: [(String, Int)] = [
            ("打", player.hitting),
            ("犠", player.bunting),
            ("走", player.speed),
            ("力", player.power),
            ("四", player.eyeLevel),
            ("盗", player.stealing),
        ]
        HStack(spacing: 3) {
            ForEach(abilities, id: \.0) { label, value in
                VStack(spacing: 1) {
                    Text(label)
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                    Text("\(value)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(gradeColor(value))
                }
                .frame(width: 22)
            }
        }
    }

    private func gradeColor(_ v: Int) -> Color {
        if v >= 4 { return .green }
        if v >= 3 { return .yellow }
        if v >= 2 { return .orange }
        return Color(white: 0.4)
    }
}

struct RecommendationBanner: View {
    @Bindable var viewModel: GameViewModel
    let players: [Player]

    var body: some View {
        let rec = viewModel.recommendation(players: players)
        VStack(alignment: .leading, spacing: 4) {
            Text(rec.title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.yellow)
            Text(rec.body)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.yellow.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 12)
    }
}

// MARK: - Count Leverage (compact inline)
struct CountLeverageCard: View {
    @Bindable var viewModel: GameViewModel

    private var leverage: Double { viewModel.countLeverage }

    var body: some View {
        HStack(spacing: 8) {
            Text("打者有利度 \(Int(leverage * 100))%")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(leverageColor)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(white: 0.12))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(leverageColor)
                        .frame(width: max(4, geo.size.width * barPercent), height: 6)
                }
            }
            .frame(height: 6)

            Text(viewModel.countAdvantageText)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(leverageColor)
                .fixedSize()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color(white: 0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 12)
    }

    private var barPercent: CGFloat {
        // Map 0.63-1.73 to 0.0-1.0
        CGFloat(min(1, max(0, (leverage - 0.5) / 1.3)))
    }

    private var leverageColor: Color {
        if leverage >= 1.3 { return .green }
        if leverage >= 1.1 { return Color(red: 0.4, green: 0.85, blue: 0.2) }
        if leverage <= 0.7 { return .red }
        if leverage <= 0.85 { return .orange }
        return .yellow
    }
}
