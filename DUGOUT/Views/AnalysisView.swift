import SwiftUI
import SwiftData

struct AnalysisView: View {
    @Bindable var viewModel: GameViewModel
    let players: [Player]
    let logs: [StrategyLog]
    @Query private var atBatRecords: [AtBatRecord]

    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Section tabs
                Picker("", selection: $selectedTab) {
                    Text("チーム").tag(0)
                    Text("選手別").tag(1)
                    Text("作戦別").tag(2)
                    Text("状況別").tag(3)
                    Text("ログ").tag(4)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                ScrollView {
                    switch selectedTab {
                    case 0: teamDashboard
                    case 1: playerRankings
                    case 2: strategyAnalysis
                    case 3: situationalAnalysis
                    case 4: logView
                    default: EmptyView()
                    }
                }
            }
            .background(Color.black)
            .navigationTitle("分析")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Helper: our team records
    private var ourRecords: [AtBatRecord] {
        atBatRecords.filter { !$0.isOpponent }
    }
    private var ourStats: PlayerStats {
        PlayerStats(records: ourRecords)
    }
    private var oppRecords: [AtBatRecord] {
        atBatRecords.filter { $0.isOpponent }
    }
    private var oppStats: PlayerStats {
        PlayerStats(records: oppRecords)
    }

