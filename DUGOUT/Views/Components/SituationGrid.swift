import SwiftUI

struct SituationGrid: View {
    @Bindable var viewModel: GameViewModel
    let players: [Player]
    @State private var showOutReason = false

    private var batter: Player? { viewModel.currentBatter(players: players) }

    private let outReasons = [
        "三振", "見逃し三振", "ゴロアウト", "フライアウト",
        "ライナー", "併殺", "犠打", "犠飛",
        "牽制アウト", "走塁アウト", "タッチアウト",
        "インフィールドフライ", "振り逃げ失敗", "守備妨害"
    ]

    var body: some View {
        VStack(spacing: 4) {
            // MARK: - BSO Count (compact inline)
            HStack(spacing: 6) {
                // B
                compactCount("B", count: viewModel.state.balls, max: 4, color: .green,
                    onPlus: {
                        if viewModel.state.balls >= 3 { fourBallWalk() }
                        else { viewModel.state.balls += 1 }
                    },
                    onMinus: { viewModel.state.balls = max(0, viewModel.state.balls - 1) })

                // S
                compactCount("S", count: viewModel.state.strikes, max: 3, color: .yellow,
                    onPlus: {
                        if viewModel.state.strikes >= 2 { thirdStrikeOut() }
                        else { viewModel.state.strikes += 1 }
                    },
                    onMinus: { viewModel.state.strikes = max(0, viewModel.state.strikes - 1) })

                // O — タップでアウト理由を選択
                compactCount("O", count: viewModel.state.outs, max: 3, color: .red,
                    onPlus: { showOutReason = true },
                    onMinus: { viewModel.state.outs = max(0, viewModel.state.outs - 1) })

                Spacer()

                // Count + advantage
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(viewModel.state.balls)-\(viewModel.state.strikes)")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    Text(viewModel.countAdvantageText)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(viewModel.countLeverage >= 1.1 ? .green : viewModel.countLeverage <= 0.85 ? .red : .secondary)
                }
            }
            .padding(.horizontal, 12)

            // MARK: - Diamond + Batter (compact)
            HStack(spacing: 0) {
                // Diamond
                ZStack {
                    let s: CGFloat = 120
                    let cx = s / 2
                    let top = CGPoint(x: cx, y: 10)
                    let right = CGPoint(x: s - 10, y: cx)
                    let left = CGPoint(x: 10, y: cx)
                    let bottom = CGPoint(x: cx, y: s - 10)

                    Path { p in
                        p.move(to: bottom); p.addLine(to: right)
                        p.addLine(to: top); p.addLine(to: left); p.closeSubpath()
                    }
                    .fill(Color(red: 0.1, green: 0.2, blue: 0.1).opacity(0.3))

                    Path { p in
                        p.move(to: bottom); p.addLine(to: right)
                        p.addLine(to: top); p.addLine(to: left); p.closeSubpath()
                    }
                    .stroke(Color(white: 0.3), lineWidth: 1.5)

                    baseMarker(filled: viewModel.state.bases[1], at: top)
                        .onTapGesture { viewModel.tapBase(2) }
                    baseMarker(filled: viewModel.state.bases[0], at: right)
                        .onTapGesture { viewModel.tapBase(1) }
                    baseMarker(filled: viewModel.state.bases[2], at: left)
                        .onTapGesture { viewModel.tapBase(3) }

                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 10, height: 10)
                        .rotationEffect(.degrees(45))
                        .position(bottom)
                }
                .frame(width: 120, height: 130)

                // Batter + runners info
                VStack(alignment: .leading, spacing: 4) {
                    if let b = batter {
                        Text("#\(b.number) \(b.name)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    Text("走者: \(viewModel.runnersText)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.yellow)

                    // Last action log
                    if let lastAction = viewModel.lastActionLog {
                        Text(lastAction)
                            .font(.system(size: 11))
                            .foregroundStyle(.green)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 6)
        .background(Color(white: 0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 8)
        .sheet(isPresented: $showOutReason) {
            outReasonSheet
                .presentationDetents([.medium])
                .preferredColorScheme(.dark)
        }
    }

    // MARK: - Out Reason Sheet
    private var outReasonSheet: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(outReasons, id: \.self) { reason in
                        Button {
                            let outsAdded = reason == "併殺" ? 2 : 1
                            viewModel.state.outs = min(3, viewModel.state.outs + outsAdded)
                            viewModel.lastActionLog = "\(reason) → \(viewModel.state.outs)アウト"
                            // 守備時は投手の投球回数を加算
                            if !viewModel.isOurOffense {
                                viewModel.recordPitcherOut(count: outsAdded)
                                viewModel.addPitch()
                            }
                            showOutReason = false
                            viewModel.state.resetCount()
                            viewModel.advanceBatter()
                            viewModel.checkInningChange()
                        } label: {
                            Text(reason)
                                .font(.system(size: 14, weight: .semibold))
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(Color(white: 0.12))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.black)
            .navigationTitle("アウトの理由")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { showOutReason = false }
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Auto actions
    private func fourBallWalk() {
        if viewModel.state.bases[0] && viewModel.state.bases[1] && viewModel.state.bases[2] {
            if viewModel.isOurOffense { viewModel.state.myScore += 1 }
            else { viewModel.state.oppScore += 1 }
        }
        if viewModel.state.bases[0] && viewModel.state.bases[1] { viewModel.state.bases[2] = true }
        if viewModel.state.bases[0] { viewModel.state.bases[1] = true }
        viewModel.state.bases[0] = true
        viewModel.lastActionLog = "四球 → ランナー1塁"
        viewModel.state.resetCount()
        viewModel.advanceBatter()
    }

    private func thirdStrikeOut() {
        viewModel.state.outs = min(3, viewModel.state.outs + 1)
        viewModel.lastActionLog = "三振 → \(viewModel.state.outs)アウト"
        viewModel.state.resetCount()
        viewModel.advanceBatter()
        viewModel.checkInningChange()
    }

    // MARK: - Base marker
    private func baseMarker(filled: Bool, at point: CGPoint) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(filled ? Color.yellow : Color(white: 0.2))
            .frame(width: 20, height: 20)
            .rotationEffect(.degrees(45))
            .shadow(color: filled ? .yellow.opacity(0.4) : .clear, radius: 4)
            .position(point)
    }

    // MARK: - Compact count button
    private func compactCount(_ label: String, count: Int, max: Int, color: Color, onPlus: @escaping () -> Void, onMinus: @escaping () -> Void) -> some View {
        HStack(spacing: 3) {
            Button(action: onMinus) {
                Text("−")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 32, height: 32)
                    .background(count > 0 ? Color(white: 0.15) : Color(white: 0.06))
                    .foregroundStyle(count > 0 ? .white : Color(white: 0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            VStack(spacing: 0) {
                Text(label)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(color)
                Text("\(count)")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(count > 0 ? color : Color(white: 0.3))
            }
            .frame(width: 24)

            Button(action: onPlus) {
                Text("＋")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 32, height: 32)
                    .background(count < max ? color.opacity(0.25) : Color(white: 0.06))
                    .foregroundStyle(count < max ? .white : Color(white: 0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }
}
