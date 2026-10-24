"use client";

import { useEffect } from "react";

/** Marks the table-of-contents link of the section being read (desktop). Without JS the TOC still works as plain links. */
export function TocHighlighter({ ids }: { ids: string[] }) {
  useEffect(() => {
    const links = new Map(ids.map((id) => [id, document.querySelector<HTMLAnchorElement>(`[data-toc-link="${id}"]`)]));
    const setActive = (active: string) => {
      for (const [id, link] of links) {
        if (id === active) link?.setAttribute("data-active", "");
        else link?.removeAttribute("data-active");
      }
    };
    const visible = new Set<string>();
    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) visible.add(entry.target.id);
          else visible.delete(entry.target.id);
        }
        const first = ids.find((id) => visible.has(id));
        if (first) setActive(first);
      },
      { rootMargin: "-80px 0px -55% 0px" },
    );
    for (const id of ids) {
      const section = document.getElementById(id);
      if (section) observer.observe(section);
    }
    setActive(ids[0]);
    return () => observer.disconnect();
  }, [ids]);
  return null;
}
