import SwiftUI

struct SettingsView: View {
    @AppStorage("myTeamName") private var myTeamName = ""
    @AppStorage("gameLevel") private var gameLevel = "高校野球"
    @AppStorage("appLanguage") private var appLanguage = ""
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = true

    private let gameLevels = ["少年野球", "中学野球", "高校野球", "大学野球", "社会人野球", "草野球", "独立リーグ"]
    private let languages = ["自動（端末設定に従う）", "日本語", "English", "한국어", "Español", "中文"]

    /// 初回起動時にシステム言語を検出
    private var detectedLanguage: String {
        let langCode = Locale.current.language.languageCode?.identifier ?? "ja"
        switch langCode {
        case "ja": return "日本語"
        case "en": return "English"
        case "ko": return "한국어"
        case "es": return "Español"
        case "zh": return "中文"
        default: return "English"
        }
    }

    private var currentLanguage: String {
        if appLanguage.isEmpty || appLanguage == "自動（端末設定に従う）" {
            return detectedLanguage
        }
        return appLanguage
    }

    var body: some View {
        NavigationStack {
            List {
                // チーム設定
                Section("チーム設定") {
                    HStack {
                        Text("チーム名")
                        Spacer()
                        TextField("チーム名を入力", text: $myTeamName)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.yellow)
                    }
                    .listRowBackground(Color(white: 0.08))
                }

                // 試合設定
                Section("試合設定") {
                    Picker("試合レベル", selection: $gameLevel) {
                        ForEach(gameLevels, id: \.self) { level in
                            Text(level).tag(level)
                        }
                    }
                    .listRowBackground(Color(white: 0.08))
                }

                // 言語
                Section("言語 / Language") {
                    Picker("言語", selection: $appLanguage) {
                        ForEach(languages, id: \.self) { lang in
                            Text(lang).tag(lang)
                        }
                    }
                    .listRowBackground(Color(white: 0.08))

                    HStack {
                        Text("現在の言語")
                        Spacer()
                        Text(currentLanguage)
                            .foregroundStyle(.yellow)
                    }
                    .listRowBackground(Color(white: 0.08))

                    Text("「自動」を選ぶと端末の言語設定に従います。")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color(white: 0.08))
                }

                // データ
                Section("データ") {
                    Text("データはこの端末に保存されています。")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color(white: 0.08))

                    Text("クラウド同期は今後のアップデートで対応予定。")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color(white: 0.08))
                }

                // アプリ情報
                Section("アプリ情報") {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    .listRowBackground(Color(white: 0.08))

                    Button {
                        hasSeenOnboarding = false
                    } label: {
                        Text("オンボーディングを再表示")
                            .foregroundStyle(.yellow)
                    }
                    .listRowBackground(Color(white: 0.08))
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("設定")
        }
    }
}
