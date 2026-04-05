import SwiftUI
import SwiftData

/// Briefing-style game summary (Yahoo Baseball play-by-play style)
/// Shows every key play in natural language, organized by inning
struct BriefingView: View {
    let logs: [StrategyLog]
    @Query private var atBatRecords: [AtBatRecord]
    let myTeamName: String
    let oppTeamName: String

    // Group logs by inning half (e.g., "1回表", "1回裏")
    private var groupedByInning: [(key: String, plays: [StrategyLog])] {
        let sorted = logs.sorted { $0.timestamp < $1.timestamp }
        var groups: [(key: String, plays: [StrategyLog])] = []
        var currentKey = ""
        var currentPlays: [StrategyLog] = []

        for log in sorted {
            let key = "\(log.inning)回\(log.isTop ? "表" : "裏")"
            if key != currentKey {
                if !currentPlays.isEmpty {
                    groups.append((key: currentKey, plays: currentPlays))
                }
                currentKey = key
                currentPlays = [log]
            } else {
                currentPlays.append(log)
            }
        }
        if !currentPlays.isEmpty {
            groups.append((key: currentKey, plays: currentPlays))
        }
        return groups
    }

    // Scoring plays only
    private var scoringPlays: [StrategyLog] {
        logs.filter { $0.isSuccess && isScoring($0) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // MARK: - Game Header
                    VStack(spacing: 8) {
                        Text("試合レポート")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 24) {
                            VStack {
                                Text(myTeamName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.yellow)
                                Text("\(logs.last?.myScore ?? 0)")
                                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.white)
                            }
                            Text("-")
                                .font(.system(size: 24))
                                .foregroundStyle(.secondary)
                            VStack {
                                Text(oppTeamName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.red)
                                Text("\(logs.last?.oppScore ?? 0)")
                                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.white)
                            }
                        }

                        if let lastLog = logs.last {
                            Text(lastLog.timestamp, style: .date)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(Color(white: 0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 12)

                    // MARK: - Key Stats Summary
                    VStack(alignment: .leading, spacing: 8) {
                        Text("試合サマリー")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.yellow)

                        let totalPlays = logs.filter { $0.result != "cancel" }.count
                        let successes = logs.filter(\.isSuccess).count
                        let rate = totalPlays > 0 ? Int(Double(successes) / Double(totalPlays) * 100) : 0

                        HStack(spacing: 16) {
                            summaryItem("作戦実行", "\(totalPlays)回")
                            summaryItem("成功率", "\(rate)%")
                            summaryItem("得点", "\(logs.last?.myScore ?? 0)")
                            summaryItem("失点", "\(logs.last?.oppScore ?? 0)")
                        }
                    }
                    .padding(12)
                    .background(Color(white: 0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 12)

                    // MARK: - Scoring Plays
                    if !scoringPlays.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("得点シーン")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.yellow)
                                .padding(.horizontal, 16)

                            ForEach(scoringPlays, id: \.id) { log in
                                playCard(log, highlight: true)
                            }
                        }
                    }

                    // MARK: - Play-by-Play (by inning)
                    ForEach(groupedByInning, id: \.key) { group in
                        VStack(alignment: .leading, spacing: 6) {
                            // Inning header
                            HStack {
                                Text(group.key)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(group.key.contains("表") ? .yellow : .red)

                                Text(group.key.contains("表") ? myTeamName : oppTeamName)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)

                                Spacer()

                                // Score at end of this half
                                if let lastPlay = group.plays.last {
                                    Text("\(lastPlay.myScore)-\(lastPlay.oppScore)")
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                            // Each play
                            ForEach(group.plays, id: \.id) { log in
                                playCard(log, highlight: false)
                            }

                            if group.plays.isEmpty {
                                Text("記録なし")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 16)
                            }
                        }
                    }

                    if logs.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            Text("まだ記録がありません")
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                            Text("試合中に作戦を実行すると\nここにレポートが表示されます")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(white: 0.4))
                                .multilineTextAlignment(.center)
                        }
                        .padding(40)
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color.black)
            .navigationTitle("試合レポート")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Play Card
    @ViewBuilder
    private func playCard(_ log: StrategyLog, highlight: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            // Result indicator
            Circle()
                .fill(log.isSuccess ? .green : log.result == "cancel" ? .gray : .red)
                .frame(width: 10, height: 10)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 3) {
                // Natural language description
                Text(naturalDescription(log))
                    .font(.system(size: 14, weight: highlight ? .bold : .medium))
                    .foregroundStyle(highlight ? .yellow : .white)

                // Context
                HStack(spacing: 8) {
                    Text("\(log.outs)アウト")
                    Text("走者:\(log.runnersText)")
                    Text(log.scoreText)
                }
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)

                // Memo
                if !log.memo.isEmpty {
                    Text(log.memo)
                        .font(.system(size: 11))
                        .foregroundStyle(.yellow.opacity(0.6))
                }
            }

            Spacer()

            Text(log.timestamp, style: .time)
                .font(.system(size: 10))
                .foregroundStyle(Color(white: 0.3))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(highlight ? Color.yellow.opacity(0.06) : Color.clear)
    }

    // MARK: - Natural Language Description
    private func naturalDescription(_ log: StrategyLog) -> String {
        let player = log.playerName.isEmpty ? "打者" : log.playerName
        let result = log.isSuccess ? "成功" : "失敗"

        switch log.strategyId {
        case "power":
            if log.isSuccess {
                return "\(player) — ヒット \(log.runnersText) \(log.scoreText)"
            } else {
                return "\(player) — アウト \(log.scoreText)"
            }

        case "bunt":
            if log.isSuccess {
                return "\(player) — 送りバント\(result)。走者を進めた"
            } else {
                return "\(player) — 送りバント\(result)"
            }

        case "steal":
            if log.isSuccess {
                return "盗塁\(result) ランナーが進塁"
            } else {
                return "盗塁\(result)… ランナーがアウトに"
            }

        case "hitrun":
            if log.isSuccess {
                return "\(player) — エンドラン\(result) 走者も進塁"
            } else {
                return "\(player) — エンドラン\(result)。走者もアウト"
            }

        case "squeeze":
            if log.isSuccess {
                return "\(player) — スクイズ\(result) 3塁走者が生還"
            } else {
                return "\(player) — スクイズ\(result)。3塁走者アウト"
            }

        case "safe":
            if log.isSuccess {
                return "\(player) — セーフティバント\(result) 自分も出塁"
            } else {
                return "\(player) — セーフティバント\(result)"
            }

        case "walk":
            if log.isSuccess {
                return "\(player) — 四球で出塁"
            } else {
                return "\(player) — 三振"
            }

        case "buster":
            if log.isSuccess {
                return "\(player) — バスター\(result) バント構えからヒット"
            } else {
                return "\(player) — バスター\(result)"
            }

        case "firstthird":
            if log.isSuccess {
                return "一三塁プレー\(result) 3塁走者が生還"
            } else {
                return "一三塁プレー\(result)。走者アウト"
            }

        case "pinch":
            return "代打: \(player)"

        case "pinchrun":
            return "代走を起用"

        default:
            return "\(player) — \(log.strategyName) \(result)"
        }
    }

    // Check if a play resulted in scoring
    private func isScoring(_ log: StrategyLog) -> Bool {
        let strats = ["squeeze", "firstthird"]
        if strats.contains(log.strategyId) && log.isSuccess { return true }
        // Check if score changed
        return false
    }

    private func summaryItem(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
