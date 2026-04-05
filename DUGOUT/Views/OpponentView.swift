import SwiftUI
import SwiftData

struct OpponentView: View {
    let opponents: [Opponent]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Big add button at top
                Button {
                    let opp = Opponent()
                    modelContext.insert(opp)
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.yellow)
                        Text("相手チームを追加する")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.yellow)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.yellow.opacity(0.08))

                ForEach(opponents, id: \.id) { opp in
                    NavigationLink(destination: OpponentDetailView(opponent: opp)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(opp.teamName.isEmpty ? "未入力" : opp.teamName).font(.system(size: 15, weight: .medium)).foregroundStyle(.white)
                            if !opp.pitcherName.isEmpty {
                                Text("投手: #\(opp.pitcherNumber) \(opp.pitcherName)").font(.system(size: 12)).foregroundStyle(.secondary)
                            }
                            if !opp.pitchTags.isEmpty {
                                HStack(spacing: 4) {
                                    ForEach(opp.pitchTags, id: \.self) { tag in
                                        Text(tag).font(.system(size: 9, weight: .medium)).padding(.horizontal, 6).padding(.vertical, 2).background(Color.yellow.opacity(0.15)).foregroundStyle(.yellow).clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color(white: 0.08))
                }
                .onDelete { offsets in for i in offsets { modelContext.delete(opponents[i]) } }
            }
            .listStyle(.plain)
            .navigationTitle("相手チーム").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("閉じる") { dismiss() }.foregroundStyle(.secondary) }
                ToolbarItem(placement: .primaryAction) { Button { modelContext.insert(Opponent()) } label: { Image(systemName: "plus.circle.fill").foregroundStyle(.yellow) } }
            }
        }
    }
}

