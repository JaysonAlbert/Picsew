# Native iOS App

This directory is the target home for the fully native Picsew iOS product.

## Current status

- Native iOS development now starts here in staged phases.
- The existing root-level `ios/` directory is still the current Capacitor-based shell and should be treated as transitional reference infrastructure during migration.
- Phase 2 adds compileable Swift packages for algorithm, media, and design system boundaries.

## Planned layout

```text
apps/ios-native/
  PicsewApp/
    App/
    Features/
    Core/
    Resources/
    Support/
  PicsewAppTests/
  Packages/
    PicsewAlgorithm/
    PicsewMedia/
    PicsewDesignSystem/
```

## Rules

- Product and UI evolution for iOS should target this directory going forward.
- Algorithm behavior must stay logically aligned with the TypeScript reference implementation until an intentional replacement is approved.
- Native code should prefer explicit module boundaries over a single flat Xcode target.

## Local validation

You can validate the starter native modules with:

```bash
cd apps/ios-native/Packages/PicsewAlgorithm && swift test
cd apps/ios-native/Packages/PicsewMedia && swift test
cd apps/ios-native/Packages/PicsewDesignSystem && swift test
```
