import type { Metadata } from "next";
import { PageShell } from "@/components/PageShell";
import { ContactCard, FaqList } from "@/components/Support";

export const metadata: Metadata = {
  title: "サポート",
  description: "誠実QRリーダーのよくある質問とお問い合わせ先です。",
  alternates: { canonical: "/support/" },
};

export default function SupportPage() {
  return (
    <PageShell active="support">
      <div className="mx-auto max-w-[712px] px-4 pt-10 md:pt-16">
        <h1 className="text-[26px] font-extrabold leading-snug md:text-[34px]">サポート</h1>
        <ContactCard />
        <FaqList />
      </div>
    </PageShell>
  );
}
