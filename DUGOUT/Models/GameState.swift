import Foundation

struct GameState {
    var myScore: Int = 0
    var oppScore: Int = 0
    var inning: Int = 1
    var isTop: Bool = true
    var outs: Int = 0
    var bases: [Bool] = [false, false, false]
    var balls: Int = 0
    var strikes: Int = 0
    var orderIndex: Int = 0

    var runnersKey: String { bases.map { $0 ? "1" : "0" }.joined() }
    var diff: Int { myScore - oppScore }
    var isLate: Bool { inning >= 7 }
    var tbText: String { isTop ? "表" : "裏" }
    var innings: String { "\(inning)回\(tbText)" }

    mutating func resetCount() { balls = 0; strikes = 0 }
}
