import Foundation

struct Sabermetrics {

    // MARK: - Run Expectancy Matrix (MLB 2021-2024 Average, FanGraphs)
    // Key: runners "000"~"111" (1st, 2nd, 3rd)
    // Value: [0 outs, 1 out, 2 outs]
    static let runExpectancy: [String: [Double]] = [
        "000": [0.50, 0.27, 0.10],
        "100": [0.90, 0.54, 0.23],
        "010": [1.14, 0.71, 0.33],
        "001": [1.37, 0.98, 0.38],
        "110": [1.51, 0.94, 0.46],
        "101": [1.82, 1.19, 0.51],
        "011": [2.04, 1.41, 0.57],
        "111": [2.38, 1.63, 0.82],
    ]

    // MARK: - Stolen Base Break-Even Rates (FanGraphs, RE-based)
    // Stealing 2nd base
    static let stealSecondBreakeven: [Int: Int] = [0: 71, 1: 67, 2: 70]
    // Stealing 3rd base
    static let stealThirdBreakeven: [Int: Int] = [0: 78, 1: 69, 2: 88]
    // Stealing home (squeeze context)
    static let stealHomeBreakeven: [Int: Int] = [0: 87, 1: 70, 2: 34]
    // Double steal (1st & 2nd → 2nd & 3rd)
    static let doubleStealBreakeven: [Int: Int] = [0: 64, 1: 60, 2: 76]

    // MARK: - Count Leverage (wOBA multiplier vs league average, FanGraphs 2015-2024)
    // Key: "balls-strikes", Value: multiplier (1.0 = league average)
    static let countLeverage: [String: Double] = [
        "0-0": 1.00,
        "0-1": 0.84, "0-2": 0.63,
        "1-0": 1.13, "1-1": 0.94, "1-2": 0.70,
        "2-0": 1.35, "2-1": 1.13, "2-2": 0.85,
        "3-0": 1.73, "3-1": 1.47, "3-2": 1.17,
    ]

    // MARK: - Platoon Splits (MLB average, FanGraphs)
    // OPS advantage when facing opposite-hand pitcher
    static let platoonOPSAdvantage: [String: Int] = [
        "L": 115,  // LHB vs RHP gains +115 OPS points
        "R": 69,   // RHB vs LHP gains +69 OPS points
    ]
    // wOBA advantage
    static let platoonWOBAAdvantage: [String: Int] = [
        "L": 28,   // LHB gains +28 wOBA points vs RHP
        "R": 16,   // RHB gains +16 wOBA points vs LHP
    ]

    // MARK: - Bunt Cost by Situation (RE delta, 2021-2024 MLB)
    static let buntRECost: [String: Double] = [
        "100_0": -0.19,  // R1, 0 out → R2, 1 out: -0.19 RE
        "110_0": -0.10,  // R1R2, 0 out → R2R3, 1 out: -0.10 RE
        "010_0": -0.16,  // R2, 0 out → R3, 1 out: -0.16 RE
    ]

    // MARK: - High School / Amateur Adjustments
    // Amateur data: bunt success rates are higher in amateur ball
    static let amateurBuntSuccessRate: Double = 84.2  // %
    // Amateur scoring probability after successful bunt (R1→R2 with 1 out)
    static let amateurScoringAfterBunt: Double = 47.5  // %
    // Amateur scoring probability without bunt (R1, 0 out)
    static let amateurScoringWithoutBunt: Double = 45.9  // %

    // MARK: - Functions

    static func runExpectancy(runnersKey: String, outs: Int) -> Double {
        guard outs < 3 else { return 0 }
        return runExpectancy[runnersKey]?[outs] ?? 0
    }

    static func afterBuntRunnersKey(from key: String) -> String {
        let b = key.map { $0 == "1" }
        return [false, b[0], b[1]].map { $0 ? "1" : "0" }.joined()
    }

