import Foundation
import SwiftUI

@Observable
final class GameViewModel {

    // MARK: - State
    var state = GameState()
    var myTeamName: String = ""
    var oppTeamName: String = ""
    var lineup: [UUID?] = Array(repeating: nil, count: 9)

    // MARK: - Opponent Lineup
    var oppLineup: [UUID?] = Array(repeating: nil, count: 9)
    var oppOrderIndex: Int = 0

    /// Are we on offense (our turn to bat) or defense?
    var isOurOffense: Bool { state.isTop }

    /// Last action description (shown on screen)
    var lastActionLog: String? = nil

    // MARK: - Undo History
    private var stateHistory: [(state: GameState, oppOrderIndex: Int, log: String?)] = []
    var canUndo: Bool { !stateHistory.isEmpty }

    /// Save current state before making a change
    func saveSnapshot() {
        stateHistory.append((state: state, oppOrderIndex: oppOrderIndex, log: lastActionLog))
        // Keep max 30 steps
        if stateHistory.count > 30 { stateHistory.removeFirst() }
    }

    /// Undo last action
    func undo() {
        guard let previous = stateHistory.popLast() else { return }
        state = previous.state
        oppOrderIndex = previous.oppOrderIndex
        lastActionLog = "↩ 1つ前に戻しました"
    }

    // MARK: - Our Pitcher Tracking (守備時)
    var currentPitcherId: UUID? = nil
    var currentPitcherName: String = ""
    var currentInningPitchCount: Int = 0
    var totalPitchCount: Int = 0
    var pitcherOutsRecorded: Int = 0

    // MARK: - Opponent Pitcher Tracking (攻撃時)
    var oppPitcherName: String = ""
    var oppPitcherNumber: String = ""
    var oppPitcherPitchCount: Int = 0
    var oppPitcherTags: [String] = []

    /// 投球回数テキスト（例: "5.2" = 5回2/3）
    var pitcherInningsText: String {
        let full = pitcherOutsRecorded / 3
        let remainder = pitcherOutsRecorded % 3
        if remainder == 0 { return "\(full).0" }
        return "\(full).\(remainder)"
    }

    /// 投球1球追加
    func addPitch() {
        totalPitchCount += 1
        currentInningPitchCount += 1
    }

    /// 投手がアウトを記録（投球回数加算）
    func recordPitcherOut(count: Int = 1) {
        pitcherOutsRecorded += count
    }

    // MARK: - Game Flow
    var gameStarted: Bool = false
    var totalInnings: Int = 7
    var showInningChange: Bool = false
    var gameEnded: Bool = false

    // MARK: - Selected Strategy
    var selectedStrategyId: String? = nil
    var selectedStrategyName: String = ""
    var selectedStrategySaber: String = ""
    var selectedStrategyRate: Int = 0
    var selectedStrategyREDelta: Double = 0

    // MARK: - Sheet
    var showingSheet: SheetType? = nil

    enum SheetType: Identifiable {
        case players, opponent, lineup, analysis, exec, gameSetup, pitcherChange
        var id: String {
            switch self {
            case .players: return "players"
            case .opponent: return "opponent"
            case .lineup: return "lineup"
            case .analysis: return "analysis"
            case .exec: return "exec"
            case .gameSetup: return "gameSetup"
            case .pitcherChange: return "pitcherChange"
            }
        }
    }

    // MARK: - Game Flow Logic

    /// Check if 3 outs → show チェンジ prompt or end game
    func checkInningChange() {
        guard state.outs >= 3 else { return }

        let isLastInning = state.inning >= totalInnings

        if state.isTop {
            // 表（our offense）ended with 3 outs
            if isLastInning && state.myScore < state.oppScore {
                // We're losing after our last at-bat in final inning top → game over
                // (But we still need to play the bottom if we're home)
                // Actually in standard baseball: top ends, bottom still happens
                showInningChange = true
            } else {
                showInningChange = true
            }
        } else {
            // 裏（opponent offense）ended with 3 outs
            if isLastInning {
                if state.myScore != state.oppScore {
                    // Game over — someone is ahead after full inning
                    gameEnded = true
                    return
                }
                // Tied → extra innings (continue)
                showInningChange = true
            } else {
                showInningChange = true
            }
        }
    }

    /// Check for walk-off (サヨナラ) — call when score changes during bottom half
    func checkWalkOff() {
        let isLastInningOrLater = state.inning >= totalInnings
        if !state.isTop && isLastInningOrLater && state.myScore > state.oppScore {
            // サヨナラ — home team takes the lead in the bottom of the last inning
            gameEnded = true
            showInningChange = false
        }
    }