    // MARK: - 1. Team Dashboard
    private var teamDashboard: some View {
        VStack(spacing: 12) {
            // Team vs Opponent comparison
            sectionHeader("チーム成績")

            HStack(spacing: 0) {
                // Our team
                VStack(spacing: 8) {
                    Text("自チーム")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.yellow)
                    bigStat(ourStats.baText, label: "打率", color: .yellow)
                    bigStat(ourStats.opsText, label: "OPS", color: .yellow)
                    bigStat("\(ourStats.hits)/\(ourStats.atBats)", label: "安打/打数", color: .white)
                    bigStat("\(ourStats.homeRuns)", label: "本塁打", color: .white)
                    bigStat("\(ourStats.walks)", label: "四球", color: .white)
                    bigStat("\(ourStats.strikeouts)", label: "三振", color: .red)
                }
                .frame(maxWidth: .infinity)

                // Divider
                Rectangle()
                    .fill(Color(white: 0.2))
                    .frame(width: 1)
                    .padding(.vertical, 8)

                // Opponent team
                VStack(spacing: 8) {
                    Text("相手チーム")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.red)
                    bigStat(oppStats.baText, label: "打率", color: .red)
                    bigStat(oppStats.opsText, label: "OPS", color: .red)
                    bigStat("\(oppStats.hits)/\(oppStats.atBats)", label: "安打/打数", color: .white)
                    bigStat("\(oppStats.homeRuns)", label: "本塁打", color: .white)
                    bigStat("\(oppStats.walks)", label: "四球", color: .white)
                    bigStat("\(oppStats.strikeouts)", label: "三振", color: .green)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(16)
            .background(Color(white: 0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 12)

            // Strategy overview
            sectionHeader("作戦の成績")
            strategyOverviewGrid
        }
        .padding(.bottom, 20)
    }

    // Strategy overview grid
    private var strategyOverviewGrid: some View {
        let strategyIds = ["power", "bunt", "steal", "hitrun", "squeeze", "safe", "buster", "runhit", "delayed", "firstthird"]
        let strategyNames: [String: String] = [
            "power": "バッティング", "bunt": "バント", "steal": "盗塁",
            "hitrun": "エンドラン", "squeeze": "スクイズ", "safe": "セーフティ",
            "buster": "バスター", "runhit": "ランエンドヒット",
            "delayed": "ディレード", "firstthird": "一三塁"
        ]

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(strategyIds, id: \.self) { sid in
                let sLogs = logs.filter { $0.strategyId == sid && $0.result != "cancel" }
                let successes = sLogs.filter(\.isSuccess).count
                let total = sLogs.count
                let rate = total > 0 ? Int(Double(successes) / Double(total) * 100) : 0

                if total > 0 {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(strategyNames[sid] ?? sid)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                            Text("\(successes)/\(total)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(rate)%")
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundStyle(rate >= 70 ? .green : rate >= 50 ? .yellow : .red)
                    }
                    .padding(10)
                    .background(Color(white: 0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(.horizontal, 12)
    }

    // MARK: - 2. Player Rankings
    private var playerRankings: some View {
        VStack(spacing: 12) {
            sectionHeader("打率ランキング")
            playerRankingList(sortBy: { statsFor($0).battingAverage > statsFor($1).battingAverage }, statLabel: { p in
                let s = statsFor(p)
                return "\(s.baText) (\(s.hits)/\(s.atBats))"
            })

            sectionHeader("OPSランキング")
            playerRankingList(sortBy: { statsFor($0).ops > statsFor($1).ops }, statLabel: { p in
                let s = statsFor(p)
                return "\(s.opsText)"
            })

            sectionHeader("本塁打ランキング")
            playerRankingList(sortBy: { statsFor($0).homeRuns > statsFor($1).homeRuns }, statLabel: { p in
                let s = statsFor(p)
                return "\(s.homeRuns)本"
            })

            sectionHeader("出塁率ランキング")
            playerRankingList(sortBy: { statsFor($0).onBasePercentage > statsFor($1).onBasePercentage }, statLabel: { p in
                let s = statsFor(p)
                return s.obpText
            })
        }
        .padding(.bottom, 20)
    }

    @ViewBuilder
    private func playerRankingList(sortBy: @escaping (Player, Player) -> Bool, statLabel: @escaping (Player) -> String) -> some View {
        let rankedPlayers = players
            .filter { statsFor($0).plateAppearances > 0 }
            .sorted(by: sortBy)

        if rankedPlayers.isEmpty {
            Text("まだデータがありません")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
        } else {
            VStack(spacing: 4) {
                ForEach(Array(rankedPlayers.prefix(10).enumerated()), id: \.element.id) { index, player in
                    HStack(spacing: 8) {
                        Text("\(index + 1)")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundStyle(index == 0 ? .yellow : index <= 2 ? .white : .secondary)
                            .frame(width: 28)

                        Text("#\(player.number)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(.yellow)

                        Text(player.name.isEmpty ? "未入力" : player.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)

                        Spacer()

                        Text(statLabel(player))
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundStyle(index == 0 ? .yellow : .white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(index == 0 ? Color.yellow.opacity(0.08) : Color.clear)
                }
            }
            .padding(.vertical, 4)
            .background(Color(white: 0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 12)
        }
    }

    // MARK: - 3. Strategy Analysis
    private var strategyAnalysis: some View {
        VStack(spacing: 12) {
            sectionHeader("作戦別の詳細分析")

            let strategyIds = ["power", "bunt", "steal", "hitrun", "squeeze", "safe", "buster"]
            let strategyNames: [String: String] = [
                "power": "バッティング", "bunt": "バント", "steal": "盗塁",
                "hitrun": "エンドラン", "squeeze": "スクイズ", "safe": "セーフティ",
                "buster": "バスター"
            ]

            ForEach(strategyIds, id: \.self) { sid in
                let sLogs = logs.filter { $0.strategyId == sid && $0.result != "cancel" }
                let total = sLogs.count
                if total > 0 {
                    strategyDetailCard(
                        name: strategyNames[sid] ?? sid,
                        logs: sLogs
                    )
                }
            }

            if logs.isEmpty {
                Text("まだデータがありません。\n試合で作戦を実行するとここに分析が表示されます。")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(20)
            }
        }
        .padding(.bottom, 20)
    }

    @ViewBuilder
    private func strategyDetailCard(name: String, logs: [StrategyLog]) -> some View {
        let successes = logs.filter(\.isSuccess).count
        let total = logs.count
        let rate = total > 0 ? Int(Double(successes) / Double(total) * 100) : 0

        // By inning
        let earlyLogs = logs.filter { $0.inning <= 3 }
        let midLogs = logs.filter { $0.inning >= 4 && $0.inning <= 6 }
        let lateLogs = logs.filter { $0.inning >= 7 }

        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text(name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(rate)%")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(rate >= 70 ? .green : rate >= 50 ? .yellow : .red)
            }

            Text("\(successes)成功 / \(total)回実行")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            // By inning breakdown
            HStack(spacing: 12) {
                inningBreakdown("序盤(1-3)", logs: earlyLogs)
                inningBreakdown("中盤(4-6)", logs: midLogs)
                inningBreakdown("終盤(7+)", logs: lateLogs)
            }

            // Top players for this strategy
            let playerNames = Set(logs.map(\.playerName)).filter { !$0.isEmpty }
            if !playerNames.isEmpty {
                HStack(spacing: 8) {
                    Text("選手別:")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                    ForEach(Array(playerNames.prefix(4)), id: \.self) { name in
                        let pLogs = logs.filter { $0.playerName == name }
                        let pSucc = pLogs.filter(\.isSuccess).count
                        let pRate = pLogs.count > 0 ? Int(Double(pSucc) / Double(pLogs.count) * 100) : 0
                        Text("\(name) \(pSucc)/\(pLogs.count)(\(pRate)%)")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(pRate >= 70 ? .green : pRate >= 50 ? .yellow : .red)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(white: 0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 12)
    }

    @ViewBuilder
    private func inningBreakdown(_ label: String, logs: [StrategyLog]) -> some View {
        let total = logs.count
        let successes = logs.filter(\.isSuccess).count
        let rate = total > 0 ? Int(Double(successes) / Double(total) * 100) : 0

        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.secondary)
            if total > 0 {
                Text("\(rate)%")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(rate >= 70 ? .green : rate >= 50 ? .yellow : .red)
                Text("\(successes)/\(total)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.secondary)
            } else {
                Text("-")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(white: 0.3))
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 4. Situational Analysis
    private var situationalAnalysis: some View {
        VStack(spacing: 12) {
            // By runner situation
            sectionHeader("走者状況別の成績")
            let runnerKeys = ["000", "100", "010", "001", "110", "101", "011", "111"]
            let runnerNames: [String: String] = [
                "000": "ランナーなし", "100": "1塁", "010": "2塁", "001": "3塁",
                "110": "1・2塁", "101": "1・3塁", "011": "2・3塁", "111": "満塁"
            ]

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(runnerKeys, id: \.self) { key in
                    let rLogs = logs.filter { $0.runnersKey == key && $0.result != "cancel" }
                    if !rLogs.isEmpty {
                        let successes = rLogs.filter(\.isSuccess).count
                        let rate = Int(Double(successes) / Double(rLogs.count) * 100)

                        HStack {
                            Text(runnerNames[key] ?? key)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(rate)%")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundStyle(rate >= 70 ? .green : rate >= 50 ? .yellow : .red)
                            Text("(\(rLogs.count))")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(Color(white: 0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.horizontal, 12)

            // By out count
            sectionHeader("アウト数別の成績")
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { outs in
                    let oLogs = logs.filter { $0.outs == outs && $0.result != "cancel" }
                    let successes = oLogs.filter(\.isSuccess).count
                    let total = oLogs.count
                    let rate = total > 0 ? Int(Double(successes) / Double(total) * 100) : 0

                    VStack(spacing: 4) {
                        Text("\(outs)アウト")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                        Text("\(rate)%")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundStyle(rate >= 70 ? .green : rate >= 50 ? .yellow : .red)
                        Text("\(successes)/\(total)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(Color(white: 0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal, 12)

            // By inning
            sectionHeader("イニング別の成績")
            HStack(spacing: 8) {
                inningPeriodCard("序盤(1-3)", logs: logs.filter { $0.inning <= 3 && $0.result != "cancel" })
                inningPeriodCard("中盤(4-6)", logs: logs.filter { $0.inning >= 4 && $0.inning <= 6 && $0.result != "cancel" })
                inningPeriodCard("終盤(7+)", logs: logs.filter { $0.inning >= 7 && $0.result != "cancel" })
            }
            .padding(.horizontal, 12)

            // Hit type breakdown
            sectionHeader("打撃内容の内訳")
            let hitTypes: [(String, String, Color)] = [
                ("シングル", "single", .green),
                ("ツーベース", "double", .green),
                ("スリーベース", "triple", .green),
                ("ホームラン", "homerun", .yellow),
                ("四球", "walk", .blue),
                ("三振", "strikeout", .red),
                ("ゴロアウト", "groundout", .orange),
                ("フライアウト", "flyout", .orange),
                ("併殺", "doubleplay", .red),
            ]

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(hitTypes, id: \.1) { name, resultId, color in
                    let count = ourRecords.filter { $0.result == resultId }.count
                    if count > 0 {
                        VStack(spacing: 2) {
                            Text("\(count)")
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundStyle(color)
                            Text(name)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color(white: 0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.horizontal, 12)
        }
        .padding(.bottom, 20)
    }

    // MARK: - 5. Log View
    private var logView: some View {
        VStack(spacing: 8) {
            if logs.isEmpty {
                Text("まだ記録がありません")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .padding(40)
            } else {
                ForEach(logs, id: \.id) { log in
                    logRow(log)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 20)
    }

    // MARK: - Helpers
    private func statsFor(_ player: Player) -> PlayerStats {
        PlayerStats(records: atBatRecords.filter { $0.playerId == player.id && !$0.isOpponent })
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.yellow)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func inningPeriodCard(_ label: String, logs: [StrategyLog]) -> some View {
        let successes = logs.filter(\.isSuccess).count
        let total = logs.count
        let rate = total > 0 ? Int(Double(successes) / Double(total) * 100) : 0

        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
            Text(total > 0 ? "\(rate)%" : "-")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundStyle(total == 0 ? Color(white: 0.3) : rate >= 70 ? .green : rate >= 50 ? .yellow : .red)
            if total > 0 {
                Text("\(successes)/\(total)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color(white: 0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func bigStat(_ value: String, label: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func logRow(_ log: StrategyLog) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(log.isSuccess ? .green : log.result == "cancel" ? .gray : .red)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(log.strategyName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                    if !log.playerName.isEmpty {
                        Text(log.playerName)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                HStack(spacing: 6) {
                    Text("\(log.inning)回\(log.isTop ? "表" : "裏")")
                    Text("\(log.outs)アウト")
                    Text(log.runnersText)
                    Text(log.scoreText)
                }
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(log.timestamp, style: .time)
                .font(.system(size: 10))
                .foregroundStyle(Color(white: 0.3))
        }
        .padding(8)
        .background(Color(white: 0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