struct OpponentDetailView: View {
    @Bindable var opponent: Opponent
    @Environment(\.modelContext) private var modelContext
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 12) {
                    sectionHeader("チーム情報")
                    HStack {
                        Text("チーム名").font(.system(size: 14, weight: .medium)).foregroundStyle(.secondary)
                        Spacer()
                        TextField("チーム名を入力", text: $opponent.teamName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.plain)
                    }.padding(.horizontal, 16)
                }.padding(.vertical, 12).background(Color(white: 0.08)).clipShape(RoundedRectangle(cornerRadius: 12)).padding(.horizontal, 12)

                VStack(spacing: 12) {
                    sectionHeader("投手情報")
                    HStack {
                        Text("背番号").font(.system(size: 14, weight: .medium)).foregroundStyle(.secondary)
                        Spacer()
                        Button { adjustPitcherNumber(-1) } label: { Image(systemName: "minus.circle.fill").font(.system(size: 24)).foregroundStyle(.yellow) }.frame(width: 44, height: 44)
                        Text(opponent.pitcherNumber.isEmpty ? "0" : opponent.pitcherNumber).font(.system(size: 24, weight: .bold, design: .monospaced)).foregroundStyle(.white).frame(width: 50)
                        Button { adjustPitcherNumber(1) } label: { Image(systemName: "plus.circle.fill").font(.system(size: 24)).foregroundStyle(.yellow) }.frame(width: 44, height: 44)
                    }.padding(.horizontal, 16)

                    HStack {
                        Text("名前").font(.system(size: 14, weight: .medium)).foregroundStyle(.secondary)
                        Spacer()
                        TextField("投手名を入力", text: $opponent.pitcherName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.plain)
                    }.padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("特徴タグ").font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary).padding(.horizontal, 16)
                        FlowLayout(spacing: 6) {
                            ForEach(Opponent.pitchTagOptions, id: \.self) { tag in
                                TagToggle(label: tag, isOn: opponent.pitchTags.contains(tag), onToggle: {
                                    if opponent.pitchTags.contains(tag) { opponent.pitchTags.removeAll { $0 == tag } } else { opponent.pitchTags.append(tag) }
                                })
                            }
                        }.padding(.horizontal, 16)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("メモ").font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary).padding(.horizontal, 16)
                        FlowLayout(spacing: 6) {
                            ForEach(pitcherMemoPresets, id: \.self) { preset in
                                TagToggle(label: preset, isOn: opponent.pitcherMemo.contains(preset), onToggle: {
                                    if opponent.pitcherMemo.contains(preset) { opponent.pitcherMemo = opponent.pitcherMemo.replacingOccurrences(of: preset, with: "").trimmingCharacters(in: .whitespaces) } else { opponent.pitcherMemo = opponent.pitcherMemo.isEmpty ? preset : "\(opponent.pitcherMemo) \(preset)" }
                                })
                            }
                        }.padding(.horizontal, 16)
                        if !opponent.pitcherMemo.isEmpty { Text(opponent.pitcherMemo).font(.system(size: 11)).foregroundStyle(.secondary).padding(.horizontal, 16) }
                    }
                }.padding(.vertical, 12).background(Color(white: 0.08)).clipShape(RoundedRectangle(cornerRadius: 12)).padding(.horizontal, 12)

                VStack(spacing: 8) {
                    HStack {
                        sectionHeader("相手選手")
                        Spacer()
                        // 1人追加
                        Button { opponent.players.append(OpponentPlayer()) } label: {
                            Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundStyle(.yellow)
                        }.frame(width: 44, height: 44)
                    }
                    .padding(.trailing, 12)

                    // 番号だけで一括登録
                    if opponent.players.isEmpty {
                        Button {
                            for i in 1...9 {
                                let p = OpponentPlayer(number: "\(i)")
                                opponent.players.append(p)
                            }
                            try? modelContext.save()
                        } label: {
                            HStack {
                                Image(systemName: "number.circle")
                                Text("1〜9番を一括登録（番号のみ）")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(.horizontal, 16)
                    }
                    ForEach(opponent.players, id: \.id) { player in
                        NavigationLink(destination: OpponentPlayerDetailView(player: player)) {
                            HStack {
                                Text("#\(player.number)").font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundStyle(.yellow).frame(width: 36)
                                Text(player.name.isEmpty ? "未入力" : player.name).font(.system(size: 14, weight: .medium)).foregroundStyle(.white)
                                Spacer()
                                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(.secondary)
                            }.padding(10).background(Color(white: 0.12)).clipShape(RoundedRectangle(cornerRadius: 8))
                        }.padding(.horizontal, 12)
                    }
                }.padding(.vertical, 12).background(Color(white: 0.08)).clipShape(RoundedRectangle(cornerRadius: 12)).padding(.horizontal, 12)
            }.padding(.vertical, 8)
        }
        .background(Color.black)
        .navigationTitle(opponent.teamName.isEmpty ? "新規チーム" : opponent.teamName).navigationBarTitleDisplayMode(.inline)
        // Names use keyboard input directly
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack { Text(title).font(.system(size: 13, weight: .bold)).foregroundStyle(.yellow); Spacer() }.padding(.horizontal, 16)
    }
    private func adjustPitcherNumber(_ delta: Int) { let c = Int(opponent.pitcherNumber) ?? 0; opponent.pitcherNumber = "\(max(0, min(99, c + delta)))" }
    private var pitcherMemoPresets: [String] { ["球速遅め","球速速い","変化球主体","ストレート主体","コントロール良","荒れ球","スタミナ不安","初回弱い","ランナー出すと弱い","左打者に強い","右打者に強い","クセ見える"] }
}

