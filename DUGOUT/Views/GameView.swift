import SwiftUI
import SwiftData

struct GameView: View {
    @Bindable var viewModel: GameViewModel
    let players: [Player]
    let logs: [StrategyLog]
    @Environment(\.modelContext) private var modelContext
    @Query private var opponents: [Opponent]

    var body: some View {
        NavigationStack {
            ZStack {
                if !viewModel.gameStarted {
                    // MARK: - Pre-Game Screen
                    preGameView
                } else if viewModel.gameEnded {
                    // MARK: - Game Over Screen
                    gameOverView
                } else {
                    // MARK: - Active Game
                    activeGameView
                }
            }
            .background(Color.black)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(item: $viewModel.showingSheet) { sheet in
            switch sheet {
            case .exec:
                ExecSheetView(viewModel: viewModel, players: players)
                    .preferredColorScheme(.dark)
            case .analysis:
                AnalysisView(viewModel: viewModel, players: players, logs: logs)
                    .preferredColorScheme(.dark)
            case .opponent:
                OpponentView(opponents: opponents)
                    .preferredColorScheme(.dark)
            case .players:
                PlayersView(dismissAction: { viewModel.showingSheet = nil })
                    .preferredColorScheme(.dark)
            case .gameSetup:
                GameSetupView(viewModel: viewModel)
                    .preferredColorScheme(.dark)
            case .pitcherChange:
                PitcherChangeView(viewModel: viewModel, players: players)
                    .preferredColorScheme(.dark)
            default:
                EmptyView()
            }
        }
    }

    // MARK: - Pre-Game View
    private var preGameView: some View {
        VStack(spacing: 24) {
            Spacer()

            ThreeDiamondLogo(size: 32, spacing: 16)

            Text("DUGOUT")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)

            Text("試合を始める準備をしましょう")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                Button {
                    viewModel.showingSheet = .gameSetup
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("新しい試合を始める")
                    }
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    viewModel.showingSheet = .players
                } label: {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("選手を登録する")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.yellow)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.yellow.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Active Game View
    private var activeGameView: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 8) {
                    // Inning progress bar
                    InningProgressBar(viewModel: viewModel)

                    // Quick action buttons
                    HStack(spacing: 6) {
                        Spacer()
                        NavPill(title: "選手登録") { viewModel.showingSheet = .players }
                        NavPill(title: "相手情報") { viewModel.showingSheet = .opponent }
                        NavPill(title: "投手交代") { viewModel.showingSheet = .pitcherChange }
                        NavPill(title: "試合ログ") { viewModel.showingSheet = .analysis }
                        NavPill(title: "中止") { viewModel.gameEnded = true }
                    }
                    .padding(.horizontal, 8)

                    // 現在の投手表示
                    if !viewModel.currentPitcherName.isEmpty {
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Text("投手")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                Text(viewModel.currentPitcherName)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            HStack(spacing: 4) {
                                Text("投球数")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                Text("\(viewModel.totalPitchCount)")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.yellow)
                            }
                            HStack(spacing: 4) {
                                Text("投球回")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                Text(viewModel.pitcherInningsText)
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.white)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 4)
                        .background(Color(white: 0.04))
                    }

                    ScoreboardCard(viewModel: viewModel)
                    SituationGrid(viewModel: viewModel, players: players)

                    if viewModel.isOurOffense {
                        // OFFENSE MODE — 相手投手情報 + our batters
                        if !viewModel.oppPitcherName.isEmpty {
                            HStack(spacing: 8) {
                                Text("相手投手")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.red)
                                Text("#\(viewModel.oppPitcherNumber) \(viewModel.oppPitcherName)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                                Text("投球数: \(viewModel.oppPitcherPitchCount)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                // 投手交代ボタン（相手）
                                Button {
                                    // 相手投手の投球数リセット
                                    viewModel.oppPitcherPitchCount = 0
                                    viewModel.oppPitcherName = ""
                                } label: {
                                    Text("交代")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.red)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.red.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 4)
                            .background(Color(red: 0.1, green: 0.03, blue: 0.03))
                        }

                        AtBatCard(viewModel: viewModel, players: players)
                        CountLeverageCard(viewModel: viewModel)
                        RecommendationBanner(viewModel: viewModel, players: players)
                        StrategyListView(
                            viewModel: viewModel,
                            players: players,
                            logs: logs,
                            modelContext: modelContext
                        )
                    } else {
                        // DEFENSE MODE — opponent batters
                        DefenseCard(viewModel: viewModel)
                    }
                }
                .padding(.bottom, 120)
            }
            .overlay(alignment: .bottom) {
                ActionBar(viewModel: viewModel, players: players, logs: logs, modelContext: modelContext)
            }

            // MARK: - Inning Change Overlay
            if viewModel.showInningChange {
                inningChangeOverlay
            }
        }
    }

    // MARK: - Inning Change Overlay
    private var inningChangeOverlay: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("3アウト")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.yellow)

                Text("\(viewModel.state.innings) 終了")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)

                HStack(spacing: 24) {
                    VStack {
                        Text(viewModel.myTeamName)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Text("\(viewModel.state.myScore)")
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                    Text("-")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                    VStack {
                        Text(viewModel.oppTeamName)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Text("\(viewModel.state.oppScore)")
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                }

                // Next half description
                let nextText = viewModel.state.isTop
                    ? "\(viewModel.state.inning)回裏へ"
                    : "\(viewModel.state.inning + 1)回表へ"

                Button {
                    viewModel.performInningChange()
                } label: {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text(nextText)
                    }
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 40)
            }
        }
    }

    // MARK: - Game Over View
    private var gameOverView: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("試合終了")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.yellow)
                .onAppear {
                    // 試合記録を保存
                    let record = GameRecord(myTeamName: viewModel.myTeamName, oppTeamName: viewModel.oppTeamName)
                    record.myScore = viewModel.state.myScore
                    record.oppScore = viewModel.state.oppScore
                    modelContext.insert(record)
                    try? modelContext.save()
                }

            Text(viewModel.state.myScore > viewModel.state.oppScore ? "勝利" : viewModel.state.myScore < viewModel.state.oppScore ? "敗北" : "引き分け")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(viewModel.state.myScore > viewModel.state.oppScore ? .green : .red)

            HStack(spacing: 32) {
                VStack {
                    Text(viewModel.myTeamName)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.state.myScore)")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }
                Text("-")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
                VStack {
                    Text(viewModel.oppTeamName)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.state.oppScore)")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }
            }

            Text("\(viewModel.state.inning)回終了")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)

            Spacer()

            VStack(spacing: 12) {
                // Briefing report button
                NavigationLink(destination: BriefingView(
                    logs: logs, myTeamName: viewModel.myTeamName, oppTeamName: viewModel.oppTeamName
                )) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                        Text("試合レポート（ミーティング用）")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    viewModel.showingSheet = .analysis
                } label: {
                    HStack {
                        Image(systemName: "waveform.path.ecg")
                        Text("試合分析を見る")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.yellow)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.yellow.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    viewModel.resetGame()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("新しい試合へ")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color(white: 0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Inning Progress Bar
struct InningProgressBar: View {
    @Bindable var viewModel: GameViewModel

    var body: some View {
        HStack(spacing: 0) {
            ForEach(1...viewModel.totalInnings, id: \.self) { inning in
                VStack(spacing: 1) {
                    Text("\(inning)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(inning == viewModel.state.inning ? .yellow : inning < viewModel.state.inning ? .white : Color(white: 0.3))
                    Circle()
                        .fill(inningColor(inning))
                        .frame(width: 6, height: 6)
                }
                .frame(maxWidth: .infinity)
            }
            Text(viewModel.progressText)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color(white: 0.03))
    }

    private func inningColor(_ inning: Int) -> Color {
        if inning < viewModel.state.inning { return .green }
        if inning == viewModel.state.inning { return .yellow }
        return Color(white: 0.2)
    }
}

struct NavPill: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(white: 0.6))
                .padding(.horizontal, 12)
                .frame(height: 28)
                .background(Color(white: 0.15))
                .clipShape(Capsule())
        }
    }
}
