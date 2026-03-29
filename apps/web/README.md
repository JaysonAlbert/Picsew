# Web App

This directory is the target home for the long-lived Picsew web surface.

## Current status

- The live web app still runs from the repository root in phase 1.
- The root `package.json`, `src/`, `public/`, and `.github/workflows/deploy.yml` remain authoritative for the deployed website.
- No production web code has been moved here yet.

## Why this directory exists now

We are starting a staged repository migration:

1. Keep the current website stable and deployable.
2. Build the native iOS app in parallel.
3. Move the web app into `apps/web/` only after the deploy and test paths are updated.

## Future contents

- React/Vite web source
- Web-specific tests
- Web-specific docs and build config
