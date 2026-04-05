import Foundation
import SwiftData

@Model
final class Player {
    var id: UUID
    var number: String
    var name: String
    var position: String
    var note: String

    var hitting: Int
    var bunting: Int
    var speed: Int
    var safetyBunt: Int
    var power: Int
    var eyeLevel: Int
    var stealing: Int

    // 打者の利き手
    var batHand: String  // "右打", "左打", "両打"

    // 投手能力（全選手が投げる可能性がある）
    var canPitch: Bool
    var throwHand: String  // "右投" or "左投"
    var pitchTypes: [String]

    var rawHitting: String
    var rawBunting: String
    var rawSpeed: String
    var rawSafetyBunt: String
    var rawPower: String
    var rawEyeLevel: String
    var rawStealing: String

    var createdAt: Date

    init(number: String = "", name: String = "", position: String = "外") {
        self.id = UUID()
        self.number = number
        self.name = name
        self.position = position
        self.note = ""
        self.hitting = 0; self.bunting = 0; self.speed = 0
        self.safetyBunt = 0; self.power = 0; self.eyeLevel = 0; self.stealing = 0
        self.batHand = "右打"
        self.canPitch = false; self.throwHand = "右投"; self.pitchTypes = []
        self.rawHitting = ""; self.rawBunting = ""; self.rawSpeed = ""
        self.rawSafetyBunt = ""; self.rawPower = ""; self.rawEyeLevel = ""; self.rawStealing = ""
        self.createdAt = Date()
    }

    static let positions = ["投","捕","一","二","三","遊","左","中","右","指"]

    /// Update ability ratings based on actual recorded stats
    func updateAbilitiesFromStats(atBats: [AtBatRecord], strategyLogs: [StrategyLog]) {
        let myAtBats = atBats.filter { $0.playerId == id && !$0.isOpponent }
        let myLogs = strategyLogs.filter { $0.playerName == name }
        let stats = PlayerStats(records: myAtBats)

        // Only update if enough data (at least 5 at-bats)
        guard stats.plateAppearances >= 5 else { return }

        // Hitting: based on actual BA
        if stats.atBats >= 5 {
            let ba = stats.battingAverage
            if ba >= 0.300 { hitting = 5 }
            else if ba >= 0.250 { hitting = 4 }
            else if ba >= 0.200 { hitting = 3 }
            else if ba >= 0.150 { hitting = 2 }
            else { hitting = 1 }
            rawHitting = String(format: ".%03d", Int(round(ba * 1000)))
        }

        // Power: based on HR + extra base hits
        let xbh = stats.doubles + stats.triples + stats.homeRuns
        if stats.atBats >= 5 {
            if stats.homeRuns >= 3 || xbh >= 8 { power = 5 }
            else if stats.homeRuns >= 2 || xbh >= 5 { power = 4 }
            else if stats.homeRuns >= 1 || xbh >= 2 { power = 3 }
            else if xbh >= 1 { power = 2 }
            else { power = 1 }
            rawPower = "\(stats.homeRuns)"
        }

        // Eye level (四球力): based on walk rate
        if stats.plateAppearances >= 5 {
            let walkRate = Double(stats.walks) / Double(stats.plateAppearances) * 100
            if walkRate >= 15 { eyeLevel = 5 }
            else if walkRate >= 10 { eyeLevel = 4 }
            else if walkRate >= 6 { eyeLevel = 3 }
            else if walkRate >= 3 { eyeLevel = 2 }
            else { eyeLevel = 1 }
            rawEyeLevel = String(format: "%.0f", walkRate)
        }

        // Bunting: based on bunt strategy success rate
        let buntLogs = myLogs.filter { $0.strategyId == "bunt" && $0.result != "cancel" }
        if buntLogs.count >= 3 {
            let buntSuccess = Double(buntLogs.filter(\.isSuccess).count) / Double(buntLogs.count) * 100
            if buntSuccess >= 90 { bunting = 5 }
            else if buntSuccess >= 75 { bunting = 4 }
            else if buntSuccess >= 60 { bunting = 3 }
            else if buntSuccess >= 40 { bunting = 2 }
            else { bunting = 1 }
            rawBunting = String(format: "%.0f", buntSuccess)
        }

        // Stealing: based on steal strategy success rate
        let stealLogs = myLogs.filter { $0.strategyId == "steal" && $0.result != "cancel" }
        if stealLogs.count >= 3 {
            let stealSuccess = Double(stealLogs.filter(\.isSuccess).count) / Double(stealLogs.count) * 100
            if stealSuccess >= 85 { stealing = 5 }
            else if stealSuccess >= 70 { stealing = 4 }
            else if stealSuccess >= 55 { stealing = 3 }
            else if stealSuccess >= 40 { stealing = 2 }
            else { stealing = 1 }
            rawStealing = String(format: "%.0f", stealSuccess)
        }
    }

    var offensiveScore: Double {
        Double([hitting,bunting,speed,safetyBunt,power,eyeLevel,stealing].reduce(0,+)) / 7.0
    }
}