struct OpponentPlayerDetailView: View {
    @Bindable var player: OpponentPlayer
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 12) {
                    HStack {
                        Text("背番号").font(.system(size: 14, weight: .medium)).foregroundStyle(.secondary)
                        Spacer()
                        Button { adjustNumber(-1) } label: { Image(systemName: "minus.circle.fill").font(.system(size: 24)).foregroundStyle(.yellow) }.frame(width: 44, height: 44)
                        Text(player.number.isEmpty ? "0" : player.number).font(.system(size: 24, weight: .bold, design: .monospaced)).foregroundStyle(.white).frame(width: 50)
                        Button { adjustNumber(1) } label: { Image(systemName: "plus.circle.fill").font(.system(size: 24)).foregroundStyle(.yellow) }.frame(width: 44, height: 44)
                    }.padding(.horizontal, 16)
                    HStack {
                        Text("名前").font(.system(size: 14, weight: .medium)).foregroundStyle(.secondary)
                        Spacer()
                        TextField("選手名を入力", text: $player.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.plain)
                    }.padding(.horizontal, 16)
                }.padding(.vertical, 12).background(Color(white: 0.08)).clipShape(RoundedRectangle(cornerRadius: 12)).padding(.horizontal, 12)

                VStack(alignment: .leading, spacing: 8) {
                    Text("特徴タグ").font(.system(size: 13, weight: .bold)).foregroundStyle(.yellow).padding(.horizontal, 16)
                    FlowLayout(spacing: 6) {
                        ForEach(OpponentPlayer.tagOptions, id: \.self) { tag in
                            TagToggle(label: tag, isOn: player.tags.contains(tag), onToggle: {
                                if player.tags.contains(tag) { player.tags.removeAll { $0 == tag } } else { player.tags.append(tag) }
                            })
                        }
                    }.padding(.horizontal, 16)
                }.padding(.vertical, 12).background(Color(white: 0.08)).clipShape(RoundedRectangle(cornerRadius: 12)).padding(.horizontal, 12)

                VStack(alignment: .leading, spacing: 8) {
                    Text("メモ").font(.system(size: 13, weight: .bold)).foregroundStyle(.yellow).padding(.horizontal, 16)
                    FlowLayout(spacing: 6) {
                        ForEach(playerMemoPresets, id: \.self) { preset in
                            TagToggle(label: preset, isOn: player.memo.contains(preset), onToggle: {
                                if player.memo.contains(preset) { player.memo = player.memo.replacingOccurrences(of: preset, with: "").trimmingCharacters(in: .whitespaces) } else { player.memo = player.memo.isEmpty ? preset : "\(player.memo) \(preset)" }
                            })
                        }
                    }.padding(.horizontal, 16)
                    if !player.memo.isEmpty { Text(player.memo).font(.system(size: 11)).foregroundStyle(.secondary).padding(.horizontal, 16) }
                }.padding(.vertical, 12).background(Color(white: 0.08)).clipShape(RoundedRectangle(cornerRadius: 12)).padding(.horizontal, 12)

                // 投手設定
                VStack(spacing: 12) {
                    HStack {
                        Text("投手設定")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding(.horizontal, 16)

                    HStack {
                        Text("投手として登録")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                        Spacer()
                        Toggle("", isOn: $player.isPitcher)
                            .tint(.red)
                    }
                    .padding(.horizontal, 16)

                    if player.isPitcher {
                        HStack {
                            Text("投げ手")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                            Spacer()
                            ForEach(["右投", "左投"], id: \.self) { hand in
                                Button {
                                    player.throwHand = hand
                                } label: {
                                    Text(hand)
                                        .font(.system(size: 13, weight: .bold))
                                        .frame(width: 56, height: 34)
                                        .background(player.throwHand == hand ? Color.red : Color(white: 0.15))
                                        .foregroundStyle(player.throwHand == hand ? .black : .white)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        FlowLayout(spacing: 6) {
                            ForEach(OpponentPlayer.pitcherTagOptions, id: \.self) { tag in
                                TagToggle(label: tag, isOn: player.pitchTags.contains(tag), onToggle: {
                                    if player.pitchTags.contains(tag) { player.pitchTags.removeAll { $0 == tag } }
                                    else { player.pitchTags.append(tag) }
                                })
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 12)
                .background(Color(white: 0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 12)
            }.padding(.vertical, 8)
        }
        .background(Color.black)
        .navigationTitle(player.name.isEmpty ? "新規選手" : player.name).navigationBarTitleDisplayMode(.inline)
    }

    private func adjustNumber(_ delta: Int) { let c = Int(player.number) ?? 0; player.number = "\(max(0, min(99, c + delta)))" }
    private var playerMemoPresets: [String] { ["要警戒","初球打ち","粘り強い","早打ち","バント上手","足が速い","走ってくる","内角弱","外角弱","高め弱","低め弱","変化球弱","ストレート弱","チャンスに強い"] }
}

struct TagToggle: View {
    let label: String; let isOn: Bool; let onToggle: () -> Void
    var body: some View {
        Button(action: onToggle) {
            Text(label).font(.system(size: 12, weight: .medium)).padding(.horizontal, 10).padding(.vertical, 6)
                .background(isOn ? Color.yellow.opacity(0.2) : Color(white: 0.15))
                .foregroundStyle(isOn ? .yellow : .secondary).clipShape(Capsule())
                .overlay(Capsule().stroke(isOn ? Color.yellow.opacity(0.4) : Color.clear, lineWidth: 1))
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize { layout(proposal: proposal, subviews: subviews).size }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() { subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified) }
    }
    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity; var positions: [CGPoint] = []; var x: CGFloat = 0; var y: CGFloat = 0; var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            positions.append(CGPoint(x: x, y: y)); rowHeight = max(rowHeight, size.height); x += size.width + spacing
        }
        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
