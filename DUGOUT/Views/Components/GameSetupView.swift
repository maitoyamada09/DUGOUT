import SwiftUI
import SwiftData

struct GameSetupView: View {
    @Bindable var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    @Query private var opponents: [Opponent]

    @AppStorage("myTeamName") private var savedTeamName = ""
    @AppStorage("gameLevel") private var gameLevel = "高校野球"
    @State private var myTeam: String = ""
    @State private var selectedOpponent: Opponent? = nil
    @State private var selectedInnings: Int = 7

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Title
                VStack(spacing: 6) {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.yellow)
                    Text("試合を始める")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.top, 16)

                // My team name
                VStack(spacing: 8) {
                    Text("自チーム")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)

                    TextField("チーム名を入力", text: $myTeam)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.yellow)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
                .background(Color(white: 0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)

                // Opponent team selection (pick from saved teams)
                VStack(spacing: 8) {
                    Text("相手チーム")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)

                    if opponents.isEmpty {
                        Text("相手チームが未登録です。\n「選手」タブの「相手チーム」から追加してください。")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(white: 0.4))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(opponents, id: \.id) { opp in
                                    Button {
                                        selectedOpponent = opp
                                    } label: {
                                        VStack(spacing: 4) {
                                            Text(opp.teamName.isEmpty ? "未入力" : opp.teamName)
                                                .font(.system(size: 15, weight: .bold))
                                            if !opp.pitcherName.isEmpty {
                                                Text("投: \(opp.pitcherName)")
                                                    .font(.system(size: 10))
                                            }
                                            Text("\(opp.players.count)人")
                                                .font(.system(size: 10))
                                        }
                                        .frame(minWidth: 100, minHeight: 60)
                                        .padding(.horizontal, 12)
                                        .background(
                                            selectedOpponent?.id == opp.id
                                                ? Color.red.opacity(0.3)
                                                : Color(white: 0.12)
                                        )
                                        .foregroundStyle(
                                            selectedOpponent?.id == opp.id ? .white : .secondary
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(
                                                    selectedOpponent?.id == opp.id ? Color.red : Color.clear,
                                                    lineWidth: 2
                                                )
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.vertical, 12)
                .background(Color(white: 0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)

                // Game level
                VStack(spacing: 8) {
                    Text("試合レベル")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)

                    let levels = ["少年野球", "中学野球", "高校野球", "大学野球", "社会人", "草野球"]
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        ForEach(levels, id: \.self) { level in
                            Button {
                                gameLevel = level
                            } label: {
                                Text(level)
                                    .font(.system(size: 13, weight: .bold))
                                    .frame(maxWidth: .infinity, minHeight: 38)
                                    .background(gameLevel == level ? Color.yellow : Color(white: 0.12))
                                    .foregroundStyle(gameLevel == level ? .black : .white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
                .background(Color(white: 0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)

                // Innings
                VStack(spacing: 8) {
                    Text("イニング数")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        inningsButton(5, label: "5回")
                        inningsButton(7, label: "7回")
                        inningsButton(9, label: "9回")
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
                .background(Color(white: 0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)

                Spacer()

                // Start button
                Button {
                    let oppName = selectedOpponent?.teamName ?? "相手"
                    viewModel.startNewGame(myTeam: myTeam, oppTeam: oppName, innings: selectedInnings)
                    // 相手投手情報をセット
                    if let opp = selectedOpponent {
                        viewModel.oppPitcherName = opp.pitcherName
                        viewModel.oppPitcherNumber = opp.pitcherNumber
                        viewModel.oppPitcherTags = opp.pitchTags
                    }
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("プレイボール")
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(Color.black)
            .navigationTitle("試合設定")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if myTeam.isEmpty && !savedTeamName.isEmpty {
                    myTeam = savedTeamName
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func inningsButton(_ innings: Int, label: String) -> some View {
        Button {
            selectedInnings = innings
        } label: {
            Text(label)
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(selectedInnings == innings ? Color.yellow : Color(white: 0.15))
                .foregroundStyle(selectedInnings == innings ? .black : .white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
