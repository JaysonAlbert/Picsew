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
