import Foundation
import SwiftData

@Model
final class Opponent {
    var id: UUID
    var teamName: String
    var pitcherNumber: String
    var pitcherName: String
    var pitcherMemo: String
    var pitchTags: [String]
    @Relationship(deleteRule: .cascade) var players: [OpponentPlayer]
    var createdAt: Date

    init(teamName: String = "") {
        self.id = UUID()
        self.teamName = teamName
        self.pitcherNumber = ""
        self.pitcherName = ""
        self.pitcherMemo = ""
        self.pitchTags = []
        self.players = []
        self.createdAt = Date()
    }

    static let pitchTagOptions = [
        "速球派","軟投派","変化球多","左投","右投",
        "サイド","アンダー","クセあり","牽制強",
        "クイック速","クイック遅","制球難"
    ]
}

@Model
final class OpponentPlayer {
    var id: UUID
    var number: String
    var name: String
    var tags: [String]
    var memo: String

    // 投手データ（投手として登録された場合）
    var isPitcher: Bool
    var throwHand: String        // "右投" or "左投"
    var pitchTags: [String]      // 球種・特徴タグ

    init(number: String = "", name: String = "") {
        self.id = UUID()
        self.number = number
        self.name = name
        self.tags = []
        self.memo = ""
        self.isPitcher = false
        self.throwHand = "右投"
        self.pitchTags = []
    }

    static let tagOptions = [
        "右打","左打","長打あり","バント得意","足が速い",
        "選球眼◎","引っ張り","流し打ち","内角弱","外角弱","追い込まれ強"
    ]

    static let pitcherTagOptions = [
        "速球派","軟投派","変化球多","左投","右投",
        "サイド","アンダー","クセあり","牽制強",
        "クイック速","クイック遅","制球難"
    ]
}
