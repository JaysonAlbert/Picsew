# Capacitor iOS Setup

Last updated: 2026-03-29

Picsew now includes a Capacitor iOS shell with:

- config file: [capacitor.config.ts](/Volumes/data/Projects/Picsew/capacitor.config.ts)
- iOS project: [ios/App/App.xcodeproj](/Volumes/data/Projects/Picsew/ios/App/App.xcodeproj)

Current app id:

- `top.ibotcloud.picsew`

## Phase 1 status

Phase 1 P0 is now wired for these native capabilities:

- native video import from `Photos`
- native video import from `Files`
- native save to `Photos`
- native share sheet using `@capacitor/share`

Current implementation files:

- web/native bridge: [native-media.ts](/Volumes/data/Projects/Picsew/src/lib/native-media.ts)
- iOS photo save plugin: [PicsewMediaPlugin.swift](/Volumes/data/Projects/Picsew/ios/App/App/PicsewMediaPlugin.swift)
- iOS privacy manifest: [PrivacyInfo.xcprivacy](/Volumes/data/Projects/Picsew/ios/App/App/PrivacyInfo.xcprivacy)
- iOS permission strings: [Info.plist](/Volumes/data/Projects/Picsew/ios/App/App/Info.plist)

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

1. Run `npm run cap:sync:ios`
2. Build the iOS target in Xcode or with `xcodebuild`
3. Verify:
   - Photos import reaches the upload flow
   - Files import reaches the upload flow
   - generated screenshots save into Photos
   - share sheet opens from preview
   - feedback dialog still submits from inside the WebView
4. Add app icons and launch screen assets in Xcode
5. Add an iOS-specific support/about page if needed

## Notes

- Capacitor copies the built web app from `build/` into `ios/App/App/public`
- Any frontend change should be followed by `npm run cap:sync:ios`
- Current feedback submission is already wired to Supabase via `VITE_FEEDBACK_ENDPOINT`
- `@capacitor/filesystem` requires an iOS privacy manifest. The current manifest uses the recommended `C617.1` file timestamp reason from the Capacitor docs.
