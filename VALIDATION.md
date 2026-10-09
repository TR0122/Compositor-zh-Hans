# Simplified Chinese build validation

Base: official `v1.4.7`, commit `675d8a4479de53c582c70ac3b7a46766f1fc7d1a`.

- Compiled the Swift and C application code with Apple Swift 6.4 and the macOS 26.5 SDK, targeting arm64 and macOS 26.0, with release optimization.
- Verified the generated and installed app bundles with `codesign --verify --deep --strict`. Local ad hoc signing retains App Sandbox and user-selected file read/write entitlements.
- Validated the Chinese string table and Xcode project with `plutil`.
- Compared all 127 groups of explicitly declared string enum raw values with the official source: unchanged.
- Ran the independent integration runner: **84 checks passed**. Checks cover Chinese resource lookup and dynamic filter names, every blend mode's translated title and Codable round trip, Chinese layer naming, undo/redo, the native blend picker selecting the correct persisted value, project save/reopen with Chinese names, stable English format identifiers, PNG dimensions and pixels, retained Cmd-N, and Chinese command search.
- Opened the built app and visually verified the Chinese menu bar, initial canvas form, tool descriptions, transform toolbar, layer panel, and status bar. The interface rendered correctly with an image on the canvas.
- Adapted 78 upstream unit-test text expectations to localized labels and updated the overflow and real-menu checks. Parsed the unit-test Swift sources successfully.

To reproduce the independent integration checks after building:

```sh
python3 scripts/build-localized.py
python3 scripts/verify-localization.py
```

The full Xcode unit/UI test suite was not run: this machine has Command Line Tools rather than the full Xcode application. The independent checks above are a focused smoke suite, not a claim that every editor feature has been exercised.

This is a local MIT-licensed derivative build. It is not signed or notarized by the upstream developer. Upstream automatic updating was removed to preserve the translations.
