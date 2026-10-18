---
name: generate-logo
description: Generate an app logo or icon with the Recraft image model. Use when asked to create, design or regenerate a logo or app icon for a willsawyerrrr.dev app.
---

Run `~/willsawyerrrr.dev/platform/main/scripts/generate-logo [--svg] [--out <dir>] <app-name> "<description>"`.

- Write the description as the visual concept (subject, palette, mood), not the app's features.
- Output is a 1024x1024 PNG, or SVG with `--svg`. View the result and regenerate with a refined description until it fits.
- Each generation costs about $0.04 (PNG) or $0.08 (SVG); don't loop blindly.
- Place the final PNG in the app's asset catalog (`AppIcon`) or `public/` as appropriate.
