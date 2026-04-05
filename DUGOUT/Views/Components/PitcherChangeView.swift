import SwiftUI
import SwiftData

/// 投手交代シート — 全選手から投手を選ぶ（野手も投げられる）
struct PitcherChangeView: View {
    @Bindable var viewModel: GameViewModel
    let players: [Player]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var pitcherRecords: [PitcherRecord]

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // 現在の投手
                if !viewModel.currentPitcherName.isEmpty {
                    VStack(spacing: 4) {
                        Text("現在の投手")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text(viewModel.currentPitcherName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.yellow)
                        Text("投球数: \(viewModel.totalPitchCount)")
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(Color(white: 0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)
                }

                Text("交代する投手を選択")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                // 選手リスト（全選手、投手マーク付き）
                List {
                    ForEach(players, id: \.id) { player in
                        Button {
                            // 現在の投手の記録を保存
                            savePitcherRecord()

                            // 新しい投手に交代
                            viewModel.currentPitcherId = player.id
                            viewModel.currentPitcherName = "#\(player.number) \(player.name)"
                            viewModel.currentInningPitchCount = 0
                            viewModel.lastActionLog = "投手交代: \(player.name)"
                            dismiss()
                        } label: {
                            HStack(spacing: 10) {
                                Text("#\(player.number)")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.yellow)
                                    .frame(width: 36)

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(player.name.isEmpty ? "未入力" : player.name)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(.white)
                                        if player.canPitch {
                                            Text(player.throwHand)
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(.yellow)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.yellow.opacity(0.15))
                                                .clipShape(Capsule())
                                        }
                                    }
                                    Text(player.position)
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                // この選手の通算投手成績
                                let stats = PitcherStats(records: pitcherRecords.filter { $0.pitcherId == player.id })
                                if stats.games > 0 {
                                    VStack(alignment: .trailing, spacing: 1) {
                                        Text("ERA \(stats.eraText)")
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundStyle(stats.era <= 3.0 ? .green : stats.era <= 5.0 ? .yellow : .red)
                                        Text("\(stats.games)登板")
                                            .font(.system(size: 9))
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                // 現在の投手マーク
                                if viewModel.currentPitcherId == player.id {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 8))
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        .listRowBackground(
                            viewModel.currentPitcherId == player.id
                                ? Color.yellow.opacity(0.08)
                                : Color(white: 0.08)
                        )
                    }
                }
                .listStyle(.plain)
            }
            .background(Color.black)
            .navigationTitle("投手交代")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    /// 現在の投手の登板記録を保存
    private func savePitcherRecord() {
        guard let pitcherId = viewModel.currentPitcherId else { return }
        let record = PitcherRecord(
            pitcherId: pitcherId,
            pitcherName: viewModel.currentPitcherName,
            isOpponent: false
        )
        record.pitchCount = viewModel.totalPitchCount
        // アウト数から投球回数を自動計算（例: 7アウト = 2.1回）
        let outs = viewModel.pitcherOutsRecorded
        record.inningsPitched = Double(outs / 3) + Double(outs % 3) * 0.1
        modelContext.insert(record)
        try? modelContext.save()
    }
}
