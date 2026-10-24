import type { Metadata } from "next";
import { LegalDocument } from "@/components/LegalDocument";
import { PageShell } from "@/components/PageShell";
import { privacy } from "@/content/privacy";

export const metadata: Metadata = { title: privacy.title, description: privacy.description, alternates: { canonical: "/privacy/" } };

export default function Page() {
  return (
    <PageShell active="privacy">
      <LegalDocument doc={privacy} />
    </PageShell>
  );
}
