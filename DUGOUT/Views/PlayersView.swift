import SwiftUI
import SwiftData

struct PlayersView: View {
    var dismissAction: (() -> Void)? = nil
    @Environment(\.modelContext) private var modelContext
    @Query private var players: [Player]
    @Query private var opponents: [Opponent]
    @State private var selectedSection = 0
    @State private var filterPosition: String = "全"
    @State private var newPlayer: Player? = nil
    @State private var newOpponent: Opponent? = nil

    private var filtered: [Player] {
        let sorted = players.sorted { $0.number.localizedStandardCompare($1.number) == .orderedAscending }
        if filterPosition == "全" { return sorted }
        return sorted.filter { $0.position == filterPosition }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedSection) {
                    Text("自チーム").tag(0)
                    Text("相手チーム").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                if selectedSection == 0 {
                    ourTeamView
                } else {
                    enemyTeamView
                }
            }
            .navigationTitle("選手一覧")
            .toolbar {
                if let dismiss = dismissAction {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("閉じる") { dismiss() }
                            .foregroundStyle(.secondary)
                    }
                }
            }
            // Add player sheet
            .sheet(item: $newPlayer) { p in
                NavigationStack {
                    PlayerDetailView(player: p)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("閉じる") { newPlayer = nil }
                                    .foregroundStyle(.secondary)
                            }
                        }
                }
                .preferredColorScheme(.dark)
            }
            // Add opponent sheet
            .sheet(item: $newOpponent) { opp in
                NavigationStack {
                    OpponentDetailView(opponent: opp)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("閉じる") { newOpponent = nil }
                                    .foregroundStyle(.secondary)
                            }
                        }
                }
                .preferredColorScheme(.dark)
            }
        }
    }

    // MARK: - Our Team
    private var ourTeamView: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    positionFilterButton("全")
                    ForEach(Player.positions, id: \.self) { pos in
                        positionFilterButton(pos)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .background(Color(white: 0.05))

            List {
                // Big add button
                Button(action: addPlayer) {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.yellow)
                        Text("選手を追加する")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.yellow)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Spacer()
                        Text("\(players.count)人")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .frame(minHeight: 54)
                }
                .listRowBackground(Color.yellow.opacity(0.1))

                // Empty state
                if filtered.isEmpty {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 48))
                                .foregroundStyle(Color(white: 0.2))

                            Text("まだ選手が登録されていません")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color(white: 0.4))

                            VStack(alignment: .leading, spacing: 8) {
                                Label("上の「＋選手を追加する」をタップ", systemImage: "1.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(white: 0.35))
                                Label("背番号・名前・ポジションを入力", systemImage: "2.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(white: 0.35))
                                Label("能力値を設定して保存", systemImage: "3.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(white: 0.35))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                    .listRowBackground(Color.clear)
                }

                ForEach(filtered, id: \.id) { player in
                    NavigationLink(destination: PlayerDetailView(player: player)) {
                        playerRow(player)
                    }
                    .listRowBackground(Color(white: 0.08))
                }
                .onDelete(perform: deletePlayer)
            }
            .listStyle(.plain)
        }
    }

    // MARK: - Enemy Team
    private var enemyTeamView: some View {
        List {
            Button(action: addOpponent) {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.red)
                    Text("相手チームを追加する")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer()
                }
                .frame(minHeight: 54)
            }
            .listRowBackground(Color.red.opacity(0.08))

            if opponents.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.badge.plus")
                            .font(.system(size: 48))
                            .foregroundStyle(Color(white: 0.2))

                        Text("相手チームが未登録です")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color(white: 0.4))

                        Text("上の「＋相手チームを追加する」から\nチーム名と選手を登録できます")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(white: 0.35))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
                .listRowBackground(Color.clear)
            }

            ForEach(opponents, id: \.id) { opp in
                Section {
                    if !opp.pitcherName.isEmpty {
                        HStack {
                            Image(systemName: "figure.baseball")
                                .foregroundStyle(.red)
                            Text("投手: #\(opp.pitcherNumber) \(opp.pitcherName)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .listRowBackground(Color(white: 0.08))
                    }

                    ForEach(opp.players, id: \.id) { player in
                        NavigationLink(destination: OpponentPlayerDetailView(player: player)) {
                            HStack(spacing: 8) {
                                Text("#\(player.number)")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.red)
                                    .frame(width: 36)
                                Text(player.name.isEmpty ? "未入力" : player.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                        }
                        .listRowBackground(Color(white: 0.08))
                    }
                } header: {
                    NavigationLink(destination: OpponentDetailView(opponent: opp)) {
                        HStack {
                            Text(opp.teamName.isEmpty ? "チーム名未入力" : opp.teamName)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(opp.players.count)人")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Actions
    private func addPlayer() {
        let p = Player()
        modelContext.insert(p)
        try? modelContext.save()
        newPlayer = p
    }

    private func addOpponent() {
        let opp = Opponent()
        modelContext.insert(opp)
        try? modelContext.save()
        newOpponent = opp
    }

    // MARK: - Helpers
    private func positionFilterButton(_ pos: String) -> some View {
        Button {
            filterPosition = pos
        } label: {
            Text(pos)
                .font(.system(size: 13, weight: .bold))
                .frame(minWidth: 36, minHeight: 32)
                .padding(.horizontal, 4)
                .background(filterPosition == pos ? Color.yellow : Color(white: 0.15))
                .foregroundStyle(filterPosition == pos ? .black : .white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder
    private func playerRow(_ p: Player) -> some View {
        HStack(spacing: 10) {
            Text("#\(p.number)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(.yellow)
                .frame(width: 40, alignment: .trailing)

            VStack(alignment: .leading, spacing: 2) {
                Text(p.name.isEmpty ? "未入力" : p.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                Text(p.position)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(String(format: "%.1f", p.offensiveScore))
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(p.offensiveScore >= 3.5 ? .green : p.offensiveScore >= 2.0 ? .orange : Color(white: 0.5))
        }
        .padding(.vertical, 4)
    }

    private func deletePlayer(at offsets: IndexSet) {
        for i in offsets {
            modelContext.delete(filtered[i])
        }
    }
}
