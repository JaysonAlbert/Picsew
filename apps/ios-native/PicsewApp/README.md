# PicsewApp Module Layout

This folder reserves the structure for the native app target.

- `App/`: App entry, app wiring, navigation composition
- `Features/`: upload, processing, preview, feedback, onboarding
- `Core/`: shared app services that are not algorithm packages
- `Resources/`: app assets, localized strings, design tokens
- `Support/`: app-specific support files and build helpers

These directories are intentionally empty in phase 1 so the migration can start without disrupting the current shipping web and Capacitor paths.
