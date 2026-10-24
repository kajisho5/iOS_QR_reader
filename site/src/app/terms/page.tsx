import type { Metadata } from "next";
import { LegalDocument } from "@/components/LegalDocument";
import { PageShell } from "@/components/PageShell";
import { terms } from "@/content/terms";

export const metadata: Metadata = { title: terms.title, description: terms.description, alternates: { canonical: "/terms/" } };

export default function Page() {
  return (
    <PageShell active="terms">
      <LegalDocument doc={terms} />
    </PageShell>
  );
}
