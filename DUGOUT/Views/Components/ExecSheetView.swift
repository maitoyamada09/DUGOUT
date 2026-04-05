import SwiftUI
import SwiftData

struct ExecSheetView: View {
    @Bindable var viewModel: GameViewModel
    let players: [Player]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var atBatResult: String = ""
    @State private var memo: String = ""
    @State private var step: Int = 1  // 1=結果選択, 2=ランナー進塁, 3=完了
    // ランナー進塁先: [0]=1塁ランナーの行き先, [1]=2塁, [2]=3塁  (0=そのまま, 1=次の塁, 2=2つ先, 3=ホームイン)
    @State private var runnerDestinations: [Int] = [0, 0, 0]

    private var batter: Player? { viewModel.currentBatter(players: players) }

    private var isBattingStrategy: Bool {
        let id = viewModel.selectedStrategyId ?? ""
        return ["power", "bunt", "safe", "hitrun", "squeeze", "buster", "walk"].contains(id)
    }

    private var isStealStrategy: Bool {
        let id = viewModel.selectedStrategyId ?? ""
        return ["steal", "delayed", "runhit", "firstthird"].contains(id)
    }

    /// ランナー進塁の選択が必要か？（ヒット系 + ランナーがいる場合）
    private var needsRunnerChoice: Bool {
        let hitResults = ["single", "single_score", "double", "double_score", "triple", "error", "fielderschoice"]
        return hitResults.contains(atBatResult) && viewModel.state.bases.contains(true)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                // Header
                HStack {
                    Text(viewModel.selectedStrategyName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.yellow)
                    if let b = batter {
                        Text("#\(b.number) \(b.name)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Text("\(viewModel.state.innings) \(viewModel.state.outs)アウト")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.top, 6)

                // 打撃結果を選択
                ScrollView {
                    VStack(spacing: 8) {
                        strategyResultButtons

                        // ランナー進塁選択（ヒット系を選んだら展開）
                        if needsRunnerChoice && !atBatResult.isEmpty {
                            Divider().background(Color(white: 0.2)).padding(.horizontal, 14)

                            Text("ランナーはどうなった？")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.yellow)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 14)

                            runnerChoiceView
                        }

                        // メモ
                        if !atBatResult.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 5) {
                                    ForEach(memoPresets, id: \.self) { preset in
                                        Button {
                                            if memo.contains(preset) {
                                                memo = memo.replacingOccurrences(of: preset, with: "").trimmingCharacters(in: .whitespaces)
                                            } else {
                                                memo = memo.isEmpty ? preset : "\(memo) \(preset)"
                                            }
                                        } label: {
                                            Text(preset)
                                                .font(.system(size: 10, weight: .medium))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 5)
                                                .background(memo.contains(preset) ? Color.yellow.opacity(0.2) : Color(white: 0.12))
                                                .foregroundStyle(memo.contains(preset) ? .yellow : .secondary)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                                .padding(.horizontal, 12)
                            }
                        }
                    }
                }

                // 記録ボタン
                if !atBatResult.isEmpty {
                    Button {
                        if needsRunnerChoice {
                            saveAllWithRunners()
                        } else {
                            saveAll()
                        }
                        dismiss()
                    } label: {
                        Text("記録する")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(height: 48)
                            .frame(maxWidth: .infinity)
                            .background(Color.yellow)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 14)
                }

                Spacer(minLength: 0)
            }
            .padding(.bottom, 12)
            .background(Color.black)
            .navigationTitle("結果を記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Strategy-Specific Result Buttons
    @ViewBuilder
    private var strategyResultButtons: some View {
        let sid = viewModel.selectedStrategyId ?? ""

        VStack(alignment: .leading, spacing: 10) {
            switch sid {

            // バッティング — context-aware results based on runners
            case "power":
                let hasRunners = viewModel.state.bases.contains(true)
                if hasRunners {
                    // With runners: show runner-specific outcomes
                    resultSection(title: "打撃結果", successItems: [
                        ("単打（走者進塁）", "single"),
                        ("単打（走者生還）", "single_score"),
                        ("二塁打", "double"),
                        ("二塁打（走者生還）", "double_score"),
                        ("三塁打", "triple"),
                        ("本塁打", "homerun"),
                        ("四球", "walk"),
                        ("死球", "hitbypitch"),
                        ("エラー出塁", "error"),
                    ], failItems: [
                        ("ゴロアウト", "groundout"),
                        ("フライアウト", "flyout"),
                        ("犠飛（走者生還）", "sacfly"),
                        ("三振", "strikeout"),
                        ("併殺", "doubleplay"),
                    ])
                } else {
                    // No runners: simple results
                    resultSection(title: "打撃結果", successItems: [
                        ("シングル", "single"),
                        ("ツーベース", "double"),
                        ("スリーベース", "triple"),
                        ("ホームラン", "homerun"),
                        ("四球", "walk"),
                        ("死球", "hitbypitch"),
                        ("エラー出塁", "error"),
                    ], failItems: [
                        ("ゴロアウト", "groundout"),
                        ("フライアウト", "flyout"),
                        ("三振", "strikeout"),
                    ])
                }

            // バント
            case "bunt":
                resultSection(title: "バント結果", successItems: [
                    ("成功（走者進塁）", "sacrifice"),
                ], failItems: [
                    ("失敗（ファウル）", "groundout"),
                    ("失敗（野手正面）", "flyout"),
                    ("バント空振り", "strikeout"),
                ])

            // セーフティバント
            case "safe":
                resultSection(title: "セーフティ結果", successItems: [
                    ("出塁成功", "single"),
                    ("走者も進塁", "single"),
                ], failItems: [
                    ("自分アウト（走者進塁）", "sacrifice"),
                    ("自分アウト（走者戻る）", "groundout"),
                ])

            // バスター
            case "buster":
                resultSection(title: "バスター結果", successItems: [
                    ("シングル", "single"), ("ツーベース", "double"),
                    ("ホームラン", "homerun"),
                ], failItems: [
                    ("ゴロアウト", "groundout"),
                    ("フライアウト", "flyout"),
                    ("犠飛（走者生還）", "sacfly"),
                    ("三振", "strikeout"),
                    ("併殺", "doubleplay"),
                ])

            // スクイズ
            case "squeeze":
                resultSection(title: "スクイズ結果", successItems: [
                    ("成功（走者生還）", "sacrifice"),
                ], failItems: [
                    ("失敗（走者アウト）", "squeeze_fail"),
                    ("ファウル", "strikeout"),
                    ("空振り", "strikeout"),
                ])

            // ヒットエンドラン
            case "hitrun":
                resultSection(title: "エンドラン結果", successItems: [
                    ("ヒット（走者進塁）", "single"),
                    ("ツーベース", "double"),
                ], failItems: [
                    ("空振り（走者アウト）", "strikeout_runner"),
                    ("ゴロ（併殺）", "doubleplay"),
                    ("フライアウト", "flyout"),
                    ("犠飛（走者生還）", "sacfly"),
                ])

            // 四球狙い
            case "walk":
                resultSection(title: "結果", successItems: [
                    ("四球", "walk"),
                    ("死球", "hitbypitch"),
                ], failItems: [
                    ("見逃し三振", "strikeout"),
                    ("手を出してアウト", "groundout"),
                ])

            // 盗塁系
            case "steal", "delayed", "runhit", "firstthird":
                resultSection(title: "走塁結果", successItems: [
                    ("成功（セーフ）", "steal_ok"),
                ], failItems: [
                    ("失敗（アウト）", "steal_ng"),
                ])

            // 代打・代走・敬遠
            default:
                resultSection(title: "結果", successItems: [
                    ("成功", "ok"),
                ], failItems: [
                    ("失敗", "ng"),
                    ("中止", "cancel"),
                ])
            }
        }
    }

    /// Build result section — compact grid, no scrolling needed
    @ViewBuilder
    private func resultSection(
        title: String,
        successItems: [(String, String)],
        failItems: [(String, String)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Success grid
            LazyVGrid(columns: [
                GridItem(.flexible()), GridItem(.flexible()),
                GridItem(.flexible()), GridItem(.flexible())
            ], spacing: 6) {
                ForEach(successItems, id: \.1) { label, value in
                    resultChip(label: label, value: value, color: .green)
                }
            }
            .padding(.horizontal, 12)

            // Fail grid
            LazyVGrid(columns: [
                GridItem(.flexible()), GridItem(.flexible()),
                GridItem(.flexible()), GridItem(.flexible())
            ], spacing: 6) {
                ForEach(failItems, id: \.1) { label, value in
                    resultChip(label: label, value: value, color: .red)
                }
            }
            .padding(.horizontal, 12)
        }
    }

    // MARK: - Result Chip Button (compact)
    private func resultChip(label: String, value: String, color: Color) -> some View {
        Button {
            atBatResult = value
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 48)
                .padding(.horizontal, 4)
                .background(atBatResult == value ? color : color.opacity(0.12))
                .foregroundStyle(atBatResult == value ? .black : color)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Runner Choice View
    @ViewBuilder
    private var runnerChoiceView: some View {
        VStack(spacing: 10) {
            // 各ランナーの行き先を選択
            if viewModel.state.bases[2] {
                // 3塁ランナー
                runnerRow(baseLabel: "3塁ランナー", runnerIndex: 2, options: [
                    ("3塁に残る", 0),
                    ("ホームイン", 3),
                ])
            }
            if viewModel.state.bases[1] {
                // 2塁ランナー
                runnerRow(baseLabel: "2塁ランナー", runnerIndex: 1, options: [
                    ("3塁へ", 1),
                    ("ホームイン", 2),
                ])
            }
            if viewModel.state.bases[0] {
                // 1塁ランナー
                runnerRow(baseLabel: "1塁ランナー", runnerIndex: 0, options: [
                    ("2塁へ", 1),
                    ("3塁へ", 2),
                    ("ホームイン", 3),
                ])
            }
        }
        .padding(.horizontal, 12)
    }

    @ViewBuilder
    private func runnerRow(baseLabel: String, runnerIndex: Int, options: [(String, Int)]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(baseLabel)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)

            HStack(spacing: 6) {
                ForEach(options, id: \.1) { label, value in
                    Button {
                        runnerDestinations[runnerIndex] = value
                    } label: {
                        Text(label)
                            .font(.system(size: 13, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(
                                runnerDestinations[runnerIndex] == value
                                    ? (value >= 2 ? Color.green : Color.yellow)
                                    : Color(white: 0.12)
                            )
                            .foregroundStyle(
                                runnerDestinations[runnerIndex] == value ? .black : .white
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(8)
        .background(Color(white: 0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Save with manual runner positions
    private func saveAllWithRunners() {
        let strategyId = viewModel.selectedStrategyId ?? ""

        // Determine success/fail
        let hitIds = AtBatRecord.hitResults.map(\.id) + ["single_score", "double_score"]
        let strategyResult = hitIds.contains(atBatResult) ? "ok" : "ng"

        // Save strategy log
        let log = StrategyLog(
            inning: viewModel.state.inning,
            isTop: viewModel.state.isTop,
            outs: viewModel.state.outs,
            runnersKey: viewModel.state.runnersKey,
            myScore: viewModel.state.myScore,
            oppScore: viewModel.state.oppScore,
            strategyId: strategyId,
            strategyName: viewModel.selectedStrategyName,
            playerName: batter?.name ?? "",
            estimatedRate: viewModel.selectedStrategyRate,
            reDelta: viewModel.selectedStrategyREDelta,
            reAtTime: viewModel.currentRE,
            result: strategyResult,
            memo: memo
        )
        modelContext.insert(log)

        // Save at-bat record
        if let b = batter {
            let record = AtBatRecord(
                playerId: b.id,
                playerName: b.name,
                result: atBatResult,
                strategyId: strategyId,
                inning: viewModel.state.inning,
                isTop: viewModel.state.isTop
            )
            modelContext.insert(record)
        }

        // Apply runner movements based on user choices
        var actionParts: [String] = []

        // Process runners from 3rd → 1st (to avoid conflicts)
        // 3塁ランナー
        if viewModel.state.bases[2] {
            if runnerDestinations[2] >= 3 {
                viewModel.state.bases[2] = false
                viewModel.state.myScore += 1
                actionParts.append("3塁→ホームイン")
            }
            // else stays at 3rd
        }

        // 2塁ランナー
        if viewModel.state.bases[1] {
            if runnerDestinations[1] >= 2 {
                viewModel.state.bases[1] = false
                viewModel.state.myScore += 1
                actionParts.append("2塁→ホームイン")
            } else if runnerDestinations[1] == 1 {
                viewModel.state.bases[1] = false
                viewModel.state.bases[2] = true
                actionParts.append("2塁→3塁")
            }
        }

        // 1塁ランナー
        if viewModel.state.bases[0] {
            if runnerDestinations[0] >= 3 {
                viewModel.state.bases[0] = false
                viewModel.state.myScore += 1
                actionParts.append("1塁→ホームイン")
            } else if runnerDestinations[0] == 2 {
                viewModel.state.bases[0] = false
                viewModel.state.bases[2] = true
                actionParts.append("1塁→3塁")
            } else if runnerDestinations[0] == 1 {
                viewModel.state.bases[0] = false
                viewModel.state.bases[1] = true
                actionParts.append("1塁→2塁")
            }
        }

        // Batter placement based on hit type
        switch atBatResult {
        case "single", "single_score", "error", "fielderschoice":
            viewModel.state.bases[0] = true
            actionParts.append("打者→1塁")
        case "double", "double_score":
            viewModel.state.bases[1] = true
            actionParts.append("打者→2塁")
        case "triple":
            viewModel.state.bases[2] = true
            actionParts.append("打者→3塁")
        default:
            break
        }

        // Set action log
        viewModel.lastActionLog = actionParts.joined(separator: " / ")

        // 攻撃時は相手投手の投球数を加算
        if viewModel.isOurOffense {
            viewModel.oppPitcherPitchCount += 1
        }

        viewModel.state.resetCount()
        viewModel.advanceBatter()
        viewModel.clearSelection()
        viewModel.checkInningChange()
    }

    private var memoPresets: [String] {
        ["完璧","惜しい","打球速い","ファウル","空振り",
         "見逃し","牽制刺","走塁ミス","守備ミス","判断良い",
         "流れ変わる","プレッシャー","相手動揺","作戦変更"]
    }

    // MARK: - Save
    private func saveAll() {
        let strategyId = viewModel.selectedStrategyId ?? ""

        // Determine success/fail for strategy log
        let strategyResult: String
        if atBatResult == "cancel" {
            strategyResult = "cancel"
        } else if isStealStrategy {
            strategyResult = atBatResult == "steal_ok" ? "ok" : "ng"
        } else if isBattingStrategy {
            // Hit results = success, out results = fail
            let hitIds = AtBatRecord.hitResults.map(\.id) + ["single_score", "double_score"]
            strategyResult = hitIds.contains(atBatResult) ? "ok" : "ng"
        } else {
            strategyResult = atBatResult == "ok" ? "ok" : (atBatResult == "ng" ? "ng" : "cancel")
        }

        // 1. Save StrategyLog
        let log = StrategyLog(
            inning: viewModel.state.inning,
            isTop: viewModel.state.isTop,
            outs: viewModel.state.outs,
            runnersKey: viewModel.state.runnersKey,
            myScore: viewModel.state.myScore,
            oppScore: viewModel.state.oppScore,
            strategyId: strategyId,
            strategyName: viewModel.selectedStrategyName,
            playerName: batter?.name ?? "",
            estimatedRate: viewModel.selectedStrategyRate,
            reDelta: viewModel.selectedStrategyREDelta,
            reAtTime: viewModel.currentRE,
            result: strategyResult,
            memo: memo
        )
        modelContext.insert(log)

        // 2. Save AtBatRecord (if batting strategy with specific result)
        if isBattingStrategy && atBatResult != "cancel", let b = batter {
            let record = AtBatRecord(
                playerId: b.id,
                playerName: b.name,
                result: atBatResult,
                strategyId: strategyId,
                inning: viewModel.state.inning,
                isTop: viewModel.state.isTop
            )
            modelContext.insert(record)
        }

        // 3. Update game state
        if strategyResult != "cancel" {
            if isBattingStrategy {
                applyBattingResult(atBatResult: atBatResult, strategyId: strategyId)
            } else if isStealStrategy {
                if strategyResult == "ok" {
                    applyStealSuccess(strategyId: strategyId)
                } else {
                    applyStealFail(strategyId: strategyId)
                }
            }
        }

        // 攻撃時は相手投手の投球数を加算
        if viewModel.isOurOffense {
            viewModel.oppPitcherPitchCount += 1
        }

        viewModel.clearSelection()
        viewModel.checkInningChange()
    }

    // MARK: - Apply batting result to game state
    private func applyBattingResult(atBatResult: String, strategyId: String) {
        switch atBatResult {
        case "single":
            // Single, runners advance 1 base (normal)
            advanceRunners(by: 1)
            viewModel.state.bases[0] = true
            viewModel.state.resetCount()
            viewModel.advanceBatter()

        case "single_score":
            // Single where runners score (fast runner, 2nd→home, 3rd→home)
            scoreAllRunners()
            viewModel.state.bases[0] = true
            viewModel.state.resetCount()
            viewModel.advanceBatter()

        case "double":
            // Double, runners advance 2 bases (normal)
            advanceRunners(by: 2)
            viewModel.state.bases[0] = false
            viewModel.state.bases[1] = true
            viewModel.state.resetCount()
            viewModel.advanceBatter()

        case "double_score":
            // Double where all runners score
            scoreAllRunners()
            viewModel.state.bases[0] = false
            viewModel.state.bases[1] = true
            viewModel.state.resetCount()
            viewModel.advanceBatter()

        case "triple":
            scoreAllRunners()
            viewModel.state.bases = [false, false, true]
            viewModel.state.resetCount()
            viewModel.advanceBatter()

        case "homerun":
            scoreAllRunners()
            viewModel.state.myScore += 1
            viewModel.state.bases = [false, false, false]
            viewModel.state.resetCount()
            viewModel.advanceBatter()

        case "walk", "hitbypitch":
            // Force runners if bases occupied
            if viewModel.state.bases[0] && viewModel.state.bases[1] && viewModel.state.bases[2] {
                viewModel.state.myScore += 1
            }
            if viewModel.state.bases[0] && viewModel.state.bases[1] {
                viewModel.state.bases[2] = true
            }
            if viewModel.state.bases[0] {
                viewModel.state.bases[1] = true
            }
            viewModel.state.bases[0] = true
            viewModel.state.resetCount()
            viewModel.advanceBatter()

        case "error", "fielderschoice":
            // Batter reaches 1st, runners advance 1
            advanceRunners(by: 1)
            viewModel.state.bases[0] = true
            viewModel.state.resetCount()
            viewModel.advanceBatter()

        case "squeeze_fail":
            // Squeeze fail: runner at 3rd tagged out
            if viewModel.state.bases[2] {
                viewModel.state.bases[2] = false
            }
            viewModel.state.outs = min(3, viewModel.state.outs + 1)
            viewModel.state.resetCount()
            viewModel.advanceBatter()

        case "groundout", "flyout", "strikeout":
            viewModel.state.outs = min(3, viewModel.state.outs + 1)
            viewModel.state.resetCount()
            viewModel.advanceBatter()

        case "doubleplay", "strikeout_runner":
            // Double play or strikeout with runner caught
            viewModel.state.outs = min(3, viewModel.state.outs + 2)
            if viewModel.state.bases[0] {
                viewModel.state.bases[0] = false
            }
            viewModel.state.resetCount()
            viewModel.advanceBatter()

        case "sacrifice":
            // Runners advance, batter out
            advanceRunners(by: 1)
            viewModel.state.outs = min(3, viewModel.state.outs + 1)
            viewModel.state.resetCount()
            viewModel.advanceBatter()

        case "sacfly":
            // Runner on 3rd scores, batter out
            if viewModel.state.bases[2] {
                viewModel.state.bases[2] = false
                viewModel.state.myScore += 1
            }
            viewModel.state.outs = min(3, viewModel.state.outs + 1)
            viewModel.state.resetCount()
            viewModel.advanceBatter()

        default:
            break
        }
    }

    // MARK: - Runner advancement helpers
    private func advanceRunners(by bases: Int) {
        for _ in 0..<bases {
            if viewModel.state.bases[2] {
                viewModel.state.myScore += 1
                viewModel.state.bases[2] = false
            }
            if viewModel.state.bases[1] {
                viewModel.state.bases[2] = true
                viewModel.state.bases[1] = false
            }
            if viewModel.state.bases[0] {
                viewModel.state.bases[1] = true
                viewModel.state.bases[0] = false
            }
        }
    }

    private func scoreAllRunners() {
        for i in 0..<3 {
            if viewModel.state.bases[i] {
                viewModel.state.myScore += 1
                viewModel.state.bases[i] = false
            }
        }
    }

    // MARK: - Steal success/fail
    private func applyStealSuccess(strategyId: String) {
        switch strategyId {
        case "firstthird":
            if viewModel.state.bases[2] {
                viewModel.state.bases[2] = false
                viewModel.state.myScore += 1
            }
            if viewModel.state.bases[0] {
                viewModel.state.bases[0] = false
                viewModel.state.bases[1] = true
            }
        default:
            // Regular steal: advance lead runner
            if viewModel.state.bases[2] {
                viewModel.state.bases[2] = false
                viewModel.state.myScore += 1
            }
            if viewModel.state.bases[1] {
                viewModel.state.bases[1] = false
                viewModel.state.bases[2] = true
            }
            if viewModel.state.bases[0] {
                viewModel.state.bases[0] = false
                viewModel.state.bases[1] = true
            }
        }
    }

    private func applyStealFail(strategyId: String) {
        switch strategyId {
        case "firstthird":
            if viewModel.state.bases[0] {
                viewModel.state.bases[0] = false
            }
        default:
            if viewModel.state.bases[1] {
                viewModel.state.bases[1] = false
            } else if viewModel.state.bases[0] {
                viewModel.state.bases[0] = false
            }
        }
        viewModel.state.outs = min(3, viewModel.state.outs + 1)
    }
}