    /// Execute the inning change
    func performInningChange() {
        saveSnapshot()
        state.outs = 0
        state.bases = [false, false, false]
        state.resetCount()
        selectedStrategyId = nil

        if state.isTop {
            // 表 → 裏 (same inning number)
            state.isTop = false

            // Check: if this is the last inning bottom and we're already ahead, skip
            let isLastInning = state.inning >= totalInnings
            if isLastInning && state.myScore > state.oppScore {
                // We're ahead going into the bottom — game over (no need to play bottom)
                // Actually in baseball: home team doesn't bat if they're ahead.
                // But in our app 表=our offense, 裏=opponent offense
                // If we're ahead, the opponent still bats in the bottom
                // Game only ends if they don't catch up (after their 3 outs)
            }
        } else {
            // 裏 → 表 of next inning
            state.isTop = true
            state.inning += 1
        }

        showInningChange = false
    }

    /// Start a new game
    func startNewGame(myTeam: String, oppTeam: String, innings: Int) {
        myTeamName = myTeam
        oppTeamName = oppTeam
        totalInnings = innings
        state = GameState()
        gameStarted = true
        gameEnded = false
        showInningChange = false
        selectedStrategyId = nil
    }

    /// Reset game completely
    func resetGame() {
        gameStarted = false
        gameEnded = false
        state = GameState()
        showInningChange = false
        selectedStrategyId = nil
        currentPitcherId = nil
        currentPitcherName = ""
        totalPitchCount = 0
        currentInningPitchCount = 0
        pitcherOutsRecorded = 0
        oppPitcherName = ""
        oppPitcherNumber = ""
        oppPitcherPitchCount = 0
        oppPitcherTags = []
        oppOrderIndex = 0
        lastActionLog = nil
    }

    /// Progress display: "1回表 (1/7)"
    var progressText: String {
        "\(state.innings) (\(state.inning)/\(totalInnings))"
    }

    // MARK: - Computed
    var currentRE: Double {
        Sabermetrics.runExpectancy(runnersKey: state.runnersKey, outs: state.outs)
    }
    var winExpectancy: Int {
        Sabermetrics.winExpectancy(inning: state.inning, scoreDiff: state.diff)
    }
    var buntDelta: (delta: Double, before: Double, after: Double, possible: Bool) {
        Sabermetrics.buntExpectedRunDelta(runnersKey: state.runnersKey, outs: state.outs)
    }
    var stolenBaseBreakeven: Int {
        Sabermetrics.stolenBaseBreakevenRate(outs: state.outs, stealTarget: currentStealTarget)
    }
    var countLeverage: Double {
        Sabermetrics.countLeverageMultiplier(balls: state.balls, strikes: state.strikes)
    }
    var countAdvantageText: String {
        Sabermetrics.countAdvantageText(balls: state.balls, strikes: state.strikes)
    }

    // Determine steal target based on runner positions
    var currentStealTarget: Sabermetrics.StealTarget {
        let h1 = state.bases[0], h2 = state.bases[1], h3 = state.bases[2]
        if h1 && h2 { return .double }
        if h2 && !h3 { return .third }
        if h3 { return .home }
        return .second
    }

    // MARK: - Score
    func changeMyScore(_ d: Int)  { saveSnapshot(); state.myScore  = max(0, state.myScore  + d) }
    func changeOppScore(_ d: Int) { saveSnapshot(); state.oppScore = max(0, state.oppScore + d) }
    func changeInning(_ d: Int)   { saveSnapshot(); state.inning   = max(1, min(15, state.inning + d)) }

    // MARK: - Bases / Outs / Count
    func tapBase(_ base: Int) {
        saveSnapshot()
        state.bases[base - 1].toggle()
        let baseName = ["1塁", "2塁", "3塁"][base - 1]
        if state.bases[base - 1] {
            lastActionLog = "ランナー\(baseName)に出塁 → 走者: \(runnersText)"
        } else {
            lastActionLog = "\(baseName)ランナー消滅 → 走者: \(runnersText)"
        }
    }
    func tapOut(at i: Int)    { saveSnapshot(); state.outs = (state.outs == i + 1) ? 0 : i + 1 }
    func tapBall(at i: Int)   { saveSnapshot(); state.balls   = (state.balls   == i + 1) ? 0 : i + 1 }
    func tapStrike(at i: Int) { saveSnapshot(); state.strikes = (state.strikes == i + 1) ? 0 : i + 1 }
    func resetCount()         { state.balls = 0; state.strikes = 0 }

