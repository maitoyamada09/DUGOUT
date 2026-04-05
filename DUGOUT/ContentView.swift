import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var players: [Player]
    @Query private var opponents: [Opponent]
    @Query(sort: \StrategyLog.timestamp, order: .reverse) private var logs: [StrategyLog]

    @State private var viewModel = GameViewModel()
    @State private var selectedTab = 0
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                GameView(viewModel: viewModel, players: players, logs: logs)
                    .tabItem { Label("試合", systemImage: "diamond.fill") }
                    .tag(0)

                PlayersView()
                    .tabItem { Label("選手", systemImage: "person.2") }
                    .tag(1)

                LineupView(viewModel: viewModel, players: players)
                    .tabItem { Label("打順", systemImage: "list.number") }
                    .tag(2)

                AnalysisView(viewModel: viewModel, players: players, logs: logs)
                    .tabItem { Label("分析", systemImage: "waveform.path.ecg") }
                    .tag(3)

                StrategyGuideView()
                    .tabItem { Label("戦略辞典", systemImage: "book.fill") }
                    .tag(4)

                SettingsView()
                    .tabItem { Label("設定", systemImage: "gearshape.fill") }
                    .tag(5)
            }
            .preferredColorScheme(.dark)
            .tint(.yellow)

            if !hasSeenOnboarding {
                TutorialView(hasSeenTutorial: $hasSeenOnboarding)
                    .transition(.opacity)
            }
        }
    }
}

// MARK: - Onboarding View
struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var currentPage = 0

    // 5 pages, cool & professional tone
    private let pages: [(title: String, body: String, useCustomIcon: Bool)] = [
        (
            "DUGOUT",
            "最適解を、瞬時に。\nあなたの野球の勘に、根拠を。",
            true
        ),
        (
            "データが、采配を変える時代へ。",
            "戦略の最適解を知ることが、勝率を上げる。\n\n膨大な試合データから分析・実証された\n攻撃戦略のデータベース。\n\n得点期待値・勝率・損益分岐点。\n数十年分のデータが、あなたの次の一手を裏付ける。",
            false
        ),
        (
            "全作戦を、数値で比較。",
            "バッティング・バント・盗塁・エンドラン\nスクイズ・バスター — 13の攻撃戦術。\n\nカウント・走者・イニング・点差・選手能力から\nおすすめ度を合計100%で表示。\n根拠とともに、冷静な選択肢を提示する。",
            false
        ),
        (
            "記録が、ミーティングを変える。",
            "打率・出塁率・OPS — 全打席を自動集計。\n作戦別の成功率を選手ごとに蓄積。\n\n試合を重ねるほど精度が上がる。\nデータがチームの武器になる。\nミーティングの質が、次の勝利を分ける。",
            false
        ),
        (
            "ダグアウトから、勝利を。",
            "試合中の操作はすべてワンタップ。\nスコア・アウト・走者・カウント・打席結果。\n\nデジタルをダグアウトへ。\niPad片手に、先進的な采配を。\n\n試合後はレポートを自動生成。\nチームミーティングの質が変わる。",
            false
        ),
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        VStack(spacing: 24) {
                            Spacer()

                            if pages[index].useCustomIcon {
                                // Custom 3-diamond logo (tight, no gaps)
                                ThreeDiamondLogo(size: 28, spacing: 15)
                            } else {
                                // Yellow accent line
                                Rectangle()
                                    .fill(.yellow)
                                    .frame(width: 40, height: 3)
                            }

                            Text(pages[index].title)
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(.white)

                            Text(pages[index].body)
                                .font(.system(size: 15))
                                .foregroundStyle(Color(white: 0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 36)

                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                // Bottom button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        withAnimation { hasSeenOnboarding = true }
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "次へ" : "はじめる")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.yellow)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                // Skip button
                if currentPage < pages.count - 1 {
                    Button {
                        withAnimation { hasSeenOnboarding = true }
                    } label: {
                        Text("スキップ")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 24)
                }
            }
        }
    }
}

// MARK: - Three Diamond Logo (reusable)
struct ThreeDiamondLogo: View {
    var size: CGFloat = 28
    var spacing: CGFloat = 14

    var body: some View {
        ZStack {
            // 2nd base (top)
            RoundedRectangle(cornerRadius: size * 0.15)
                .fill(.yellow)
                .frame(width: size, height: size)
                .rotationEffect(.degrees(45))
                .offset(x: 0, y: -spacing * 1.1)
            // 3rd base (left)
            RoundedRectangle(cornerRadius: size * 0.15)
                .fill(.yellow)
                .frame(width: size, height: size)
                .rotationEffect(.degrees(45))
                .offset(x: -spacing * 1.4, y: spacing * 0.6)
            // 1st base (right)
            RoundedRectangle(cornerRadius: size * 0.15)
                .fill(.yellow)
                .frame(width: size, height: size)
                .rotationEffect(.degrees(45))
                .offset(x: spacing * 1.4, y: spacing * 0.6)
        }
        .frame(height: size * 2.5)
    }
}
