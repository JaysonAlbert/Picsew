# Capacitor iOS Setup

Last updated: 2026-03-29

Picsew now includes a Capacitor iOS shell with:

- config file: [capacitor.config.ts](/Volumes/data/Projects/Picsew/capacitor.config.ts)
- iOS project: [ios/App/App.xcodeproj](/Volumes/data/Projects/Picsew/ios/App/App.xcodeproj)

Current app id:

- `top.ibotcloud.picsew`

## Common commands

Sync web assets and native config:

```bash
npm run cap:sync
```

Sync iOS only:

```bash
npm run cap:sync:ios
```

Open the Xcode project:

```bash
npm run cap:open:ios
```

## Recommended next iOS tasks

1. Add app icons and launch screen assets in Xcode
2. Decide whether the first iOS build will use only the current web UI or also add native plugins immediately
3. Add Capacitor plugins for:
   - Photos / Files import
   - Save to Photos
   - Native share sheet
4. Verify the feedback form works inside the WebView
5. Add an iOS-specific support/about page if needed

## Notes

- Capacitor copies the built web app from `build/` into `ios/App/App/public`
- Any frontend change should be followed by `npm run cap:sync:ios`
- Current feedback submission is already wired to Supabase via `VITE_FEEDBACK_ENDPOINT`
