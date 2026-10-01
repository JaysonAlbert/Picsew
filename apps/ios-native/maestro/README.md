# Maestro Workspace

This workspace contains the first repository-owned iOS automation flows for the native Picsew app.

## Requirements

- Xcode command line tools
- a booted iOS simulator
- [Maestro CLI](https://docs.maestro.dev/)

## Quick start

From the repository root:

```bash
./scripts/ios-native/install-host-app-on-booted-sim.sh
cd apps/ios-native/maestro
maestro test flows/smoke-preview.yaml
```

To capture all primary shell states:

```bash
./scripts/ios-native/install-host-app-on-booted-sim.sh
cd apps/ios-native/maestro
maestro test .
```

Artifacts are written under `apps/ios-native/maestro/artifacts/`.

## Automation scenarios

The host app understands the `picsewAutomationScenario` launch argument. Current supported values:

- `onboarding`
- `upload`
- `processing`
- `preview`
- `feedback`

These scenarios are fixture-backed and designed for stable screenshots and smoke validation.

## Real Photos import regression

From the repository root, run `npm run ios:test:maestro:photos` with a dedicated
iPhone simulator booted. The runner installs the current app and adds the public
synthetic `fixtures/floating-overlay/white.mp4` to the simulator's Photos library.
The integration flow launches normal app composition, selects the first video in
the real system picker, verifies that processing becomes enabled, then clears
and selects that same video again. It captures fresh screenshots of both imports.

This integration flow is separate from the default fixture-backed workspace so
ordinary screenshot runs do not depend on an unseeded system Photos library. Use
an English iPhone 17 Pro / iOS 26.4 simulator for its current picker grid target.
Do not use a simulator with personal media when capturing these regression
artifacts, and do not seed private recordings into this test.
