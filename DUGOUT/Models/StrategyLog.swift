import Foundation
import SwiftData

@Model
final class StrategyLog {
    var id: UUID
    var timestamp: Date
    var inning: Int
    var isTop: Bool
    var outs: Int
    var runnersKey: String
    var myScore: Int
    var oppScore: Int
    var strategyId: String
    var strategyName: String
    var playerName: String
    var estimatedRate: Int
    var reDelta: Double
    var reAtTime: Double
    var result: String
    var memo: String

    init(
        inning: Int, isTop: Bool, outs: Int, runnersKey: String,
        myScore: Int, oppScore: Int, strategyId: String, strategyName: String,
        playerName: String, estimatedRate: Int, reDelta: Double,
        reAtTime: Double, result: String, memo: String
    ) {
        self.id = UUID(); self.timestamp = Date()
        self.inning = inning; self.isTop = isTop; self.outs = outs
        self.runnersKey = runnersKey; self.myScore = myScore; self.oppScore = oppScore
        self.strategyId = strategyId; self.strategyName = strategyName
        self.playerName = playerName; self.estimatedRate = estimatedRate
        self.reDelta = reDelta; self.reAtTime = reAtTime
        self.result = result; self.memo = memo
    }

    var isSuccess: Bool { result == "ok" }
    var scoreText: String { "\(myScore)-\(oppScore)" }
    var runnersText: String {
        [
            "000":"ランナーなし","100":"1塁","010":"2塁","001":"3塁",
            "110":"1・2塁","101":"1・3塁","011":"2・3塁","111":"満塁"
        ][runnersKey] ?? runnersKey
    }
}

@Model
final class GameRecord {
    var id: UUID
    var date: Date
    var myTeamName: String
    var oppTeamName: String
    var myScore: Int
    var oppScore: Int
    var notes: String

    init(myTeamName: String = "", oppTeamName: String = "") {
        self.id = UUID(); self.date = Date()
        self.myTeamName = myTeamName; self.oppTeamName = oppTeamName
        self.myScore = 0; self.oppScore = 0; self.notes = ""
    }
}
