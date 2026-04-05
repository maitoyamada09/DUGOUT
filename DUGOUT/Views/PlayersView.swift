import SwiftUI
import SwiftData

struct PlayersView: View {
    let players: [Player]
    var dismissAction: (() -> Void)? = nil
    @Environment(\.modelContext) private var modelContext
    @Query private var opponents: [Opponent]
    @State private var selectedSection = 0
    @State private var filterPosition: String = "全"
    @State private var showAddPlayer = false
    @State private var showAddOpponent = false

    private var filtered: [Player] {
        let sorted = players.sorted { $0.number.localizedStandardCompare($1.number) == .orderedAscending }
        if filterPosition == "全" { return sorted }
        return sorted.filter { $0.position == filterPosition }
    }

    /// Most recently added player (last in array)
    private var newestPlayer: Player? {
        players.sorted { $0.createdAt > $1.createdAt }.first
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
            .sheet(isPresented: $showAddPlayer) {
                if let p = newestPlayer {
                    NavigationStack {
                        PlayerDetailView(player: p)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("閉じる") { showAddPlayer = false }
                                        .foregroundStyle(.secondary)
                                }
                            }
                    }
                    .preferredColorScheme(.dark)
                }
            }
            // Add opponent sheet
            .sheet(isPresented: $showAddOpponent) {
                if let opp = opponents.sorted(by: { $0.createdAt > $1.createdAt }).first {
                    NavigationStack {
                        OpponentDetailView(opponent: opp)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("閉じる") { showAddOpponent = false }
                                        .foregroundStyle(.secondary)
                                }
                            }
                    }
                    .preferredColorScheme(.dark)
                }
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
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.yellow)
                        Text("選手を追加する")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.yellow)
                        Spacer()
                        Text("\(players.count)人")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .frame(minHeight: 54)
                }
                .listRowBackground(Color.yellow.opacity(0.1))

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
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.red)
                    Text("相手チームを追加する")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.red)
                    Spacer()
                }
                .frame(minHeight: 54)
            }
            .listRowBackground(Color.red.opacity(0.08))

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
        // Small delay to let SwiftData process, then show sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showAddPlayer = true
        }
    }

    private func addOpponent() {
        let opp = Opponent()
        modelContext.insert(opp)
        try? modelContext.save()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showAddOpponent = true
        }
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
