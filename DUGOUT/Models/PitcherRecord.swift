import Foundation
import SwiftData

/// 投手の登板記録（1登板分）
@Model
final class PitcherRecord {
    var id: UUID
    var timestamp: Date
    var pitcherId: UUID       // Player.id または OpponentPlayer.id
    var pitcherName: String
    var isOpponent: Bool      // 相手投手かどうか

    // 投球データ
    var inningsPitched: Double   // 投球回数（例: 5.2 = 5回2/3）
    var hitsAllowed: Int         // 被安打
    var runsAllowed: Int         // 失点
    var earnedRuns: Int          // 自責点
    var walks: Int               // 与四球
    var strikeouts: Int          // 奪三振
    var pitchCount: Int          // 投球数
    var homeRunsAllowed: Int     // 被本塁打

    init(
        pitcherId: UUID, pitcherName: String, isOpponent: Bool = false
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.pitcherId = pitcherId
        self.pitcherName = pitcherName
        self.isOpponent = isOpponent
        self.inningsPitched = 0
        self.hitsAllowed = 0
        self.runsAllowed = 0
        self.earnedRuns = 0
        self.walks = 0
        self.strikeouts = 0
        self.pitchCount = 0
        self.homeRunsAllowed = 0
    }

    /// 防御率 (ERA) = 自責点 / 投球回数 * 規定回数（通常9）
    var era: Double {
        guard inningsPitched > 0 else { return 0 }
        return Double(earnedRuns) / inningsPitched * 9.0
    }

    /// 防御率テキスト
    var eraText: String {
        guard inningsPitched > 0 else { return "---" }
        return String(format: "%.2f", era)
    }

    /// WHIP = (被安打 + 与四球) / 投球回数
    var whip: Double {
        guard inningsPitched > 0 else { return 0 }
        return Double(hitsAllowed + walks) / inningsPitched
    }

    /// 投球回数テキスト（5.1 = 5回1/3）
    var inningsText: String {
        let full = Int(inningsPitched)
        let fraction = inningsPitched - Double(full)
        if fraction < 0.1 { return "\(full)" }
        if fraction < 0.4 { return "\(full).1" }
        return "\(full).2"
    }

    /// K/9 = 奪三振 / 投球回数 * 9
    var k9: Double {
        guard inningsPitched > 0 else { return 0 }
        return Double(strikeouts) / inningsPitched * 9.0
    }
}

/// 投手の通算成績を計算するヘルパー
struct PitcherStats {
    let records: [PitcherRecord]

    var totalInnings: Double { records.map(\.inningsPitched).reduce(0, +) }
    var totalEarnedRuns: Int { records.map(\.earnedRuns).reduce(0, +) }
    var totalStrikeouts: Int { records.map(\.strikeouts).reduce(0, +) }
    var totalWalks: Int { records.map(\.walks).reduce(0, +) }
    var totalHits: Int { records.map(\.hitsAllowed).reduce(0, +) }
    var totalPitches: Int { records.map(\.pitchCount).reduce(0, +) }
    var totalHomeRuns: Int { records.map(\.homeRunsAllowed).reduce(0, +) }
    var games: Int { records.count }

    var era: Double {
        guard totalInnings > 0 else { return 0 }
        return Double(totalEarnedRuns) / totalInnings * 9.0
    }

    var eraText: String {
        guard totalInnings > 0 else { return "---" }
        return String(format: "%.2f", era)
    }

    var whip: Double {
        guard totalInnings > 0 else { return 0 }
        return Double(totalHits + totalWalks) / totalInnings
    }

    var whipText: String {
        guard totalInnings > 0 else { return "---" }
        return String(format: "%.2f", whip)
    }

    var k9: Double {
        guard totalInnings > 0 else { return 0 }
        return Double(totalStrikeouts) / totalInnings * 9.0
    }
}
