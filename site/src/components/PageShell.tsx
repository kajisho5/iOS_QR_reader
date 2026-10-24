import type { NavKey } from "@/content/site";
import { SiteFooter } from "./SiteFooter";
import { SiteHeader } from "./SiteHeader";

export function PageShell({ active, children }: { active: NavKey; children: React.ReactNode }) {
  return (
    <>
      <a href="#main" className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-20 focus:rounded-lg focus:bg-surface focus:px-4 focus:py-2">
        本文へ移動
      </a>
      <SiteHeader active={active} />
      <main id="main">{children}</main>
      <SiteFooter />
    </>
  );
}
