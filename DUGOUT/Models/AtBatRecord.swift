import Foundation
import SwiftData

@Model
final class AtBatRecord {
    var id: UUID
    var timestamp: Date
    var playerId: UUID
    var playerName: String
    var result: String
    var strategyId: String
    var inning: Int
    var isTop: Bool
    var isOpponent: Bool

    init(
        playerId: UUID, playerName: String, result: String,
        strategyId: String, inning: Int, isTop: Bool,
        isOpponent: Bool = false
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.playerId = playerId
        self.playerName = playerName
        self.result = result
        self.strategyId = strategyId
        self.inning = inning
        self.isTop = isTop
        self.isOpponent = isOpponent
    }

    // MARK: - Hit classification
    var isHit: Bool {
        ["single", "single_score", "double", "double_score", "triple", "homerun"].contains(result)
    }

    /// At-bat (打数): excludes walks, HBP, sacrifice
    var isAtBat: Bool {
        !["walk", "hitbypitch", "sacrifice", "sacfly"].contains(result)
    }

    /// Plate appearance (打席)
    var isPlateAppearance: Bool { true }

    /// Total bases for this at-bat
    var totalBases: Int {
        switch result {
        case "single", "single_score": return 1
        case "double", "double_score": return 2
        case "triple": return 3
        case "homerun": return 4
        default: return 0
        }
    }

    /// Is on-base event
    var isOnBase: Bool {
        ["single", "single_score", "double", "double_score", "triple", "homerun", "walk", "hitbypitch", "error", "fielderschoice"].contains(result)
    }

    /// Is sacrifice fly (for OBP calculation)
    var isSacFly: Bool { result == "sacfly" }

    // MARK: - Display
    var resultLabel: String {
        switch result {
        case "single": return "シングル"
        case "double": return "ツーベース"
        case "triple": return "スリーベース"
        case "homerun": return "ホームラン"
        case "walk": return "四球"
        case "hitbypitch": return "死球"
        case "error": return "エラー"
        case "fielderschoice": return "FC"
        case "groundout": return "ゴロアウト"
        case "flyout": return "フライアウト"
        case "strikeout": return "三振"
        case "doubleplay": return "併殺"
        case "sacrifice": return "犠打"
        case "sacfly": return "犠飛"
        default: return result
        }
    }

    // MARK: - All result options
    static let hitResults: [(label: String, id: String)] = [
        ("シングル", "single"),
        ("ツーベース", "double"),
        ("スリーベース", "triple"),
        ("ホームラン", "homerun"),
        ("四球", "walk"),
        ("死球", "hitbypitch"),
        ("エラー出塁", "error"),
        ("FC", "fielderschoice"),
    ]

    static let outResults: [(label: String, id: String)] = [
        ("ゴロアウト", "groundout"),
        ("フライアウト", "flyout"),
        ("三振", "strikeout"),
        ("併殺", "doubleplay"),
        ("犠打", "sacrifice"),
        ("犠飛", "sacfly"),
    ]
}

// MARK: - Player Stats Calculator
struct PlayerStats {
    let records: [AtBatRecord]

    var atBats: Int { records.filter(\.isAtBat).count }
    var plateAppearances: Int { records.count }
    var hits: Int { records.filter(\.isHit).count }
    var walks: Int { records.filter { $0.result == "walk" }.count }
    var hitByPitch: Int { records.filter { $0.result == "hitbypitch" }.count }
    var sacFlies: Int { records.filter(\.isSacFly).count }
    var homeRuns: Int { records.filter { $0.result == "homerun" }.count }
    var strikeouts: Int { records.filter { $0.result == "strikeout" }.count }
    var doubles: Int { records.filter { $0.result == "double" }.count }
    var triples: Int { records.filter { $0.result == "triple" }.count }
    var totalBases: Int { records.map(\.totalBases).reduce(0, +) }
    var doublePlays: Int { records.filter { $0.result == "doubleplay" }.count }

    /// 打率 (BA) = Hits / At-Bats
    var battingAverage: Double {
        guard atBats > 0 else { return 0 }
        return Double(hits) / Double(atBats)
    }

    /// 出塁率 (OBP) = (H + BB + HBP) / (AB + BB + HBP + SF)
    var onBasePercentage: Double {
        let denom = atBats + walks + hitByPitch + sacFlies
        guard denom > 0 else { return 0 }
        return Double(hits + walks + hitByPitch) / Double(denom)
    }

    /// 長打率 (SLG) = Total Bases / At-Bats
    var sluggingPercentage: Double {
        guard atBats > 0 else { return 0 }
        return Double(totalBases) / Double(atBats)
    }

    /// OPS = OBP + SLG
    var ops: Double { onBasePercentage + sluggingPercentage }

    /// Formatted strings
    var baText: String { atBats > 0 ? String(format: ".%03d", Int(round(battingAverage * 1000))) : "---" }
    var obpText: String { plateAppearances > 0 ? String(format: ".%03d", Int(round(onBasePercentage * 1000))) : "---" }
    var slgText: String { atBats > 0 ? String(format: ".%03d", Int(round(sluggingPercentage * 1000))) : "---" }
    var opsText: String { atBats > 0 ? String(format: ".%03d", Int(round(ops * 1000))) : "---" }
    var summaryLine: String { "\(hits)/\(atBats) \(homeRuns)本 \(walks)四球" }
}

// MARK: - Strategy Stats for a Player
struct PlayerStrategyStats {
    let logs: [StrategyLog]
    let strategyId: String

    var total: Int { logs.filter { $0.strategyId == strategyId && $0.result != "cancel" }.count }
    var successes: Int { logs.filter { $0.strategyId == strategyId && $0.result == "ok" }.count }
    var rate: Int {
        guard total > 0 else { return 0 }
        return Int(round(Double(successes) / Double(total) * 100))
    }
    var text: String {
        guard total > 0 else { return "" }
        return "\(successes)/\(total)(\(rate)%)"
    }
}
