# Design source

The SVG mockups in `docs/design/` are generated from these scripts.
All text is converted to outlines (Noto Sans JP / Noto Sans Mono via `@fontsource`),
so the SVGs render identically in every viewer regardless of installed fonts.
Text widths are measured from the font, so labels, pills and icon+label pairs stay aligned.

```sh
cd docs/design/src
npm ci
npm run build
```

Note: the real app uses the iOS system font (SF Pro + Hiragino Sans), so glyph shapes differ
slightly from these mockups; layout and sizes are the reference.
