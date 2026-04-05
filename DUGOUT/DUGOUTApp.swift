import SwiftUI
import SwiftData

@main
struct DUGOUTApp: App {
    @AppStorage("appLanguage") private var appLanguage = ""

    private var overrideLocale: Locale? {
        switch appLanguage {
        case "日本語":  return Locale(identifier: "ja")
        case "English": return Locale(identifier: "en")
        case "한국어":   return Locale(identifier: "ko")
        case "Español": return Locale(identifier: "es")
        case "中文":     return Locale(identifier: "zh-Hans")
        default:        return nil // follow system
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, overrideLocale ?? .current)
        }
        .modelContainer(for: [
            Player.self,
            Opponent.self,
            OpponentPlayer.self,
            GameRecord.self,
            StrategyLog.self,
            AtBatRecord.self,
            PitcherRecord.self
        ])
    }
}
