import Link from "next/link";
import { nav, site, type NavKey } from "@/content/site";

export function SiteHeader({ active }: { active: NavKey }) {
  return (
    <header className="sticky top-0 z-10 border-b border-line bg-surface/95 backdrop-blur">
      <div className="mx-auto flex h-14 max-w-[1072px] items-center justify-between px-4 md:h-16">
        <Link href="/" className="flex items-center gap-2.5 font-bold">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/app-icon.png" alt="" width={32} height={32} className="size-7 md:size-8" />
          <span className="text-base md:text-lg">{site.appName}</span>
        </Link>
        <nav aria-label="サイト内">
          <ul className="hidden items-center gap-8 md:flex">
            {nav.map((item) => (
              <li key={item.key}>
                <Link
                  href={item.href}
                  aria-current={item.key === active ? "page" : undefined}
                  className={`relative block py-5 text-[15px] ${
                    item.key === active
                      ? "font-bold text-brand after:absolute after:inset-x-0 after:bottom-0 after:h-0.5 after:bg-brand"
                      : "font-medium hover:text-brand"
                  }`}
                >
                  {item.label}
                </Link>
              </li>
            ))}
          </ul>
          <Link
            href="/support/"
            aria-current={active === "support" ? "page" : undefined}
            className={`text-sm text-brand md:hidden ${active === "support" ? "font-bold" : "font-medium"}`}
          >
            サポート
          </Link>
        </nav>
      </div>
    </header>
  );
}
