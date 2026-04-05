import SwiftUI
import StoreKit

struct ProUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var storeManager = StoreManager()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.yellow)

                        Text("DUGOUT Pro")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)

                        Text("すべての機能をアンロック")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)

                    // Pro Features
                    VStack(alignment: .leading, spacing: 16) {
                        proFeatureRow(icon: "person.3.fill", title: "選手登録 無制限", description: "チーム全員の能力値を管理")
                        proFeatureRow(icon: "chart.bar.fill", title: "全13戦術を分析", description: "すべての攻撃戦術のおすすめ度を表示")
                        proFeatureRow(icon: "doc.text.fill", title: "試合レポート自動生成", description: "ミーティング用の詳細レポート")
                        proFeatureRow(icon: "arrow.triangle.2.circlepath", title: "能力値の自動更新", description: "実績データから能力値を自動計算")
                        proFeatureRow(icon: "globe", title: "多言語対応", description: "日本語・英語・韓国語・スペイン語・中国語")
                    }
                    .padding(20)
                    .background(Color(white: 0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 16)

                    // Price buttons
                    if storeManager.isLoading {
                        ProgressView()
                            .padding(40)
                    } else if storeManager.products.isEmpty {
                        // Fallback when products aren't loaded yet
                        VStack(spacing: 12) {
                            pricePlaceholder(
                                title: "月額プラン",
                                price: "¥480 / 月",
                                note: "いつでもキャンセル可能",
                                highlight: false
                            )
                            pricePlaceholder(
                                title: "年額プラン（おすすめ）",
                                price: "¥3,800 / 年",
                                note: "月額より34%お得",
                                highlight: true
                            )
                        }
                        .padding(.horizontal, 16)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(storeManager.products) { product in
                                Button {
                                    Task {
                                        let success = await storeManager.purchase(product)
                                        if success { dismiss() }
                                    }
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(product.displayName)
                                                .font(.system(size: 16, weight: .bold))
                                            Text(product.description)
                                                .font(.system(size: 12))
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(product.displayPrice)
                                            .font(.system(size: 18, weight: .bold))
                                    }
                                    .padding(16)
                                    .background(product.id == StoreManager.proYearlyID ? Color.yellow : Color(white: 0.12))
                                    .foregroundStyle(product.id == StoreManager.proYearlyID ? .black : .white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Restore
                    Button {
                        Task { await storeManager.restorePurchases() }
                    } label: {
                        Text("購入を復元")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }

                    if let error = storeManager.errorMessage {
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 16)
                    }

                    Spacer().frame(height: 20)
                }
            }
            .background(Color.black)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
            .task {
                await storeManager.loadProducts()
            }
        }
    }

    private func proFeatureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.yellow)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func pricePlaceholder(title: String, price: String, note: String, highlight: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                Text(note)
                    .font(.system(size: 12))
                    .foregroundStyle(highlight ? .black.opacity(0.6) : .secondary)
            }
            Spacer()
            Text(price)
                .font(.system(size: 18, weight: .bold))
        }
        .padding(16)
        .background(highlight ? Color.yellow : Color(white: 0.12))
        .foregroundStyle(highlight ? .black : .white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
