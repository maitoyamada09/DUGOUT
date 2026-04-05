import SwiftUI
import SwiftData

struct PlayerDetailView: View {
    @Bindable var player: Player
    @Environment(\.dismiss) private var dismiss
    @Query private var atBatRecords: [AtBatRecord]
    @Query private var strategyLogs: [StrategyLog]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // MARK: - Basic Info
                VStack(spacing: 12) {
                    sectionHeader("基本情報")

                    HStack {
                        Text("背番号")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button { adjustNumber(-1) } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.yellow)
                        }
                        .frame(width: 44, height: 44)

                        Text(player.number.isEmpty ? "0" : player.number)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                            .frame(width: 50)

                        Button { adjustNumber(1) } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.yellow)
                        }
                        .frame(width: 44, height: 44)
                    }
                    .padding(.horizontal, 16)

                    HStack {
                        Text("名前")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("選手名を入力", text: $player.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.plain)
                    }
                    .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("ポジション")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Player.positions, id: \.self) { pos in
                                    Button { player.position = pos } label: {
                                        Text(pos)
                                            .font(.system(size: 14, weight: .bold))
                                            .frame(width: 44, height: 44)
                                            .background(player.position == pos ? Color.yellow : Color(white: 0.15))
                                            .foregroundStyle(player.position == pos ? .black : .white)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    // 打者の利き手
                    HStack {
                        Text("打席")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        ForEach(["右打", "左打", "両打"], id: \.self) { hand in
                            Button {
                                player.batHand = hand
                            } label: {
                                Text(hand)
                                    .font(.system(size: 13, weight: .bold))
                                    .frame(width: 56, height: 36)
                                    .background(player.batHand == hand ? Color.yellow : Color(white: 0.15))
                                    .foregroundStyle(player.batHand == hand ? .black : .white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
                .background(Color(white: 0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 12)

                // MARK: - Abilities (Preset buttons)
                VStack(spacing: 16) {
                    sectionHeader("能力値")

                    Text("試合を記録するたびに実績データから自動更新されます")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(white: 0.4))
                        .padding(.horizontal, 16)

                    // 打率
                    abilityPresetSection(label: "打率", icon: "circle.fill", currentGrade: player.hitting, currentRaw: player.rawHitting, presets: [(".300+", ".300", 5), (".250", ".250", 4), (".200", ".200", 3), (".150", ".150", 2), (".100-", ".100", 1)], onSelect: { raw, grade in player.rawHitting = raw; player.hitting = grade })

                    // 長打率（SLG）
                    abilityPresetSection(label: "長打率(SLG)", icon: "arrow.up.right", currentGrade: player.power, currentRaw: player.rawPower, presets: [(".500+", ".500", 5), (".400", ".400", 4), (".300", ".300", 3), (".200", ".200", 2), (".100-", ".100", 1)], onSelect: { raw, grade in player.rawPower = raw; player.power = grade })

                    // 出塁率（OBP）= 四球力の代わり
                    abilityPresetSection(label: "出塁率(OBP)", icon: "arrow.right.circle", currentGrade: player.eyeLevel, currentRaw: player.rawEyeLevel, presets: [(".400+", ".400", 5), (".350", ".350", 4), (".300", ".300", 3), (".250", ".250", 2), (".200-", ".200", 1)], onSelect: { raw, grade in player.rawEyeLevel = raw; player.eyeLevel = grade })

                    // バント成功率
                    abilityPresetSection(label: "バント成功率", icon: "hand.point.down", currentGrade: player.bunting, currentRaw: player.rawBunting, presets: [("90%+", "90", 5), ("75%", "75", 4), ("60%", "60", 3), ("40%", "40", 2), ("39%-", "39", 1)], onSelect: { raw, grade in player.rawBunting = raw; player.bunting = grade })

                    // 走力（50m）
                    abilityPresetSection(label: "走力（50m）", icon: "figure.run", currentGrade: player.speed, currentRaw: player.rawSpeed, presets: [("6.0s以下", "6.0", 5), ("6.5s", "6.5", 4), ("7.0s", "7.0", 3), ("7.5s", "7.5", 2), ("8.0s+", "8.0", 1)], onSelect: { raw, grade in player.rawSpeed = raw; player.speed = grade })

                    // セーフティバント
                    abilityPresetSection(label: "セーフティ", icon: "shield.fill", currentGrade: player.safetyBunt, currentRaw: player.rawSafetyBunt, presets: [("実績多", "5", 5), ("何度も", "4", 4), ("数回", "3", 3), ("1-2回", "2", 2), ("未経験", "1", 1)], onSelect: { raw, grade in player.rawSafetyBunt = raw; player.safetyBunt = grade })

                    // 盗塁成功率
                    abilityPresetSection(label: "盗塁成功率", icon: "hare.fill", currentGrade: player.stealing, currentRaw: player.rawStealing, presets: [("85%+", "85", 5), ("70%", "70", 4), ("55%", "55", 3), ("40%", "40", 2), ("39%-", "39", 1)], onSelect: { raw, grade in player.rawStealing = raw; player.stealing = grade })
                }
                .padding(.vertical, 12)
                .background(Color(white: 0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 12)

                // MARK: - 投手設定
                VStack(spacing: 12) {
                    sectionHeader("投手設定")

                    // 投手フラグ
                    HStack {
                        Text("投手として登録")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                        Spacer()
                        Toggle("", isOn: $player.canPitch)
                            .tint(.yellow)
                    }
                    .padding(.horizontal, 16)

                    if player.canPitch {
                        // 投げ手
                        HStack {
                            Text("投げ手")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                            Spacer()
                            ForEach(["右投", "左投"], id: \.self) { hand in
                                Button {
                                    player.throwHand = hand
                                } label: {
                                    Text(hand)
                                        .font(.system(size: 13, weight: .bold))
                                        .frame(width: 60, height: 36)
                                        .background(player.throwHand == hand ? Color.yellow : Color(white: 0.15))
                                        .foregroundStyle(player.throwHand == hand ? .black : .white)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // 球種
                        VStack(alignment: .leading, spacing: 6) {
                            Text("球種")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 16)

                            let pitchOptions = ["ストレート", "カーブ", "スライダー", "チェンジアップ",
                                                "フォーク", "カットボール", "シンカー", "ツーシーム",
                                                "ナックル", "シュート", "スクリュー", "パーム"]

                            FlowLayout(spacing: 6) {
                                ForEach(pitchOptions, id: \.self) { pitch in
                                    Button {
                                        if player.pitchTypes.contains(pitch) {
                                            player.pitchTypes.removeAll { $0 == pitch }
                                        } else {
                                            player.pitchTypes.append(pitch)
                                        }
                                    } label: {
                                        Text(pitch)
                                            .font(.system(size: 12, weight: .medium))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(player.pitchTypes.contains(pitch) ? Color.yellow.opacity(0.2) : Color(white: 0.15))
                                            .foregroundStyle(player.pitchTypes.contains(pitch) ? .yellow : .secondary)
                                            .clipShape(Capsule())
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
                .padding(.horizontal, 12)

                // Score
                HStack {
                    Text("総合攻撃力")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f / 5.0", player.offensiveScore))
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundStyle(player.offensiveScore >= 3.5 ? .green : player.offensiveScore >= 2.0 ? .orange : Color(white: 0.5))
                }
                .padding(16)
                .background(Color(white: 0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 12)

                // Memo
                VStack(alignment: .leading, spacing: 8) {
                    sectionHeader("メモ")
                    FlowLayout(spacing: 6) {
                        ForEach(memoPresets, id: \.self) { preset in
                            TagToggle(label: preset, isOn: player.note.contains(preset), onToggle: {
                                if player.note.contains(preset) {
                                    player.note = player.note.replacingOccurrences(of: preset, with: "").trimmingCharacters(in: .whitespaces)
                                } else {
                                    player.note = player.note.isEmpty ? preset : "\(player.note) \(preset)"
                                }
                            })
                        }
                    }
                    .padding(.horizontal, 16)

                    if !player.note.isEmpty {
                        Text(player.note).font(.system(size: 12)).foregroundStyle(.secondary).padding(.horizontal, 16)
                    }
                    Button { player.note = "" } label: { Text("メモをクリア").font(.system(size: 12)).foregroundStyle(.red) }.padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
                .background(Color(white: 0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 12)

                // MARK: - Auto-calculate from recorded data
                let myRecords = atBatRecords.filter { $0.playerId == player.id && !$0.isOpponent }
                if !myRecords.isEmpty {
                    Button {
                        player.updateAbilitiesFromStats(atBats: atBatRecords, strategyLogs: strategyLogs)
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("実績データから能力値を自動計算")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.yellow)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.yellow.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.horizontal, 16)

                    // Show current recorded stats
                    let stats = PlayerStats(records: myRecords)
                    HStack(spacing: 16) {
                        VStack(spacing: 2) {
                            Text("打率").font(.system(size: 10)).foregroundStyle(.secondary)
                            Text(stats.baText).font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundStyle(.white)
                        }
                        VStack(spacing: 2) {
                            Text("OPS").font(.system(size: 10)).foregroundStyle(.secondary)
                            Text(stats.opsText).font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundStyle(.white)
                        }
                        VStack(spacing: 2) {
                            Text("打数").font(.system(size: 10)).foregroundStyle(.secondary)
                            Text("\(stats.atBats)").font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundStyle(.white)
                        }
                        VStack(spacing: 2) {
                            Text("安打").font(.system(size: 10)).foregroundStyle(.secondary)
                            Text("\(stats.hits)").font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundStyle(.white)
                        }
                        VStack(spacing: 2) {
                            Text("本塁打").font(.system(size: 10)).foregroundStyle(.secondary)
                            Text("\(stats.homeRuns)").font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundStyle(.white)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(Color(white: 0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 12)
                }

                // MARK: - Register / Done Button
                Button {
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text(player.name.isEmpty ? "登録する" : "\(player.name)を保存")
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
            .padding(.vertical, 8)
        }
        .background(Color.black)
        .navigationTitle(player.name.isEmpty ? "新規選手" : player.name)
        .navigationBarTitleDisplayMode(.inline)
        // Name uses keyboard input directly
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack { Text(title).font(.system(size: 13, weight: .bold)).foregroundStyle(.yellow); Spacer() }.padding(.horizontal, 16)
    }

    private func adjustNumber(_ delta: Int) {
        let current = Int(player.number) ?? 0
        player.number = "\(max(0, min(99, current + delta)))"
    }

    @ViewBuilder
    private func abilityPresetSection(label: String, icon: String, currentGrade: Int, currentRaw: String, presets: [(display: String, raw: String, grade: Int)], onSelect: @escaping (String, Int) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13)).foregroundStyle(.yellow).frame(width: 18)
                Text(label).font(.system(size: 13, weight: .semibold)).foregroundStyle(.white).frame(width: 80, alignment: .leading)
                Spacer()
                if currentGrade > 0 { gradeCircle(currentGrade) }
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(presets, id: \.display) { preset in
                        Button {
                            if currentGrade == preset.grade { onSelect("", 0) } else { onSelect(preset.raw, preset.grade) }
                        } label: {
                            VStack(spacing: 2) {
                                Text(preset.display).font(.system(size: 12, weight: .bold))
                                Text("\(preset.grade)").font(.system(size: 10, weight: .medium, design: .monospaced))
                            }
                            .frame(minWidth: 56, minHeight: 44)
                            .padding(.horizontal, 4)
                            .background(currentGrade == preset.grade ? gradeColor(preset.grade) : Color(white: 0.15))
                            .foregroundStyle(currentGrade == preset.grade ? .black : .white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func gradeCircle(_ v: Int) -> some View {
        Text("\(v)").font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundStyle(.black).frame(width: 28, height: 28).background(gradeColor(v)).clipShape(Circle())
    }

    private func gradeColor(_ v: Int) -> Color {
        switch v { case 5: return .green; case 4: return Color(red: 0.4, green: 0.85, blue: 0.2); case 3: return .yellow; case 2: return .orange; case 1: return .red; default: return Color(white: 0.3) }
    }

    private var memoPresets: [String] {
        ["右打","左打","スイッチ","長打あり","粘り強い","早打ち","初球注意","追い込まれ弱","ランナーに強い","チャンスに強い","代走要員","代打要員","守備固め","要注意"]
    }
}

struct NameInputPad: View {
    @Binding var name: String
    @Environment(\.dismiss) private var dismiss

    private let kanaRows: [[String]] = [
        ["ア","イ","ウ","エ","オ"],["カ","キ","ク","ケ","コ"],["サ","シ","ス","セ","ソ"],["タ","チ","ツ","テ","ト"],["ナ","ニ","ヌ","ネ","ノ"],["ハ","ヒ","フ","ヘ","ホ"],["マ","ミ","ム","メ","モ"],["ヤ","　","ユ","　","ヨ"],["ラ","リ","ル","レ","ロ"],["ワ","ヲ","ン","ー","・"],
    ]
    private let dakutenRows: [[String]] = [
        ["ガ","ギ","グ","ゲ","ゴ"],["ザ","ジ","ズ","ゼ","ゾ"],["ダ","ヂ","ヅ","デ","ド"],["バ","ビ","ブ","ベ","ボ"],["パ","ピ","プ","ペ","ポ"],
    ]
    @State private var showDakuten = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                HStack {
                    Text(name.isEmpty ? "タップで入力" : name).font(.system(size: 22, weight: .bold)).foregroundStyle(name.isEmpty ? Color.secondary : Color.white).frame(maxWidth: .infinity, alignment: .leading)
                    Button { if !name.isEmpty { name.removeLast() } } label: { Image(systemName: "delete.left.fill").font(.system(size: 22)).foregroundStyle(.red) }.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16).padding(.top, 8)

                HStack {
                    Button { showDakuten = false } label: { Text("清音").font(.system(size: 13, weight: .bold)).frame(maxWidth: .infinity, minHeight: 40).background(!showDakuten ? Color.yellow : Color(white: 0.15)).foregroundStyle(!showDakuten ? .black : .white).clipShape(RoundedRectangle(cornerRadius: 8)) }
                    Button { showDakuten = true } label: { Text("濁音・半濁音").font(.system(size: 13, weight: .bold)).frame(maxWidth: .infinity, minHeight: 40).background(showDakuten ? Color.yellow : Color(white: 0.15)).foregroundStyle(showDakuten ? .black : .white).clipShape(RoundedRectangle(cornerRadius: 8)) }
                }
                .padding(.horizontal, 16)

                ScrollView {
                    let rows = showDakuten ? dakutenRows : kanaRows
                    VStack(spacing: 4) {
                        ForEach(rows.indices, id: \.self) { rowIdx in
                            HStack(spacing: 4) {
                                ForEach(rows[rowIdx].indices, id: \.self) { colIdx in
                                    let ch = rows[rowIdx][colIdx]
                                    if ch == "　" { Color.clear.frame(width: 56, height: 48) }
                                    else {
                                        Button { name.append(ch) } label: { Text(ch).font(.system(size: 20, weight: .semibold)).frame(width: 56, height: 48).background(Color(white: 0.15)).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 8)) }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                Button { name.append(" ") } label: { Text("スペース").font(.system(size: 14, weight: .medium)).frame(maxWidth: .infinity, minHeight: 44).background(Color(white: 0.15)).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 8)) }.padding(.horizontal, 16).padding(.bottom, 8)
            }
            .background(Color.black)
            .navigationTitle("名前入力").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("クリア") { name = "" }.foregroundStyle(.red) }
                ToolbarItem(placement: .confirmationAction) { Button("完了") { dismiss() }.foregroundStyle(.yellow) }
            }
        }
    }
}