    var runnersText: String {
        let r = zip([1,2,3], state.bases).filter(\.1).map { "\($0.0)塁" }
        return r.isEmpty ? "なし" : r.joined(separator: "・")
    }

    // MARK: - Our Batter (offense)
    func currentBatter(players: [Player]) -> Player? {
        let lu = lineup.compactMap { $0 }
        guard !lu.isEmpty else { return nil }
        return players.first { $0.id == lu[state.orderIndex % lu.count] }
    }
    func nextBatter(players: [Player]) -> Player? {
        let lu = lineup.compactMap { $0 }
        guard !lu.isEmpty else { return nil }
        let ni = (state.orderIndex + 1) % lu.count
        return players.first { $0.id == lu[ni] }
    }
    func advanceBatter() {
        saveSnapshot()
        if isOurOffense {
            let lu = lineup.compactMap { $0 }
            guard !lu.isEmpty else { return }
            state.orderIndex = (state.orderIndex + 1) % lu.count
        } else {
            let lu = oppLineup.compactMap { $0 }
            guard !lu.isEmpty else { return }
            oppOrderIndex = (oppOrderIndex + 1) % lu.count
        }
        resetCount()
        selectedStrategyId = nil
    }

    // MARK: - Opponent Batter (defense)
    func currentOppBatter(opponents: [OpponentPlayer]) -> OpponentPlayer? {
        let lu = oppLineup.compactMap { $0 }
        guard !lu.isEmpty else { return nil }
        return opponents.first { $0.id == lu[oppOrderIndex % lu.count] }
    }
    func nextOppBatter(opponents: [OpponentPlayer]) -> OpponentPlayer? {
        let lu = oppLineup.compactMap { $0 }
        guard !lu.isEmpty else { return nil }
        let ni = (oppOrderIndex + 1) % lu.count
        return opponents.first { $0.id == lu[ni] }
    }
    var oppOrderNum: Int {
        let lu = oppLineup.compactMap { $0 }
        guard !lu.isEmpty else { return 0 }
        return (oppOrderIndex % lu.count) + 1
    }

    // MARK: - Strategy
    func selectStrategy(id: String, name: String, saber: String, rate: Int, reDelta: Double) {
        selectedStrategyId = (selectedStrategyId == id) ? nil : id
        if selectedStrategyId != nil {
            selectedStrategyName = name
            selectedStrategySaber = saber
            selectedStrategyRate = rate
            selectedStrategyREDelta = reDelta
        }
    }
    func clearSelection() { selectedStrategyId = nil }

