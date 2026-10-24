import type { Metadata, Viewport } from "next";
import { site } from "@/content/site";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL(site.url),
  title: { default: `${site.appName} — 広告なし・サブスクなしの QR コードリーダー`, template: `%s | ${site.appName}` },
  description: "広告なし、サブスクなし。読み取った内容は端末の外に出ない、iPhone と iPad の QR コード・バーコードリーダーです。",
  applicationName: site.appName,
  icons: { apple: "/apple-touch-icon.png" },
  formatDetection: { telephone: false, email: false, address: false },
};

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#ffffff" },
    { media: "(prefers-color-scheme: dark)", color: "#151b19" },
  ],
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ja">
      <body className="min-h-dvh antialiased">{children}</body>
    </html>
  );
}
