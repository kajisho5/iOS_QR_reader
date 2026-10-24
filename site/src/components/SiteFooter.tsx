import Link from "next/link";
import { nav, site } from "@/content/site";

export function SiteFooter() {
  return (
    <footer className="mt-12 bg-footer">
      <div className="mx-auto max-w-[1072px] px-4 py-8 md:py-10">
        <nav aria-label="フッター">
          <ul className="flex flex-col gap-1 text-sm md:flex-row md:gap-8">
            {nav.map((item) => (
              <li key={item.key}>
                <Link href={item.href} className="inline-block py-0.5 hover:text-brand">
                  {item.label}
                </Link>
              </li>
            ))}
          </ul>
        </nav>
        <p className="mt-6 text-xs text-sub md:mt-4">
          © {site.year} {site.provider}
        </p>
      </div>
    </footer>
  );
}
