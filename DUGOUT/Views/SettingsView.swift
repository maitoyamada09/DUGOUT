import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("myTeamName") private var myTeamName = ""
    @AppStorage("gameLevel") private var gameLevel = "高校野球"
    @AppStorage("appLanguage") private var appLanguage = ""
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = true
    @Query private var players: [Player]
    @Query private var logs: [StrategyLog]

    @State private var showFeedback = false

    private let gameLevels = ["少年野球", "中学野球", "高校野球", "大学野球", "社会人野球", "草野球", "独立リーグ"]
    private let languages = ["自動（端末設定に従う）", "日本語", "English", "한국어", "Español", "中文"]

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

                // フィードバック
                Section("サポート") {
                    Button {
                        showFeedback = true
                    } label: {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(.yellow)
                            Text("開発者に報告する")
                                .foregroundStyle(.white)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listRowBackground(Color(white: 0.08))

                    Text("バグ報告・機能リクエスト・ご意見など\nお気軽にお送りください。")
                        .font(.system(size: 11))
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
            .sheet(isPresented: $showFeedback) {
                FeedbackView(
                    playerCount: players.count,
                    logCount: logs.count,
                    gameLevel: gameLevel
                )
                .preferredColorScheme(.dark)
            }
        }
    }
}

// MARK: - Feedback View
struct FeedbackView: View {
    let playerCount: Int
    let logCount: Int
    let gameLevel: String
    @Environment(\.dismiss) private var dismiss

    @State private var feedbackType = 0
    @State private var message = ""
    @State private var showSent = false

    private let feedbackTypes = ["バグ報告", "機能リクエスト", "改善提案", "その他"]

    private var deviceInfo: String {
        let device = UIDevice.current
        return "\(device.model) / \(device.systemName) \(device.systemVersion)"
    }

    private var mailBody: String {
        """
        【\(feedbackTypes[feedbackType])】

        \(message)

        ───────────────
        アプリ: DUGOUT v1.0.0
        端末: \(deviceInfo)
        レベル: \(gameLevel)
        登録選手数: \(playerCount)
        作戦ログ数: \(logCount)
        ───────────────
        """
    }

    private var mailSubject: String {
        "【DUGOUT】\(feedbackTypes[feedbackType])"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "envelope.open.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.yellow)
                        Text("開発者に報告する")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                        Text("いただいたフィードバックは\nアプリの改善に役立てます")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 16)

                    // Feedback type
                    VStack(alignment: .leading, spacing: 8) {
                        Text("報告の種類")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.yellow)
                            .padding(.horizontal, 16)

                        Picker("", selection: $feedbackType) {
                            ForEach(feedbackTypes.indices, id: \.self) { i in
                                Text(feedbackTypes[i]).tag(i)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 12)
                    .background(Color(white: 0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 12)

                    // Message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("内容")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.yellow)
                            .padding(.horizontal, 16)

                        TextEditor(text: $message)
                            .frame(minHeight: 150)
                            .scrollContentBackground(.hidden)
                            .background(Color(white: 0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.horizontal, 16)
                            .foregroundStyle(.white)

                        Text(feedbackType == 0
                             ? "どこで・何をしたら・どうなったかを書いていただけると助かります"
                             : "具体的にお書きください")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(white: 0.35))
                            .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 12)
                    .background(Color(white: 0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 12)

                    // Device info (auto-attached)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("自動添付される情報")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.yellow)
                            .padding(.horizontal, 16)

                        VStack(alignment: .leading, spacing: 4) {
                            infoRow("端末", deviceInfo)
                            infoRow("バージョン", "DUGOUT v1.0.0")
                            infoRow("レベル", gameLevel)
                            infoRow("選手数", "\(playerCount)人")
                            infoRow("ログ数", "\(logCount)件")
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 12)
                    .background(Color(white: 0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 12)

                    // Send button
                    Button {
                        sendFeedback()
                    } label: {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("メールで送信")
                        }
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(message.isEmpty ? Color(white: 0.3) : Color.yellow)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(message.isEmpty)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .background(Color.black)
            .navigationTitle("フィードバック")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
            .alert("送信準備完了", isPresented: $showSent) {
                Button("OK") { dismiss() }
            } message: {
                Text("メールアプリが開きます。\n送信ボタンを押してフィードバックを送信してください。")
            }
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color(white: 0.5))
        }
    }

    private func sendFeedback() {
        let subject = mailSubject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let body = mailBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let email = "dugout.app.feedback@gmail.com"
        let urlString = "mailto:\(email)?subject=\(subject)&body=\(body)"

        if let url = URL(string: urlString) {
            UIApplication.shared.open(url) { success in
                if !success {
                    // Fallback: copy to clipboard
                    UIPasteboard.general.string = "件名: \(mailSubject)\n\n\(mailBody)"
                    showSent = true
                }
            }
        }
    }
}