    static func buntExpectedRunDelta(
        runnersKey: String, outs: Int
    ) -> (delta: Double, before: Double, after: Double, possible: Bool) {
        guard outs < 2 else { return (0, 0, 0, false) }
        let before = runExpectancy(runnersKey: runnersKey, outs: outs)
        let afterKey = afterBuntRunnersKey(from: runnersKey)
        let after = runExpectancy(runnersKey: afterKey, outs: outs + 1)
        return (after - before, before, after, true)
    }

    static func winExpectancy(inning: Int, scoreDiff: Int) -> Int {
        let k = 0.4 + Double(min(inning, 9) - 1) * 0.08
        return Int(round(100.0 / (1.0 + exp(-k * Double(scoreDiff)))))
    }

    /// Returns the break-even steal rate for the given steal type and outs
    static func stolenBaseBreakevenRate(outs: Int, stealTarget: StealTarget = .second) -> Int {
        switch stealTarget {
        case .second: return stealSecondBreakeven[outs] ?? 70
        case .third:  return stealThirdBreakeven[outs] ?? 75
        case .home:   return stealHomeBreakeven[outs] ?? 70
        case .double: return doubleStealBreakeven[outs] ?? 65
        }
    }

    /// Returns the count leverage multiplier (1.0 = average)
    static func countLeverageMultiplier(balls: Int, strikes: Int) -> Double {
        let key = "\(balls)-\(strikes)"
        return countLeverage[key] ?? 1.0
    }

    /// Returns a human-readable count advantage description
    static func countAdvantageText(balls: Int, strikes: Int) -> String {
        let mult = countLeverageMultiplier(balls: balls, strikes: strikes)
        if mult >= 1.3 { return "打者がかなり有利" }
        if mult >= 1.1 { return "打者がやや有利" }
        if mult <= 0.7 { return "投手がかなり有利" }
        if mult <= 0.85 { return "投手がやや有利" }
        return "互角"
    }

    /// Platoon advantage text
    static func platoonText(batterHand: String, pitcherHand: String) -> String {
        if batterHand == pitcherHand {
            let disadvantage = batterHand == "L" ? 115 : 69
            return "同じ手（OPS -\(disadvantage)点不利）"
        } else {
            let advantage = batterHand == "L" ? 115 : 69
            return "逆手有利（OPS +\(advantage)点）"
        }
    }

    /// Whether bunting is recommended based on analytics
    static func isBuntRecommended(
        runnersKey: String, outs: Int, inning: Int, scoreDiff: Int,
        batterStrength: Int, isAmateur: Bool
    ) -> (recommended: Bool, reason: String) {
        guard outs < 2 else {
            return (false, "2アウトではバントは使えません")
        }

        let bd = buntExpectedRunDelta(runnersKey: runnersKey, outs: outs)

        // Late & close: bunt can increase WP even while decreasing RE
        let isLateClose = inning >= 7 && abs(scoreDiff) <= 1
        // Weak batter: bunt is relatively better
        let isWeakBatter = batterStrength <= 2

        if isAmateur {
            // In amateur baseball, bunts are nearly neutral (+1.6% scoring probability)
            if isLateClose || isWeakBatter {
                return (true, "アマ野球: バント後得点率47.5%（バントなし45.9%）。接戦終盤/弱打者には有効")
            }
            return (false, String(format: "アマ野球: RE変動 %+.3f。強打者ならバッティングが有利", bd.delta))
        }

        // MLB analytics
        if bd.delta > -0.05 {
            return (true, String(format: "期待得点の低下が小さい（%+.3f）。状況に応じて有効", bd.delta))
        }
        if isLateClose && isWeakBatter {
            return (true, String(format: "終盤接戦＋弱打者: RE %+.3fだが勝率向上の可能性あり", bd.delta))
        }
        if bd.delta < -0.15 {
            return (false, String(format: "MLB実データ: バントでRE %+.3f点。バッティングを推奨", bd.delta))
        }
        return (false, String(format: "期待得点 %+.3f点。打力があればバッティングが有利", bd.delta))
    }

    // MARK: - Steal Target
    enum StealTarget: String, CaseIterable {
        case second = "2塁"
        case third = "3塁"
        case home = "本塁"
        case double = "ダブルスチール"
    }
}
