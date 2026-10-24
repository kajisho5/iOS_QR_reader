# App icon

Built with [fresnel](https://github.com/kajisho5/fresnel) (Liquid Glass icon composer).
Two glass groups on the brand gradient: the viewfinder corners in front, the QR mark behind.

| File | |
|---|---|
| `icon.spec.json` | fresnel spec (background, groups, layers) |
| `src/*.svg` | Layer artwork (1024×1024, transparent, no rounded corners) |
| `AppIcon.icon` | Icon Composer–compatible bundle built from the spec |
| `preview.png` | All six appearances (Default / Dark / Clear / Tinted) |

Rebuild and export to the app's asset catalog:

```sh
cd docs/design/icon
npx fresnel-icon@0.2.2 build icon.spec.json -o AppIcon.icon
npx fresnel-icon@0.2.2 validate AppIcon.icon
npx fresnel-icon@0.2.2 render AppIcon.icon --sheet -o preview.png
npx fresnel-icon@0.2.2 export AppIcon.icon -o /tmp/icon --formats appiconset
cp /tmp/icon/AppIcon.appiconset/AppIcon{,-Dark,-Tinted}.png ../../../SeijitsuQR/Resources/Assets.xcassets/AppIcon.appiconset/
```

The app's `Contents.json` lists only the three iOS images (Default, Dark, Tinted); the Mac and watchOS
sizes fresnel also exports are not used by this iOS-only app.
