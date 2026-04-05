import SwiftUI

struct TutorialView: View {
    @Binding var hasSeenTutorial: Bool
    @State private var currentStep = 0

    private let steps: [TutorialStep] = [
        TutorialStep(
            icon: "diamond.fill",
            iconColor: .yellow,
            title: "DUGOUTへようこそ",
            subtitle: "試合中の采配をデータで支援するアプリです",
            items: [
                "セイバーメトリクスに基づいた戦略提案",
                "得点期待値・勝率をリアルタイム表示",
                "全打席・全作戦を自動記録＆分析",
            ],
            tip: "まずは選手を登録するところから始めましょう"
        ),
        TutorialStep(
            icon: "person.badge.plus",
            iconColor: .yellow,
            title: "STEP 1: 選手を登録する",
            subtitle: "「選手」タブから自チームの選手を登録します",
            items: [
                "「＋選手を追加する」をタップ",
                "背番号・名前・ポジションを入力",
                "打率・走力・バント成功率などの能力値を設定",
                "能力値は試合データから自動計算も可能",
            ],
            tip: "💡 能力値が正確なほど、作戦のおすすめ精度が上がります"
        ),
        TutorialStep(
            icon: "person.2.badge.plus",
            iconColor: .red,
            title: "STEP 2: 相手チームを登録する",
            subtitle: "「選手」タブの「相手チーム」から登録します",
            items: [
                "チーム名・投手情報を入力",
                "「1〜9番を一括登録」で素早く登録",
                "選手の特徴タグ（右打・足が速いなど）を設定",
                "投手の特徴（速球派・変化球多など）も記録",
            ],
            tip: "💡 相手情報が充実するほど、守備時の分析も可能になります"
        ),
        TutorialStep(
            icon: "list.number",
            iconColor: .yellow,
            title: "STEP 3: 打順を設定する",
            subtitle: "「打順」タブで自チーム・相手チームの打順を設定",
            items: [
                "1番〜9番に選手をドロップダウンから選択",
                "自チーム・相手チーム両方の打順を設定可能",
                "打順に基づいて試合中に次の打者が自動表示",
            ],
            tip: "💡 打順は試合中にも変更できます"
        ),
        TutorialStep(
            icon: "play.fill",
            iconColor: .yellow,
            title: "STEP 4: 試合を始める",
            subtitle: "「試合」タブから新しい試合を開始します",
            items: [
                "自チーム名・相手チーム・イニング数を設定",
                "「プレイボール」で試合開始！",
                "スコア・アウト・走者・カウントをワンタップで操作",
                "状況に応じた作戦が自動でおすすめ表示される",
            ],
            tip: "💡 走者やカウントが変わるたびにおすすめ度が更新されます"
        ),
        TutorialStep(
            icon: "chart.bar.fill",
            iconColor: .green,
            title: "STEP 5: 作戦を実行＆記録",
            subtitle: "データが蓄積されるほど分析の精度が上がります",
            items: [
                "おすすめ作戦一覧から戦術を選択",
                "「実行」ボタンで作戦を記録",
                "打席結果（ヒット・アウト等）を記録",
                "「分析」タブで選手別・作戦別の成績を確認",
            ],
            tip: "💡 試合後のミーティングでレポートを活用しましょう"
        ),
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                HStack(spacing: 4) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(i <= currentStep ? Color.yellow : Color(white: 0.2))
                            .frame(height: 3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Step indicator
                Text("\(currentStep + 1) / \(steps.count)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)

                // Content
                TabView(selection: $currentStep) {
                    ForEach(steps.indices, id: \.self) { index in
                        stepView(steps[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Bottom buttons
                VStack(spacing: 12) {
                    // Main button
                    Button {
                        if currentStep < steps.count - 1 {
                            withAnimation(.easeInOut(duration: 0.3)) { currentStep += 1 }
                        } else {
                            withAnimation { hasSeenTutorial = true }
                        }
                    } label: {
                        Text(currentStep < steps.count - 1 ? "次へ" : "はじめる")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.yellow)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // Skip button
                    if currentStep < steps.count - 1 {
                        Button {
                            withAnimation { hasSeenTutorial = true }
                        } label: {
                            Text("スキップ")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
    }

    @ViewBuilder
    private func stepView(_ step: TutorialStep) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer().frame(height: 8)

                // Icon
                ZStack {
                    Circle()
                        .fill(step.iconColor.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: step.icon)
                        .font(.system(size: 36))
                        .foregroundStyle(step.iconColor)
                }

                // Title
                Text(step.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(step.subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(white: 0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                // Items
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(step.items.indices, id: \.self) { i in
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(step.iconColor.opacity(0.2))
                                    .frame(width: 28, height: 28)
                                Text("\(i + 1)")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundStyle(step.iconColor)
                            }

                            Text(step.items[i])
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer()
                        }
                    }
                }
                .padding(20)
                .background(Color(white: 0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)

                // Tip
                if !step.tip.isEmpty {
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(step.iconColor)
                            .frame(width: 3)

                        Text(step.tip)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(white: 0.6))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                }

                Spacer().frame(height: 20)
            }
        }
    }
}

// MARK: - Tutorial Step Data
private struct TutorialStep {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let items: [String]
    let tip: String
}
