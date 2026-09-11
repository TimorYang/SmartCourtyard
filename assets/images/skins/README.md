# FLINX skin artwork slots

Final dark and technology artwork has not been supplied. Missing assets render
an explicit localized placeholder; no existing art is recolored or redrawn.
The minimalist skin uses the existing asset paths. Door animation frames,
avatars, and sign-in provider branding remain shared.

`AppSkinAssets` in `lib/app/theme/app_skin_catalog.dart` owns path resolution.
For dark and technology skins, `assets/<kind>/<folder>/<name>.png` maps to
`assets/<kind>/skins/<skin>/<folder>/<name>_placeholder.png`.
Add the approved export at this path (and optional `2.0x` / `3.0x` variants).
Flutter widgets and layout do not need to change.

See `docs/skin_assets.md` for the complete candidate slot inventory and
`docs/app_appearance.md` for implementation and validation details.
