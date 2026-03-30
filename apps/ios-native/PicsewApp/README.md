# PicsewApp Module Layout

This folder reserves the structure for the native app target.

- `App/`: App entry, app wiring, navigation composition
- `Features/`: upload, processing, preview, feedback, onboarding
- `Core/`: shared app services that are not algorithm packages
- `Resources/`: app assets, localized strings, design tokens
- `Support/`: app-specific support files and build helpers

Phase 2 adds starter files so future native implementation work has stable landing zones before the final Xcode app target is created.

Phase 5 upgrades this folder into a compileable Swift package so the native app shell, route model, and SwiftUI feature views can evolve before the final app bundle target lands.
