import SwiftUI
import SwiftData

// MARK: - Defense Mode Card (shown when opponent is batting)
struct DefenseCard: View {
    @Bindable var viewModel: GameViewModel
    @Query private var opponents: [Opponent]
    @Query private var atBatRecords: [AtBatRecord]
    @Environment(\.modelContext) private var modelContext
    @State private var showResultSheet = false

    private var allOppPlayers: [OpponentPlayer] {
        opponents.flatMap(\.players)
    }

    private var currentOpp: OpponentPlayer? {
        viewModel.currentOppBatter(opponents: allOppPlayers)
    }
    private var nextOpp: OpponentPlayer? {
        viewModel.nextOppBatter(opponents: allOppPlayers)
    }

    private func oppStats(_ player: OpponentPlayer) -> PlayerStats {
        PlayerStats(records: atBatRecords.filter { $0.playerId == player.id && $0.isOpponent })
    }

    var body: some View {
        VStack(spacing: 10) {
            // Header
            HStack {
                Text("相手の攻撃")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.red)
                Spacer()
                Text("\(viewModel.oppOrderNum)番打者")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            if let opp = currentOpp {
                // Opponent batter info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("#\(opp.number)")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(.red)
                            Text(opp.name.isEmpty ? "不明" : opp.name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        // Tags
                        if !opp.tags.isEmpty {
                            HStack(spacing: 4) {
                                ForEach(opp.tags.prefix(4), id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 10, weight: .medium))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.red.opacity(0.15))
                                        .foregroundStyle(.red)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    Spacer()

                    // Opponent's recorded stats
                    let stats = oppStats(opp)
                    if stats.plateAppearances > 0 {
                        HStack(spacing: 8) {
                            VStack(spacing: 1) {
                                Text("打率")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.secondary)
                                Text(stats.baText)
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundStyle(stats.battingAverage >= 0.300 ? .red : .white)
                            }
                            VStack(spacing: 1) {
                                Text("打数")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.secondary)
                                Text(stats.summaryLine)
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Memo
                if !opp.memo.isEmpty {
                    Text(opp.memo)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Record result button
                Button {
                    showResultSheet = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.pencil")
                        Text("打席結果を記録")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.red.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Next batter
                if let next = nextOpp {
                    HStack(spacing: 4) {
                        Text("NEXT")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
                        Text("#\(next.number) \(next.name)")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(white: 0.5))
                        if !next.tags.isEmpty {
                            Text(next.tags.first ?? "")
                                .font(.system(size: 9))
                                .foregroundStyle(.red.opacity(0.6))
                        }
                        Spacer()
                    }
                }
            } else {
                // No opponent lineup set
                VStack(spacing: 8) {
                    Text("相手の打順が未設定です")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    Text("「相手」ボタンからチーム・選手を登録し、\n打順タブで設定してください")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(white: 0.4))
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(12)
        .background(Color(red: 0.15, green: 0.05, blue: 0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 8)
        .sheet(isPresented: $showResultSheet) {
            OppAtBatSheet(viewModel: viewModel, opponent: currentOpp)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Opponent At-Bat Result Sheet
struct OppAtBatSheet: View {
    @Bindable var viewModel: GameViewModel
    let opponent: OpponentPlayer?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var atBatResult: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let opp = opponent {
                        Text("#\(opp.number) \(opp.name)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.red)
                    }

                    Text("\(viewModel.state.innings) \(viewModel.state.outs)アウト")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)

                    Divider().background(Color(white: 0.2)).padding(.horizontal)

                    // Hit results
                    VStack(alignment: .leading, spacing: 6) {
                        Text("出塁")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 16)

                        LazyVGrid(columns: [
                            GridItem(.flexible()), GridItem(.flexible()),
                            GridItem(.flexible()), GridItem(.flexible())
                        ], spacing: 6) {
                            ForEach(AtBatRecord.hitResults, id: \.id) { item in
                                resultChip(label: item.label, value: item.id, color: .red)
                            }
                        }
                        .padding(.horizontal, 12)
                    }

                    // Out results
                    VStack(alignment: .leading, spacing: 6) {
                        Text("アウト")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 16)

                        LazyVGrid(columns: [
                            GridItem(.flexible()), GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 6) {
                            ForEach(AtBatRecord.outResults, id: \.id) { item in
                                resultChip(label: item.label, value: item.id, color: .green)
                            }
                        }
                        .padding(.horizontal, 12)
                    }

                    // Save
                    Button {
                        saveOppAtBat()
                        dismiss()
                    } label: {
                        Text("記録する")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(atBatResult.isEmpty ? Color(white: 0.3) : Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(atBatResult.isEmpty)
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 30)
            }
            .background(Color.black)
            .navigationTitle("相手の打席結果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }.foregroundStyle(.secondary)
                }
            }
        }
    }

    private func resultChip(label: String, value: String, color: Color) -> some View {
        Button {
            atBatResult = value
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(atBatResult == value ? color : color.opacity(0.12))
                .foregroundStyle(atBatResult == value ? .black : color)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func saveOppAtBat() {
        guard let opp = opponent else { return }

        // Save AtBatRecord for opponent
        let record = AtBatRecord(
            playerId: opp.id,
            playerName: opp.name,
            result: atBatResult,
            strategyId: "defense",
            inning: viewModel.state.inning,
            isTop: viewModel.state.isTop,
            isOpponent: true
        )
        modelContext.insert(record)

        // Update game state
        let hitIds = AtBatRecord.hitResults.map(\.id)
        let isHit = hitIds.contains(atBatResult)

        if isHit {
            // Opponent got on base — update bases
            switch atBatResult {
            case "single", "error", "fielderschoice":
                advanceOppRunners(by: 1)
                viewModel.state.bases[0] = true
            case "double":
                advanceOppRunners(by: 2)
                viewModel.state.bases[0] = false
                viewModel.state.bases[1] = true
            case "triple":
                scoreAllOppRunners()
                viewModel.state.bases = [false, false, true]
            case "homerun":
                scoreAllOppRunners()
                viewModel.state.oppScore += 1
                viewModel.state.bases = [false, false, false]
            case "walk", "hitbypitch":
                if viewModel.state.bases[0] && viewModel.state.bases[1] && viewModel.state.bases[2] {
                    viewModel.state.oppScore += 1
                }
                if viewModel.state.bases[0] && viewModel.state.bases[1] {
                    viewModel.state.bases[2] = true
                }
                if viewModel.state.bases[0] {
                    viewModel.state.bases[1] = true
                }
                viewModel.state.bases[0] = true
            default:
                break
            }
        } else {
            // Opponent made out
            switch atBatResult {
            case "doubleplay":
                viewModel.state.outs = min(3, viewModel.state.outs + 2)
                if viewModel.state.bases[0] { viewModel.state.bases[0] = false }
            case "sacfly":
                if viewModel.state.bases[2] {
                    viewModel.state.bases[2] = false
                    viewModel.state.oppScore += 1
                }
                viewModel.state.outs = min(3, viewModel.state.outs + 1)
            case "sacrifice":
                advanceOppRunners(by: 1)
                viewModel.state.outs = min(3, viewModel.state.outs + 1)
            default:
                viewModel.state.outs = min(3, viewModel.state.outs + 1)
            }
        }

        viewModel.state.resetCount()
        viewModel.advanceBatter()
        viewModel.checkInningChange()
    }

    private func advanceOppRunners(by bases: Int) {
        for _ in 0..<bases {
            if viewModel.state.bases[2] {
                viewModel.state.oppScore += 1
                viewModel.state.bases[2] = false
            }
            if viewModel.state.bases[1] {
                viewModel.state.bases[2] = true
                viewModel.state.bases[1] = false
            }
            if viewModel.state.bases[0] {
                viewModel.state.bases[1] = true
                viewModel.state.bases[0] = false
            }
        }
    }

    private func scoreAllOppRunners() {
        for i in 0..<3 {
            if viewModel.state.bases[i] {
                viewModel.state.oppScore += 1
                viewModel.state.bases[i] = false
            }
        }
    }
}
