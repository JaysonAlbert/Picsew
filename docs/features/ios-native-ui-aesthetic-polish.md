---
title: Native iOS UI Aesthetic Polish
issue: ios-native-ui-aesthetic-polish
author: Jayson Albert
date: 2026-03-30
updated: 2026-03-30
version: 0.2.0
reviewers: [Jayson Albert]
tags: [ios, native, swiftui, ui, design]
source_code:
  - apps/ios-native/Packages/PicsewDesignSystem/Sources/PicsewDesignSystem/PicsewDesignSystem.swift
  - apps/ios-native/PicsewApp/Core/PicsewAppShell.swift
  - apps/ios-native/PicsewApp/Features/Upload/UploadFeature.swift
  - apps/ios-native/PicsewApp/Features/Processing/ProcessingFeature.swift
  - apps/ios-native/PicsewApp/Features/Preview/PreviewFeature.swift
  - apps/ios-native/PicsewApp/Features/Onboarding/OnboardingFeature.swift
status: approved
---

# Native iOS UI Aesthetic Polish

## Summary

- **Problem**: The native iOS app already has the right flow, but the visual finish still reads closer to a functional prototype than a polished utility product.
- **Goal**: Improve perceived quality by unifying the shell, stage surfaces, and action areas into one calmer, more intentional SwiftUI visual language.
- **Scope**:
  - strengthen the shared shell background and top utility bar
  - introduce reusable native surface and action styles in the design system
  - improve the visual hierarchy of upload, processing, preview, and onboarding
  - tighten the vertical rhythm so the main stage remains visible above floating actions on compact iPhone screens
  - reduce generic bordered-button styling in favor of more product-specific action treatments
  - keep the current route structure, copy intent, and pipeline behavior intact

## Problem

### Current issues

1. The shell chrome, stage cards, and bottom action trays do not yet feel like one design system.
2. Upload and preview still rely on plain stacked sections rather than one visually dominant stage with supporting detail.
3. Processing is structurally correct, but the central progress moment lacks enough visual character to feel premium.
4. Onboarding is functionally clear, yet its hero area and step presentation are still too plain for a first-run experience.
5. Repeated material backgrounds and generic bordered buttons make the app feel flatter than intended.
6. On compact screens, the shell chrome plus bottom tray can crowd the main stage, especially in preview where the stitched image should remain the focal point.

### Out of scope

- algorithm or pipeline logic changes
- new routes or navigation patterns
- backend or feedback submission work
- release metadata, signing, or packaging updates

## Design Choice

### ADR-001: Keep the existing route model and improve aesthetics through shared primitives

**Status**: Accepted

**Decision**:

- Preserve the current upload -> processing -> preview route structure.
- Add richer shared shell primitives in `PicsewDesignSystem` and `PicsewAppShell`.
- Restyle feature screens primarily through composition rather than route-level redesign.

**Why**:

- The flow itself is already small and clear.
- Shared primitives reduce the chance that each screen drifts into a different visual language.
- This keeps the change set focused enough to validate in one delivery.

## Visual Direction

### Look and feel

- modern iOS utility app rather than landing-page branding
- soft atmospheric background instead of a flat gradient
- stronger sense of depth in the main stage card
- calmer, more tactile action bars near the thumb zone
- compact but recognizable brand treatment in the top shell

### Screen structure rules

- one dominant stage surface per primary route
- one supporting metadata group when needed, never multiple equal-weight helper cards
- one clear primary action zone anchored near the bottom safe area
- secondary information should use softer chips, captions, or compact rows instead of full cards
- compact shell chrome should support the screen rather than becoming a second hero
- bottom trays should feel floating and tactile without visually blocking the primary stage

## Acceptance Criteria

- [ ] AC-01: [P0] Upload, processing, preview, and onboarding share one clearly recognizable visual system.
  - **Given**: the native iOS app is opened on an iPhone simulator
  - **When**: the user moves across the four main screens
  - **Then**: shell chrome, background treatment, stage surfaces, and action areas feel consistent rather than route-specific
- [ ] AC-02: [P0] Upload and preview each present one visually dominant main stage and a more polished bottom action tray.
  - **Given**: the user is on the upload or preview route
  - **When**: the screen is displayed
  - **Then**: the content hierarchy emphasizes one main focal surface and one anchored action zone
- [ ] AC-03: [P0] Processing has a more premium central progress presentation without adding extra workflow complexity.
  - **Given**: the user starts processing
  - **When**: the processing route is shown
  - **Then**: the current progress state is clearer and visually stronger than the baseline implementation
- [ ] AC-04: [P1] The design-system layer exposes reusable surface styling that is covered by automated tests or existing package validation.
- [ ] AC-05: [P1] Compact iPhone screenshots show the main stage and bottom action zone coexisting without the shell or tray overwhelming the route.

## Planned Tests

- `swift test --package-path apps/ios-native/Packages/PicsewDesignSystem`
- `swift test --package-path apps/ios-native/PicsewApp`
- `xcodebuild -project apps/ios-native/HostApp/PicsewNativeApp.xcodeproj -scheme PicsewNativeApp -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `npm run ios:harness:smoke`
- `maestro test apps/ios-native/maestro/flows/capture-upload.yaml`
- `maestro test apps/ios-native/maestro/flows/capture-processing.yaml`
- `maestro test apps/ios-native/maestro/flows/capture-preview.yaml`
- `maestro test apps/ios-native/maestro/flows/capture-onboarding.yaml`

## Risks

- Visual polish can become subjective and endless, so this pass must stay focused on shared primitives and hierarchy rather than unlimited tweaking.
- Richer backgrounds and layered materials can look better but may also make spacing bugs more obvious if applied inconsistently.
- UI-first changes have limited automated coverage, so validation still relies partly on simulator build confidence and existing automation scaffolds.

## Rollback

The change is a SwiftUI styling and composition pass. Reverting the updated design-system tokens and route views returns the app to the previous baseline without affecting data flow or native pipeline behavior.
