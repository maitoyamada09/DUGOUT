import SwiftUI
import SwiftData

struct LineupView: View {
    @Bindable var viewModel: GameViewModel
    let players: [Player]
    @Query private var opponents: [Opponent]
    @State private var selectedSection = 0

    private var allOppPlayers: [OpponentPlayer] {
        opponents.flatMap(\.players).sorted {
            $0.number.localizedStandardCompare($1.number) == .orderedAscending
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedSection) {
                    Text("自チーム打順").tag(0)
                    Text("相手チーム打順").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                if selectedSection == 0 {
                    ourLineup
                } else {
                    oppLineup
                }
            }
            .navigationTitle("打順設定")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("クリア") {
                        if selectedSection == 0 {
                            viewModel.lineup = Array(repeating: nil, count: 9)
                        } else {
                            viewModel.oppLineup = Array(repeating: nil, count: 9)
                        }
                    }
                    .foregroundStyle(.red)
                }
            }
        }
    }

    // MARK: - 自チーム打順
    private var ourLineup: some View {
        List {
            ForEach(0..<9, id: \.self) { index in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(.yellow)
                        .frame(width: 30)

                    Picker("", selection: myLineupBinding(for: index)) {
                        Text("未選択").tag(UUID?.none)
                        ForEach(availableMyPlayers(for: index), id: \.id) { p in
                            Text("#\(p.number) \(p.name) \(p.batHand) (\(p.position))")
                                .tag(UUID?.some(p.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.white)

                    Spacer()

                    if let pid = viewModel.lineup[index],
                       let p = players.first(where: { $0.id == pid }) {
                        Text(p.batHand)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(minHeight: 44)
                .listRowBackground(Color(white: 0.08))
            }
        }
        .listStyle(.plain)
    }

    // MARK: - 相手チーム打順
    private var oppLineup: some View {
        List {
            if allOppPlayers.isEmpty {
                Text("相手チームの選手を先に登録してください")
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color(white: 0.08))
            } else {
                ForEach(0..<9, id: \.self) { index in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundStyle(.red)
                            .frame(width: 30)

                        Picker("", selection: oppLineupBinding(for: index)) {
                            Text("未選択").tag(UUID?.none)
                            ForEach(availableOppPlayers(for: index), id: \.id) { p in
                                Text("#\(p.number) \(p.name.isEmpty ? "不明" : p.name)")
                                    .tag(UUID?.some(p.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.white)

                        Spacer()

                        if let pid = viewModel.oppLineup[index],
                           let p = allOppPlayers.first(where: { $0.id == pid }) {
                            if p.isPitcher {
                                Text("投")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .frame(minHeight: 44)
                    .listRowBackground(Color(white: 0.08))
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Bindings
    private func myLineupBinding(for index: Int) -> Binding<UUID?> {
        Binding(get: { viewModel.lineup[index] }, set: { viewModel.lineup[index] = $0 })
    }

    private func oppLineupBinding(for index: Int) -> Binding<UUID?> {
        Binding(get: { viewModel.oppLineup[index] }, set: { viewModel.oppLineup[index] = $0 })
    }

    private func availableMyPlayers(for index: Int) -> [Player] {
        let usedIDs = viewModel.lineup.enumerated().filter { $0.offset != index }.compactMap { $0.element }
        return players.filter { !usedIDs.contains($0.id) }.sorted { $0.number.localizedStandardCompare($1.number) == .orderedAscending }
    }

    private func availableOppPlayers(for index: Int) -> [OpponentPlayer] {
        let usedIDs = viewModel.oppLineup.enumerated().filter { $0.offset != index }.compactMap { $0.element }
        return allOppPlayers.filter { !usedIDs.contains($0.id) }
    }
}
