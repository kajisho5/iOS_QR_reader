export const site = {
  appName: "誠実QRリーダー",
  provider: "seventhwell",
  // Set the public support address here. The support page shows the contact card only when this is set.
  contactEmail: "info@seventh-well.com" as string,
  priceLabel: "¥800（買い切り）",
  minimumOS: "iOS 17 / iPadOS 17 以降",
  // Set after the App Store release. Until then the hero shows "App Store で近日公開".
  appStoreURL: "" as string,
  url: "https://seijitsuqr.kajisho5.workers.dev",
  year: 2026,
} as const;

export const nav = [
  { href: "/", label: "トップ", key: "top" },
  { href: "/privacy/", label: "プライバシーポリシー", key: "privacy" },
  { href: "/terms/", label: "利用規約", key: "terms" },
  { href: "/support/", label: "サポート", key: "support" },
] as const;

export type NavKey = (typeof nav)[number]["key"];

export const promises = [
  { icon: "ad", title: "広告なし", body: "広告もアクセス解析も入っていません。" },
  { icon: "sub", title: "サブスクなし", body: "Pro は ¥800 の買い切り。定期的な課金はありません。" },
  { icon: "lock", title: "端末の中で完結", body: "読み取り・作成・履歴はすべて端末内。アプリは通信しません。" },
] as const;

export const features = [
  "QRコードとバーコードの読み取り",
  "写真から読み取り",
  "連続スキャン",
  "履歴の検索とお気に入り",
  "QRコードの作成",
  "Wi-Fi への接続・連絡先への追加",
] as const;

export const plans = {
  free: { name: "無料", price: "¥0", body: "読み取り・テキストと URL の作成・履歴 30 件" },
  pro: {
    name: "Pro（買い切り）",
    price: "¥800",
    body: "履歴の無制限保存・全種類の作成・CSV 書き出し",
    note: "一度の購入で、同じ Apple ID の端末で使えます。",
  },
} as const;

export const externalLinks = {
  applePrivacy: "https://www.apple.com/jp/legal/privacy/",
  appleEula: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/",
  reportProblem: "https://reportaproblem.apple.com/",
} as const;