    func calculateStrategies(players: [Player]) -> [StrategyResult] {
        let p = currentBatter(players: players)
        let re = currentRE
        let bd = buntDelta
        let sbBE = stolenBaseBreakeven
        let cl = countLeverage
        let hasR = state.bases.contains(true)
        let h1 = state.bases[0], h2 = state.bases[1], h3 = state.bases[2]

        // 能力値取得（0 = 未設定 → 計算には3を使うがUIには表示しない）
        func a(_ kp: KeyPath<Player, Int>) -> Int {
            let v = p?[keyPath: kp] ?? 3
            return v == 0 ? 3 : v
        }
        // 実際の値（UIに表示する用。0なら「未設定」と表示）
        func raw(_ kp: KeyPath<Player, Int>) -> String {
            let v = p?[keyPath: kp] ?? 0
            return v == 0 ? "未設定" : "\(v)"
        }
        let hasAbilityData = (p?.hitting ?? 0) > 0

        let stealRate = min(92, 20 + a(\.stealing) * 10 + a(\.speed) * 4)
        let isLateClose = state.inning >= 7 && abs(state.diff) <= 1

        // Bunt analysis with real MLB data
        let buntAnalysis = Sabermetrics.isBuntRecommended(
            runnersKey: state.runnersKey, outs: state.outs,
            inning: state.inning, scoreDiff: state.diff,
            batterStrength: a(\.hitting), isAmateur: false
        )

        return [
            // 1. 送りバント — with detailed MLB/amateur data
            StrategyResult(
                id: "bunt", name: "送りバント", risk: .low,
                enabled: state.outs < 2 && hasR,
                rate: min(92, 45 + (a(\.bunting)) * 10),
                reDelta: bd.delta,
                saberText: bd.possible
                    ? String(format: "得点期待: %.2f → %.2f点（%+.2f）%@",
                             bd.before, bd.after, bd.delta,
                             buntAnalysis.recommended ? " ★おすすめ" : "")
                    : "2アウトでは使えません",
                description: buntAnalysis.reason,
                playerKey: \.bunting, showBreakeven: false,
                topPlayers: topPlayers(players: players, key: \.bunting)
            ),
            // 2. 盗塁 — separate break-even by target base
            StrategyResult(
                id: "steal", name: "盗塁（\(currentStealTarget.rawValue)）", risk: .mid,
                enabled: h1 || h2,  // Can only steal if runner on 1st or 2nd
                rate: stealRate,
                reDelta: stealRate >= sbBE ? 0.2 : -0.45,
                saberText: "\(currentStealTarget.rawValue)盗塁: 成功\(sbBE)%以上必要 / この選手の推定\(stealRate)%\(stealRate >= sbBE ? " ★走れる" : " ✕危険")",
                description: currentStealTarget == .double
                    ? "2人同時に走る。\(sbBE)%以上の成功率が必要。成功すれば大チャンス。"
                    : currentStealTarget == .third
                    ? "3塁を狙う。\(sbBE)%以上の成功率が必要。リスクが高いので注意。"
                    : "2塁を狙う。成功率\(sbBE)%以上なら走る価値あり。",
                playerKey: \.stealing, showBreakeven: true,
                topPlayers: topPlayers(players: players, key: \.stealing)
            ),
            // 3. セーフティバント
            StrategyResult(
                id: "safe", name: "セーフティ", risk: .mid,
                enabled: state.outs < 2 && hasR,
                rate: min(80, 20 + (a(\.safetyBunt)) * 8 + (a(\.speed)) * 4),
                reDelta: 0.1,
                saberText: "出塁+走者進塁を同時に狙う",
                description: hasAbilityData ? "セーフティ技術\(raw(\.safetyBunt)) / 走力\(raw(\.speed))" : "選手データ未登録",
                playerKey: \.safetyBunt, showBreakeven: false,
                topPlayers: topPlayers(players: players, key: \.safetyBunt)
            ),
            // 4. ヒットエンドラン — NPB research data
            StrategyResult(
                id: "hitrun", name: "ヒットエンドラン", risk: .high,
                enabled: hasR && state.outs < 2,
                rate: min(80, 10 + (a(\.hitting)) * 10 + (a(\.speed)) * 4),
                reDelta: 0.2,
                saberText: "期待得点: エンドラン0.95 > 打撃0.86 > バント0.73（併殺回避+30%）",
                description: hasAbilityData ? "打力\(raw(\.hitting))の選手。カウント\(state.balls)-\(state.strikes)" : "走者スタート+打者スイングの同時プレー",
                playerKey: \.hitting, showBreakeven: false,
                topPlayers: topPlayers(players: players, key: \.hitting)
            ),
            // 5. スクイズ — with WP lift data
            StrategyResult(
                id: "squeeze", name: "スクイズ", risk: .high,
                enabled: h3 && state.outs < 2,
                rate: min(85, 25 + (a(\.bunting)) * 12),
                reDelta: 0.5,
                saberText: state.outs == 1
                    ? "1アウト時の損益分岐点: 70%。バント技術\(a(\.bunting))"
                    : "0アウト時の損益分岐点: 87%。犠飛でも得点可能な状況。",
                description: "成功時: 3塁走者が生還(+1点)。失敗時: 3塁走者アウト。勝率\(winExpectancy)%",
                playerKey: \.bunting, showBreakeven: false,
                topPlayers: topPlayers(players: players, key: \.bunting)
            ),
            // 6. バッティング — with count leverage + 待て instruction
            StrategyResult(
                id: "power", name: "バッティング", risk: .mid,
                enabled: true,
                rate: min(80, 10 + (a(\.hitting)) * 9 + (a(\.power)) * 5),
                reDelta: 0.05,
                saberText: String(format: "得点期待 %.2f点 / カウント\(state.balls)-\(state.strikes)", re),
                description: cl >= 1.3
                    ? "打者有利なカウント"
                    : cl <= 0.7
                    ? "投手有利なカウント"
                    : "標準的なカウント",
                playerKey: \.hitting, showBreakeven: false,
                topPlayers: topPlayers(players: players, key: \.hitting)
            ),
            // 7. 四球狙い — with count data
            StrategyResult(
                id: "walk", name: "四球狙い", risk: .low,
                enabled: state.balls >= 2,
                rate: min(78, 20 + (a(\.eyeLevel)) * 10),
                reDelta: (Sabermetrics.runExpectancy(runnersKey: state.bases[0] ? "110" : "100", outs: state.outs)) - re,
                saberText: String(format: "四球で得点期待 %.2f → %.2f点に上がる",
                    re,
                    Sabermetrics.runExpectancy(runnersKey: state.bases[0] ? "110" : "100", outs: state.outs)),
                description: state.balls >= 3
                    ? "カウント\(state.balls)-\(state.strikes)。四球確率が高い状況。"
                    : "ボール先行カウント。選球眼\(a(\.eyeLevel))",
                playerKey: \.eyeLevel, showBreakeven: false,
                topPlayers: topPlayers(players: players, key: \.eyeLevel)
            ),
            // 8. 代打 — with platoon split data
            StrategyResult(
                id: "pinch", name: "代打", risk: .low,
                enabled: true,
                rate: max(30, min(75, (a(\.hitting)) <= 2 ? 60 : 35)),
                reDelta: 0.05,
                saberText: "投打の利き手が逆なら打者が有利になる",
                description: isLateClose
                    ? "\(state.innings)、\(abs(state.diff))点差。" + (p?.batHand != nil ? "現打者: \(p?.batHand ?? "")" : "")
                    : hasAbilityData ? "現打者の打力: \(raw(\.hitting))" : "控え選手と交代する選択肢",
                playerKey: \.hitting, showBreakeven: false,
                topPlayers: topPlayers(players: players, key: \.hitting)
            ),
            // 10. バスター（フェイクバント→打つ）
            StrategyResult(
                id: "buster", name: "バスター", risk: .mid,
                enabled: state.outs < 2 && hasR,
                rate: min(75, 15 + (a(\.hitting)) * 8 + (a(\.bunting)) * 4),
                reDelta: 0.15,
                saberText: "バント構え→ヒッティング。守備のシフトを利用する",
                description: hasAbilityData ? "打力\(raw(\.hitting)) / バント\(raw(\.bunting))" : "バントシフト時に有効",
                playerKey: \.hitting, showBreakeven: false,
                topPlayers: topPlayers(players: players, key: \.hitting)
            ),
            // 11. ヒットエンドラン（走者スタート、打者は振っても振らなくてもOK）
            StrategyResult(
                id: "runhit", name: "ヒットエンドラン", risk: .mid,
                enabled: h1 || h2,
                rate: min(80, 15 + (a(\.stealing)) * 8 + (a(\.speed)) * 5),
                reDelta: 0.15,
                saberText: "走者はスタート、打者はいい球だけ振る。エンドランより安全",
                description: "走者が盗塁スタート。打者はボール球なら振らなくてOK。足の速い走者向き。",
                playerKey: \.stealing, showBreakeven: false,
                topPlayers: topPlayers(players: players, key: \.stealing)
            ),
            // 12. ディレードスチール（遅れて走る）
            StrategyResult(
                id: "delayed", name: "ディレードスチール", risk: .mid,
                enabled: h1 || h2,
                rate: min(75, 20 + (a(\.speed)) * 8 + (a(\.stealing)) * 4),
                reDelta: 0.15,
                saberText: "キャッチャーの返球時に走る。相手の油断を突く作戦",
                description: "投球時ではなく、捕手→投手の返球時にスタート。相手の隙を狙う。アマチュアで効果的。",
                playerKey: \.speed, showBreakeven: false,
                topPlayers: topPlayers(players: players, key: \.speed)
            ),
            // 10. 代走
            StrategyResult(
                id: "pinchrun", name: "代走", risk: .low,
                enabled: hasR,
                rate: max(30, min(70, 20 + (a(\.speed)) <= 2 ? 60 : 30)),
                reDelta: 0.1,
                saberText: "足の遅いランナーを足の速い選手に交代",
                description: isLateClose
                    ? "★終盤の接戦。足の速い代走で盗塁・得点の可能性を上げろ。"
                    : "遅いランナーを速い選手に交代。盗塁やエンドランが使えるようになる。",
                playerKey: \.speed, showBreakeven: false,
                topPlayers: topPlayers(players: players, key: \.speed)
            ),
            // 17. 一三塁プレー（トリックプレー）
            StrategyResult(
                id: "firstthird", name: "一三塁プレー", risk: .high,
                enabled: h1 && h3,
                rate: min(65, 15 + (a(\.speed)) * 6 + (a(\.stealing)) * 6),
                reDelta: 0.4,
                saberText: "1塁走者が走る→送球の隙に3塁走者がホームへ",
                description: "1塁ランナーが盗塁スタート。相手が2塁に投げたら3塁ランナーが本塁突入。高校野球の定番。",
                playerKey: \.speed, showBreakeven: false,
                topPlayers: topPlayers(players: players, key: \.speed)
            ),
        ]
    }

