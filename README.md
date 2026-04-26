# Better Brushing

Better Brushing is a calm, kid-friendly tooth-brushing MVP built with Flutter. It turns a two-minute brushing routine into a light character-led experience with a live front-camera preview, simple guidance, and a parent handoff at the end.

## What It Does

- Lets kids choose a brushing buddy before starting.
- Runs a guided two-minute brushing flow across four mouth zones.
- Uses the device front camera as the main play surface.
- Shows playful fox and gator themed overlays and encouragement.
- Supports English and German localization.
- Adds an optional 30-second parent extension after the main session.

## Current Product Scope

This repository is an MVP focused on experience flow, visual tone, and basic camera-backed interaction.

- The brushing session logic is implemented in Flutter.
- The app includes localized UI copy and character-specific presentation.
- Effect assets are included in the repo for future AR work.
- The current in-app experience uses the plain camera preview with themed overlays rather than full face-tracked AR effects.

## Tech Stack

- Flutter
- Dart
- `camera`
- `flutter_localizations`
- `intl`

## Project Structure

```text
lib/
  app.dart
  main.dart
  controllers/
  l10n/
  models/
  screens/
  widgets/
effects/
design_assets/
```

Key areas:

- `lib/screens/character_selection_screen.dart`: character choice entry point
- `lib/screens/camera_game_screen.dart`: camera-backed brushing experience
- `lib/controllers/brushing_session_controller.dart`: timer, zone, and parent-extension logic
- `lib/l10n/`: generated and source localization files
- `effects/`: AR/effect asset experiments for future integration

## Getting Started

### Prerequisites

- Flutter SDK installed
- A device or simulator with camera support
- Xcode for iOS builds
- Android Studio / Android SDK for Android builds

### Install Dependencies

```bash
flutter pub get
```

### Run The App

```bash
flutter run
```

If you want to test on a physical phone, make sure camera permissions are enabled for the app.

## Localization

The app currently ships with:

- English
- German

Localization files live in `lib/l10n/`, with configuration in `l10n.yaml`.

## Notes For Development

- Generated build output is ignored and should not be committed.
- The app is designed as a friendly MVP, so some visual and gameplay elements are intentionally lightweight.
- Camera fallback messaging is included so the brushing flow can still be exercised when preview initialization fails.

## Roadmap Ideas

- Wire in full AR character/effect rendering
- Add progress persistence and rewards
- Track brushing accuracy by zone
- Expand the character roster
- Add audio cues and celebration moments

## Repository Status

This repo is now set up as the working source for the Better Brushing Flutter MVP and is ready for continued iteration on GitHub.
