import SwiftUI

struct StrategyGuideView: View {
    @State private var selectedCategory = 0

    private let categories = ["仕組み", "攻撃", "走塁", "分析"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category picker
                Picker("", selection: $selectedCategory) {
                    ForEach(categories.indices, id: \.self) { i in
                        Text(categories[i]).tag(i)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                ScrollView {
                    VStack(spacing: 12) {
                        switch selectedCategory {
                        case 0: howItWorks
                        case 1: offenseStrategies
                        case 2: baserunningStrategies
                        case 3: analyticsGuide
                        default: EmptyView()
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 20)
                }
            }
            .background(Color.black)
            .navigationTitle("戦略辞典")
        }
    }

    // MARK: - Offense Strategies
    // MARK: - How It Works
    private var howItWorks: some View {
        VStack(spacing: 12) {
            guideCard(
                title: "おすすめ度の仕組み",
                subtitle: "なぜこの%が表示されるのか",
                risk: "",
                riskColor: .clear,
                stats: [
                    "各作戦の「おすすめ度」は合計100%で表示されます。",
                    "これはその場面で各作戦がどれだけ有効かを示す指標です。",
                    "",
                    "例: バッティング 45% / 盗塁 20% / バント 10% ...",
                    "→ この場面ではバッティングが最も有効という意味です。",
                ],
                when: "これは「成功率」ではありません。「この場面でどの作戦を選ぶべきか」の比率です。バッティング45%は「45%の確率で成功する」という意味ではなく、「この場面ではバッティングを選ぶのが最も賢明」という意味です。",
                source: "DUGOUT独自のアルゴリズム"
            )

            guideCard(
                title: "計算に使われる要素",
                subtitle: "7つの要素で判断",
                risk: "",
                riskColor: .clear,
                stats: [
                    "1. 打者の能力値（打力・走力・バント技術など）",
                    "   → 能力が高い選手ほど、その能力を活かす作戦が上がる",
                    "",
                    "2. ボール・ストライクのカウント",
                    "   → 3-0なら四球狙い↑、0-2ならバッティングで粘る",
                    "",
                    "3. ランナーの位置",
                    "   → 1塁なら盗塁可能、3塁ならスクイズが選択肢に",
                    "",
                    "4. アウトカウント",
                    "   → 0アウトならバントも選択肢、2アウトはバッティング一択",
                    "",
                    "5. イニング（序盤/中盤/終盤）",
                    "   → 終盤の接戦では代打・スクイズの価値が上がる",
                    "",
                    "6. 点差",
                    "   → 大量ビハインドではバントせずバッティング一択",
                    "",
                    "7. 盗塁の損益分岐点",
                    "   → 選手の盗塁成功率が分岐点を超えているかどうか",
                ],
                when: "これらの要素を組み合わせて、各作戦にスコアをつけます。スコアを合計100%に変換したものが、画面に表示される「おすすめ度」です。",
                source: "MLB 2021-2024 / NPB研究データ / FanGraphs"
            )

            guideCard(
                title: "バッティングが常に高い理由",
                subtitle: "データが示す真実",
                risk: "",
                riskColor: .clear,
                stats: [
                    "MLBの実データでは、ほとんどの場面で",
                    "「普通に打つ」が最も期待得点が高い作戦です。",
                    "",
                    "NPB研究（2006年、3,994ケース）:",
                    "  ヒットエンドラン: 0.95点/回",
                    "  普通に打つ:       0.86点/回",
                    "  バント:           0.73点/回",
                    "",
                    "バントは期待得点を0.10〜0.19点下げることが多く、",
                    "「アウトを1つ犠牲にする価値」が証明されていません。",
                    "",
                    "ただし以下の場面ではバントの価値が上がります:",
                    "  ・終盤の接戦（1点差以内）",
                    "  ・弱い打者が打席にいる時",
                    "  ・アマチュア野球（プロほど不利にならない）",
                ],
                when: "バッティングのおすすめ度が40〜60%と高いのは「バグ」ではなく、データに基づいた正しい推奨です。他の作戦が特定の条件を満たした時にだけ、バッティング以外のおすすめ度が上がります。",
                source: "FanGraphs RE24 / NPB 2006研究 / J-STAGE"
            )

            guideCard(
                title: "スコアの計算例",
                subtitle: "具体的なシナリオ",
                risk: "",
                riskColor: .clear,
                stats: [
                    "【場面】3回表 0アウト 1塁 カウント1-1 平均的な打者",
                    "",
                    "バッティング:  50点（基本）+ 5点（打力3）= 55点",
                    "盗塁:         15点（走力4、成功率>分岐点）",
                    "エンドラン:    12点（打力3、カウント普通）",
                    "バスター:      10点（打力3 + ランナーあり）",
                    "バント:         8点（RE低下小 + ランナーあり）",
                    "その他:        各2〜5点",
                    "",
                    "合計: 約107点 → 100%に変換",
                    "バッティング: 55/107 = 51%",
                    "盗塁:        15/107 = 14%",
                    "エンドラン:   12/107 = 11%",
                    "...",
                    "",
                    "【場面】7回裏 1アウト 3塁 カウント0-0 1点差",
                    "",
                    "バッティング:  55点",
                    "スクイズ:      25点（1アウト + 終盤接戦 + 3塁）★大幅UP",
                    "エンドラン:    12点",
                    "...",
                    "→ スクイズが18%まで上昇（通常は3%以下）",
                ],
                when: "このように、特定の条件が揃った時だけ、バッティング以外の作戦のスコアが大きく上がります。闇雲にバントや盗塁を選ぶのではなく、データが「この場面なら有効」と示す時だけ推奨します。",
                source: "DUGOUT計算エンジン"
            )

            guideCard(
                title: "能力値が未設定の場合",
                subtitle: "0 = 平均として扱う",
                risk: "",
                riskColor: .clear,
                stats: [
                    "選手の能力値が0（未設定）の場合:",
                    "→ 自動的に「3」（5段階の平均）として計算されます。",
                    "",
                    "これは「能力がわからない選手は平均的な選手」",
                    "として扱うという意味です。",
                    "",
                    "能力値を正しく設定すると、その選手に合った",
                    "作戦推奨が表示されます。",
                    "例: 走力5の選手 → 盗塁のおすすめ度が大幅UP",
                    "例: 打力1の選手 → 代打のおすすめ度がUP（終盤）",
                ],
                when: "より正確な推奨を得るために、選手の能力値はできるだけ正確に設定してください。試合を重ねて実際の打率・盗塁成功率が蓄積されると、推奨はさらに正確になります。",
                source: "DUGOUT設計方針"
            )
        }
    }

    // MARK: - Offense Strategies
    private var offenseStrategies: some View {
        VStack(spacing: 12) {
            guideCard(
                title: "バッティング",
                subtitle: "基本の攻撃",
                risk: "中",
                riskColor: .orange,
                stats: [
                    "NPB実績: 期待得点 0.86点/回",
                    "カウント別 打率:",
                    "  3-0: .544 / 3-1: .476 / 2-0: .434",
                    "  0-2: .203 / 1-2: .228 / 2-2: .273",
                ],
                when: "基本的にどの場面でも使える。追い込まれた時は粘り、打者有利カウントでは積極的に振る。大量ビハインドの終盤では強打が唯一の選択肢。",
                source: "FanGraphs 2015-2024 / NPB 2006研究"
            )

            guideCard(
                title: "送りバント",
                subtitle: "犠打でランナーを進める",
                risk: "低",
                riskColor: .green,
                stats: [
                    "MLB実データ (2021-2024):",
                    "  1塁0アウト → 2塁1アウト: 得点期待 -0.19点",
                    "  1・2塁0アウト → 2・3塁1アウト: -0.10点",
                    "  2塁0アウト → 3塁1アウト: -0.16点",
                    "",
                    "アマチュア: バント成功率 約80%",
                    "アマチュア: バント後の得点率はバントなしとほぼ同じ",
                    "（差はわずか+1.6%）",
                ],
                when: "データ上はほとんどの場面で得点期待を下げる。ただし終盤の接戦で1点が欲しい場面、弱い打者の時は勝率を上げる可能性がある。アマチュアではプロほど不利にならない。",
                source: "FanGraphs RE24 / Baseball Reference"
            )

            guideCard(
                title: "セーフティバント",
                subtitle: "バントで自分も生きる",
                risk: "中",
                riskColor: .orange,
                stats: [
                    "アマチュア: バント成功率 約80%",
                    "セーフティは通常のバントより成功率が低い",
                    "足が速い選手 + バント技術が必要",
                ],
                when: "相手守備がバントシフトを敷いていない時、足が速くバント技術のある打者。出塁しながらランナーも進められる一石二鳥の作戦。",
                source: "日本アマチュア野球研究"
            )

            guideCard(
                title: "バスター",
                subtitle: "バント構え → ヒッティング",
                risk: "中",
                riskColor: .orange,
                stats: [
                    "日本の高校・大学野球で頻繁に使用",
                    "相手がバントシフトの時に効果的",
                    "打者にコンタクト力が必要",
                ],
                when: "相手がバントを予想して前進守備を敷いた時。バント構えで守備を引きつけ、空いたスペースに打つ。当てる力のある打者向き。",
                source: "NPBデータ / 日本アマチュア野球研究"
            )

            guideCard(
                title: "スクイズ",
                subtitle: "3塁ランナーをバントで生還させる",
                risk: "高",
                riskColor: .red,
                stats: [
                    "MLB: 成功チームは52-78%の成功率",
                    "ドジャース(2024): 78.6%成功率",
                    "1アウト最適: 損益分岐点 70%",
                    "0アウト: 損益分岐点 87%（他の方法でも点が入る）",
                    "成功時: 勝率+42%向上の可能性",
                ],
                when: "3塁ランナーがいて1アウトの接戦が最適。成功すれば確実に1点。失敗すると3塁ランナーがアウトになる壊滅的な結果。バント精度が全て。",
                source: "FanGraphs / MLB.com 2024"
            )

            guideCard(
                title: "タッチアップ（犠牲フライ）",
                subtitle: "外野フライでランナーを生還させる",
                risk: "低",
                riskColor: .green,
                stats: [
                    "MLB: 3塁からのタッチアップ成功率 90%以上",
                    "パワーのある打者ほど深い外野フライを打てる",
                    "アウトでも1点入る（犠牲フライ）",
                ],
                when: "3塁にランナーがいて2アウト未満。パワーのある打者が外野フライを狙う。アウトになっても1点が入る生産的なプレー。",
                source: "MLB Statcast"
            )

            guideCard(
                title: "進塁打",
                subtitle: "右方向に打ってランナーを進める",
                risk: "低",
                riskColor: .green,
                stats: [
                    "NPBでは公式スタッツとして記録",
                    "日本野球の基本戦術",
                    "2塁→3塁に進めることで犠飛で得点可能に",
                ],
                when: "2塁にランナー、0アウト。右方向にゴロを打って、自分はアウトでもランナーを3塁に進める。日本野球の基本であり、チームバッティングの象徴。",
                source: "NPB公式 / 日本野球戦術研究"
            )
        }
    }

    // MARK: - Baserunning Strategies
    private var baserunningStrategies: some View {
        VStack(spacing: 12) {
            guideCard(
                title: "盗塁",
                subtitle: "走者が次の塁を奪う",
                risk: "中",
                riskColor: .orange,
                stats: [
                    "盗塁の損益分岐点（成功率が必要な最低ライン）:",
                    "",
                    "【2塁盗塁】",
                    "  0アウト: 71% / 1アウト: 67% / 2アウト: 70%",
                    "",
                    "【3塁盗塁】",
                    "  0アウト: 78% / 1アウト: 69% / 2アウト: 88%",
                    "",
                    "【本塁盗塁（ホームスチール）】",
                    "  0アウト: 87% / 1アウト: 70% / 2アウト: 34%",
                    "",
                    "【ダブルスチール】",
                    "  0アウト: 64% / 1アウト: 60% / 2アウト: 76%",
                    "",
                    "MLB 2023: 平均成功率 80%（ルール変更後過去最高）",
                ],
                when: "走者の盗塁能力が損益分岐点を上回る時に走る。成功すれば得点期待+0.20点、失敗すると-0.45点。投手有利カウントの時に走ると、投手にプレッシャーをかけられる。",
                source: "FanGraphs Stolen Base Break-Even / MLB.com 2023"
            )

            guideCard(
                title: "ヒットエンドラン",
                subtitle: "走者スタート + 打者が必ず打つ",
                risk: "高",
                riskColor: .red,
                stats: [
                    "NPB研究（2006年、3,994ケース）:",
                    "  ヒットエンドラン: 期待得点 0.95点/回",
                    "  普通に打つ: 0.86点/回",
                    "  バント: 0.73点/回",
                    "",
                    "H&Rが最も期待得点が高い",
                    "併殺回避率: 30%向上",
                    "MLB: 平均走者進塁成功率 60%",
                ],
                when: "1塁にランナー、コンタクト力の高い打者（三振しにくい）。打者有利カウントで特に効果的。ただし打者がボール球を空振りすると走者が捕まるリスク。",
                source: "Baseball Prospectus / NPB 2006研究 / J-STAGE"
            )

            guideCard(
                title: "ランエンドヒット",
                subtitle: "走者スタート + 打者は振っても振らなくてもOK",
                risk: "中",
                riskColor: .orange,
                stats: [
                    "ヒットエンドランより安全",
                    "走者が独力で盗塁できる足があれば成功率が高い",
                    "ボール球なら振らなくてOK → 空振りリスクなし",
                    "成功率はほぼ盗塁と同じ（75-80%）",
                ],
                when: "走者が盗塁できる足を持っている時。打者はいい球が来たら打ち、ボール球なら見逃す。ヒットエンドランよりリスクが低い。",
                source: "NPBデータ / 日本アマチュア野球"
            )

            guideCard(
                title: "ディレードスチール",
                subtitle: "投球後にタイミングをずらして走る",
                risk: "中",
                riskColor: .orange,
                stats: [
                    "投球時ではなく、捕手→投手の返球時にスタート",
                    "アマチュア野球で特に効果的",
                    "相手の油断を突くサプライズ戦術",
                ],
                when: "キャッチャーの返球が遅い時、中盤以降で守備が緩んでいる時。通常の盗塁と違い、ピッチャーのクイックモーションに関係なく成功できる。試合序盤にスカウティングしてから使うと効果的。",
                source: "日本アマチュア野球研究"
            )

            guideCard(
                title: "一三塁プレー",
                subtitle: "1塁走者が走り、3塁走者がホームを狙う",
                risk: "高",
                riskColor: .red,
                stats: [
                    "高校野球の定番トリックプレー",
                    "複数のバリエーション:",
                    "  (a) 1塁→盗塁、送球間に3塁→本塁",
                    "  (b) 1塁走者がわざと挟まれ、その間に3塁→本塁",
                    "  (c) 1塁走者が早めにスタート → ボーク誘い",
                ],
                when: "1塁と3塁にランナーがいる時。接戦の終盤で1点が欲しい場面。相手バッテリーが2塁に投げる癖があれば成功率が上がる。2アウトではリスクが高すぎる。",
                source: "日本野球戦術研究"
            )

            guideCard(
                title: "代打",
                subtitle: "打力の高い控え選手に交代",
                risk: "低",
                riskColor: .green,
                stats: [
                    "投打の左右相性（プラトーンスプリット）:",
                    "  左打者 vs 右投手: OPS +115ポイント有利",
                    "  右打者 vs 左投手: OPS +69ポイント有利",
                    "",
                    "注意: 代打は準備なしで打席に入るため",
                    "通常より打率が20-30ポイント下がる傾向",
                    "→ プラトーン有利がそれを上回る時に使う",
                ],
                when: "終盤の接戦で弱い打者が打席に入る時。投手と逆の手の打者を出して有利を取る。早い回での代打は通常推奨されない。",
                source: "FanGraphs Splits Library"
            )

            guideCard(
                title: "代走",
                subtitle: "足の速い選手に走者を交代",
                risk: "低",
                riskColor: .green,
                stats: [
                    "足の遅いランナー → 足の速い選手に交代",
                    "盗塁やエンドランの選択肢が増える",
                    "1塁からでもシングルで一気にホームを狙える",
                ],
                when: "終盤の接戦で塁上に足の遅い選手がいる時。盗塁や次の打席でのエンドランなど、走塁戦術の選択肢を広げるために使う。",
                source: "NPB / MLB戦術論"
            )
        }
    }

    // MARK: - Analytics Guide
    private var analyticsGuide: some View {
        VStack(spacing: 12) {
            guideCard(
                title: "得点期待（Run Expectancy）",
                subtitle: "この場面であと何点入りそうか",
                risk: "",
                riskColor: .clear,
                stats: [
                    "MLB 2021-2024 平均:",
                    "",
                    "ランナーなし:",
                    "  0アウト: 0.50点 / 1アウト: 0.27点 / 2アウト: 0.10点",
                    "",
                    "1塁:",
                    "  0アウト: 0.90点 / 1アウト: 0.54点 / 2アウト: 0.23点",
                    "",
                    "2塁:",
                    "  0アウト: 1.14点 / 1アウト: 0.71点 / 2アウト: 0.33点",
                    "",
                    "1・2塁:",
                    "  0アウト: 1.51点 / 1アウト: 0.94点 / 2アウト: 0.46点",
                    "",
                    "満塁:",
                    "  0アウト: 2.38点 / 1アウト: 1.63点 / 2アウト: 0.82点",
                ],
                when: "すべての作戦判断の基礎データ。バントやスチールで得点期待がどう変わるかを比較して、正しい作戦を選ぶために使う。",
                source: "FanGraphs RE24 / MLB 2021-2024"
            )

            guideCard(
                title: "カウント有利度",
                subtitle: "ボール・ストライクの影響",
                risk: "",
                riskColor: .clear,
                stats: [
                    "カウント別の打者の強さ（平均=100%）:",
                    "",
                    "打者有利:",
                    "  3-0: 173% / 3-1: 147% / 2-0: 135%",
                    "  1-0: 113% / 2-1: 113% / 3-2: 117%",
                    "",
                    "投手有利:",
                    "  0-2: 63% / 1-2: 70% / 2-2: 85%",
                    "  0-1: 84%",
                    "",
                    "互角:",
                    "  0-0: 100% / 1-1: 94%",
                ],
                when: "カウントは個人の打力よりも結果に大きく影響する。エリート打者の0-2カウントは、平均以下の打者の3-1カウントより結果が悪い。カウントに合わせた作戦選択が重要。",
                source: "FanGraphs 'The Count Is King' / SABR研究"
            )

            guideCard(
                title: "プラトーンスプリット",
                subtitle: "投打の左右相性",
                risk: "",
                riskColor: .clear,
                stats: [
                    "対角の投打は有利:",
                    "",
                    "左打者 vs 右投手: OPS +115ポイント / wOBA +28",
                    "右打者 vs 左投手: OPS +69ポイント / wOBA +16",
                    "",
                    "左打者の方がプラトーン差が大きい理由:",
                    "  1. 同側の変化球が逃げていくため打ちにくい",
                    "  2. 左投手と対戦する機会が少ない（経験不足）",
                    "",
                    "大きな影響のある球種: ツーシーム、スライダー",
                    "影響が小さい球種: フォーシーム、チェンジアップ",
                ],
                when: "代打や打順を決める時に活用。投手と逆の手の打者を起用すると有利。ただし個人の打者vs投手の過去データ（少数サンプル）は信頼性が低い — 全体的な傾向を使う方が正確。",
                source: "FanGraphs Splits Library / MLB Statcast"
            )

            guideCard(
                title: "勝率（Win Expectancy）",
                subtitle: "今の時点で勝つ確率",
                risk: "",
                riskColor: .clear,
                stats: [
                    "参考値（MLB実データ）:",
                    "",
                    "9回表、1点リード、2アウト、ランナーなし: 96.6%",
                    "9回裏、同点、1塁、0アウト: 約71%（ホーム）",
                    "9回裏、1点ビハインド、2アウト、ランナーなし: 約4.2%",
                    "7回裏、1点ビハインド、満塁、0アウト: 約68.7%",
                    "",
                    "1点の価値は終盤ほど大きくなる",
                    "7回以降の1点 ≫ 1回の1点",
                ],
                when: "試合の流れを客観的に判断するための指標。「まだ勝てる」「もう厳しい」を数字で把握し、リスクを取るべきかどうかの判断材料にする。",
                source: "TangoTiger WE Tables / Greg Stoll Win Expectancy Finder"
            )
        }
    }

    // MARK: - Guide Card Component
    private func guideCard(
        title: String, subtitle: String,
        risk: String, riskColor: Color,
        stats: [String], when: String, source: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if !risk.isEmpty {
                    Text("リスク: \(risk)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(riskColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(riskColor.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            Divider().background(Color(white: 0.2))

            // Stats
            VStack(alignment: .leading, spacing: 2) {
                Text("データ")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.yellow)
                ForEach(stats, id: \.self) { line in
                    if line.isEmpty {
                        Spacer().frame(height: 4)
                    } else {
                        Text(line)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(line.hasPrefix("  ") ? Color(white: 0.7) : .white)
                    }
                }
            }

            Divider().background(Color(white: 0.2))

            // When to use
            VStack(alignment: .leading, spacing: 2) {
                Text("いつ使うか")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.green)
                Text(when)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            // Source
            Text("出典: \(source)")
                .font(.system(size: 9))
                .foregroundStyle(Color(white: 0.35))
        }
        .padding(14)
        .background(Color(white: 0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