    /// Calculate situation-weighted recommendation shares (sum to 100%)
    /// Uses sabermetrics data to push supervisor toward the analytically correct choice
    func strategiesWithShares(players: [Player]) -> [StrategyResult] {
        var strategies = calculateStrategies(players: players)
        let p = currentBatter(players: players)
        let cl = countLeverage
        let bd = buntDelta
        let hasR = state.bases.contains(true)
        let h3 = state.bases[2]
        let isLateClose = state.inning >= 7 && abs(state.diff) <= 1
        let isBehindBig = state.diff <= -3 && state.isLate

        // Helper: get ability value, treat 0 (unset) as 3 (average)
        func ability(_ kp: KeyPath<Player, Int>) -> Int {
            let v = p?[keyPath: kp] ?? 3
            return v == 0 ? 3 : v
        }

        // Score each strategy with reasons explaining why
        var scoreResults: [(score: Double, reasons: [String])] = strategies.map { s in
            guard s.enabled else { return (0, ["使用条件を満たしていない"]) }
            var score = 0.0
            var r: [String] = []

            switch s.id {

            case "power":
                score = 50; r.append("基本スコア: 50（バッティングは基本戦術）")
                if ability(\.hitting) >= 4 { score += 15; r.append("打力4以上: +15") }
                else if ability(\.hitting) >= 3 { score += 5; r.append("打力3: +5") }
                if ability(\.power) >= 4 { score += 10; r.append("パワー4以上: +10") }
                if cl >= 1.3 { score += 20; r.append("打者有利カウント(\(state.balls)-\(state.strikes)): +20") }
                else if cl >= 1.1 { score += 5; r.append("やや打者有利: +5") }
                if isBehindBig { score += 20; r.append("大量ビハインド終盤: +20（打つしかない）") }
                if !hasR { score += 10; r.append("ランナーなし: +10（まず出塁）") }

            case "bunt":
                score = 5; r.append("基本スコア: 5（バントはデータ上不利なことが多い）")
                if isBehindBig { score = 1; r.append("大量ビハインド: →1（バント不可）"); return (score, r) }
                if bd.delta < -0.15 { score = 2; r.append("得点期待が大きく下がる(\(String(format: "%+.2f", bd.delta))): →2"); return (score, r) }
                if bd.delta > -0.05 { score += 10; r.append("得点期待の低下が小さい: +10") }
                if ability(\.hitting) <= 2 && isLateClose { score += 15; r.append("弱打者＋終盤接戦: +15") }
                if ability(\.bunting) >= 4 { score += 5; r.append("バント技術4以上: +5") }

            case "steal":
                let sbBE = stolenBaseBreakeven
                let sr = min(92, 20 + ability(\.stealing) * 10 + ability(\.speed) * 4)
                if currentStealTarget == .home { score = 0.5; r.append("本塁盗塁: →0.5（ほぼ不可能）"); return (score, r) }
                if currentStealTarget == .third { score = 2; r.append("3塁盗塁: 基本2（リスク高い）") }
                else { score = 3; r.append("基本スコア: 3") }
                r.append("推定成功率\(sr)% / 損益分岐\(sbBE)%")
                if sr >= sbBE + 15 { score = 25; r.append("分岐点を大幅に超えている: →25 ★GO") }
                else if sr >= sbBE + 5 { score = 15; r.append("分岐点を超えている: →15") }
                else if sr >= sbBE { score = 8; r.append("分岐点ギリギリ: →8") }
                else { score = 2; r.append("分岐点以下: →2（走るべきでない）") }

            case "safe":
                score = 5; r.append("基本スコア: 5")
                if ability(\.safetyBunt) >= 4 && ability(\.speed) >= 4 { score = 15; r.append("セーフティ4＋走力4: →15") }
                else if ability(\.safetyBunt) >= 3 && ability(\.speed) >= 3 { score = 10; r.append("セーフティ3＋走力3: →10") }
                else { r.append("セーフティ技術か走力が不足") }

            case "hitrun":
                score = 8; r.append("基本スコア: 8（統計上、最も期待得点が高い戦術）")
                if ability(\.hitting) >= 4 { score = 20; r.append("打力4以上: →20（コンタクト力高い）") }
                else if ability(\.hitting) >= 3 { score = 12; r.append("打力3: →12") }
                else { score = 3; r.append("打力不足: →3（空振りリスク高い）") }
                if cl >= 1.1 { score += 5; r.append("打者有利カウント: +5") }
                if cl <= 0.7 { score = 2; r.append("投手有利カウント: →2（空振りの危険）") }

            case "squeeze":
                score = 3; r.append("基本スコア: 3")
                if state.outs == 1 && isLateClose { score = 20; r.append("1アウト＋終盤接戦: →20（最適な場面）") }
                else if state.outs == 1 { score = 8; r.append("1アウト: →8") }
                else if state.outs == 0 { score = 4; r.append("0アウト: →4（他の方法で得点可能）") }
                if ability(\.bunting) >= 4 { score += 5; r.append("バント技術4以上: +5") }

            case "walk":
                score = 2; r.append("基本スコア: 2")
                if state.balls == 3 && state.strikes == 0 { score = 30; r.append("3-0カウント: →30（四球がほぼ確実）") }
                else if state.balls == 3 && state.strikes == 1 { score = 20; r.append("3-1カウント: →20（四球の可能性高い）") }
                else if state.balls == 3 && state.strikes == 2 { score = 5; r.append("3-2カウント: →5（ストライクを振る必要あり）") }
                else if state.balls == 2 && state.strikes == 0 { score = 10; r.append("2-0カウント: →10") }
                else if state.balls == 2 && state.strikes == 1 { score = 6; r.append("2-1カウント: →6") }
                else { r.append("ボール先行でないため低スコア") }
                if ability(\.eyeLevel) >= 4 { score += 3; r.append("四球力4以上: +3") }

            case "buster":
                score = 5; r.append("基本スコア: 5")
                if ability(\.hitting) >= 4 && ability(\.bunting) >= 3 { score = 12; r.append("打力4＋バント3: →12") }
                else if hasR && state.outs < 2 && ability(\.hitting) >= 3 { score = 10; r.append("走者あり＋打力3: →10") }

            case "runhit":
                score = 5; r.append("基本スコア: 5")
                if ability(\.speed) >= 4 && ability(\.stealing) >= 4 { score = 12; r.append("走力4＋盗塁4: →12") }
                else if ability(\.speed) >= 3 { score = 7; r.append("走力3: →7") }
                else { score = 2; r.append("走力不足: →2") }

            case "delayed":
                score = 3; r.append("基本スコア: 3（サプライズ戦術）")
                if ability(\.speed) >= 4 { score = 7; r.append("走力4: →7") }
                else if ability(\.speed) >= 3 { score = 5; r.append("走力3: →5") }

            case "firstthird":
                score = 5; r.append("基本スコア: 5")
                if isLateClose { score = 12; r.append("終盤接戦: →12") }
                if state.outs >= 2 { score = 1; r.append("2アウト: →1（リスク高すぎ）") }

            case "pinch":
                if !state.isLate { score = 1; r.append("序盤・中盤: →1（代打は終盤のみ）") }
                else if ability(\.hitting) <= 2 && isLateClose { score = 10; r.append("弱打者＋終盤接戦: →10") }
                else { score = 2; r.append("終盤だが条件不足: →2") }

            case "pinchrun":
                if !state.isLate { score = 1; r.append("序盤・中盤: →1（代走は終盤のみ）") }
                else if isLateClose { score = 8; r.append("終盤接戦: →8") }
                else { score = 2; r.append("終盤だが接戦でない: →2") }

            default:
                score = 1; r.append("基本スコア: 1")
            }

            return (score, r)
        }

        var weights = scoreResults.map(\.score)

        // Normalize to 100%
        let total = weights.reduce(0, +)
        guard total > 0 else { return strategies }

        for i in strategies.indices {
            strategies[i].share = Int(round(weights[i] / total * 100))
            strategies[i].reasons = scoreResults[i].reasons
            // Add final score info
            strategies[i].reasons.append("→ スコア: \(Int(scoreResults[i].score))点 → おすすめ度: \(strategies[i].share)%")
        }

        // Fix rounding to exactly 100
        let currentSum = strategies.map(\.share).reduce(0, +)
        let diff = 100 - currentSum
        if diff != 0, let maxIdx = strategies.indices.max(by: { strategies[$0].share < strategies[$1].share }) {
            strategies[maxIdx].share += diff
        }

        // Sort by share descending — best recommendation first
        strategies.sort { $0.share > $1.share }

        return strategies
    }

