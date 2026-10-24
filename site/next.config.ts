import type { NextConfig } from "next";

// Fully static export: every page is prerendered HTML in out/ (served by Cloudflare Workers static assets).
const config: NextConfig = {
  output: "export",
  trailingSlash: true,
  images: { unoptimized: true },
  poweredByHeader: false,
};

export default config;