    /// Calculate runners key after intentional walk
    private func nextRunnersKeyAfterWalk() -> String {
        var bases = state.bases
        // Walk pushes everyone up: add runner to 1st, shift if forced
        if bases[0] {
            if bases[1] {
                // bases loaded or 1st-2nd: push to loaded
                bases[2] = true
            }
            bases[1] = true
        }
        bases[0] = true
        return bases.map { $0 ? "1" : "0" }.joined()
    }

    private func topPlayers(players: [Player], key: KeyPath<Player, Int>) -> [(name: String, grade: String)] {
        players
            .filter { $0[keyPath: key] > 0 }
            .sorted { $0[keyPath: key] > $1[keyPath: key] }
            .prefix(3)
            .map { p in
                let v = p[keyPath: key]
                let displayName = p.name.isEmpty ? "#\(p.number)" : p.name
                return (name: displayName, grade: v >= 4 ? "A" : v >= 3 ? "B" : "C")
            }
    }

    func recommendation(players: [Player]) -> (title: String, body: String) {
        let re = currentRE
        let bd = buntDelta
        let we = winExpectancy
        let cl = countLeverage
        let hasR = state.bases.contains(true)
        let h3 = state.bases[2]

        // Count-based recommendations (high priority when extreme)
        if cl >= 1.35 && hasR {
            return ("カウント \(state.balls)-\(state.strikes)（打者有利）",
                    String(format: "得点期待 %.2f点。エンドラン・バッティングの期待値が上昇。", re))
        }
        if cl <= 0.65 && state.outs < 2 && hasR {
            return ("カウント \(state.balls)-\(state.strikes)（投手有利）",
                    "盗塁・バントなど走塁系の選択肢を検討。")
        }

        if !hasR && state.outs < 2 {
            return ("走者なし / \(state.outs)アウト",
                    String(format: "得点期待 %.2f点。出塁で得点期待が %.2f点に上昇。", re, Sabermetrics.runExpectancy(runnersKey: "100", outs: state.outs)))
        }
        if state.bases[0] && !state.bases[1] && state.outs == 0 && bd.delta < -0.1 {
            return ("1塁 0アウト — バント非推奨",
                    String(format: "バント時の得点期待変動: %.2f → %.2f（%+.2f）", bd.before, bd.after, bd.delta))
        }
        if h3 && state.outs < 2 && abs(state.diff) <= 2 {
            return ("3塁走者あり / \(state.diff)点差 / 勝率\(we)%",
                    "スクイズ損益分岐点: \(state.outs == 1 ? "70" : "87")%。犠飛でも得点可能。")
        }
        if state.diff <= -3 && state.isLate {
            return ("\(abs(state.diff))点ビハインド / \(state.innings) / 勝率\(we)%",
                    String(format: "バントの得点期待変動: %+.2f。複数得点が必要な状況。", bd.delta))
        }
        return (String(format: "得点期待 %.2f点 / 勝率 %d%%", re, we),
                "\(state.innings) \(state.outs)アウト 走者:\(runnersText)")
    }
}

// MARK: - StrategyResult
struct StrategyResult: Identifiable {
    let id: String
    let name: String
    let risk: RiskLevel
    let enabled: Bool
    let rate: Int
    let reDelta: Double
    let saberText: String
    let description: String
    let playerKey: KeyPath<Player, Int>
    let showBreakeven: Bool
    let topPlayers: [(name: String, grade: String)]
    var share: Int = 0  // recommendation share (sums to 100% across all enabled strategies)
    var reasons: [String] = []  // breakdown of why this score

    enum RiskLevel { case low, mid, high }

    var riskLabel: String {
        switch risk { case .low: return "低"; case .mid: return "中"; case .high: return "高" }
    }
    var riskColor: Color {
        switch risk { case .low: return .green; case .mid: return .orange; case .high: return .red }
    }
    var rateColor: Color { rate >= 70 ? .green : rate >= 50 ? .orange : .red }
    var shareColor: Color { share >= 20 ? .green : share >= 10 ? .yellow : Color(white: 0.4) }
    var reDeltaFormatted: String { String(format: "%+.2f", reDelta) }
    var reDeltaColor: Color { reDelta > 0.05 ? .green : reDelta < -0.05 ? .red : .orange }
}
