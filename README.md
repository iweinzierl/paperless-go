# Paperless Go

Paperless Go is a Flutter mobile client for [paperless-ngx](https://github.com/paperless-ngx/paperless-ngx). It connects directly to your self-hosted paperless-ngx instance so you can browse, search, scan, upload, and manage documents from iPhone, iPad, and Android devices.

## Highlights

- Connect to a paperless-ngx server with your base URL, username, and password.
- Browse recent uploads, review documents, and the full document library.
- Search documents and filter by tags, correspondents, and document types.
- Open documents, inspect metadata, and perform supported document actions.
- Scan paper documents on-device and upload them to your server.
- Protect app access with biometric or device-credential unlocking.
- Use the app in English, German, French, Italian, or Spanish.
- Benefit from layouts that adapt to phones and larger tablet screens.

## Feature Overview

### Authentication and session handling

The app signs in against your paperless-ngx API and stores the connection details locally on your device so you can reconnect quickly. It includes optional biometric protection for reopening the app after it has been in the background.

### Document library

Paperless Go provides dedicated views for recent items, review items, and the main document library. Documents can be shown in list or card-based layouts depending on the screen size and view settings.

### Search, filters, and sorting

The document library supports text search, sorting, and server-backed filters. You can narrow results using paperless metadata such as tags, correspondents, and document types.

### Document actions

The app supports opening documents, viewing details, and running supported follow-up actions such as metadata edits, renaming, sharing, and deletion where the authenticated account has permission.

### Scanning and upload

Paper documents can be scanned directly in the app, converted into a PDF on-device, and uploaded to the connected paperless-ngx server.

### Settings and personalization

Users can configure server connection details, language behavior, theme mode, caching preferences, and app lock behavior from the settings screen.

## Platform Support

- Android
- iOS
- Compact and large-screen layouts for phones and tablets

## Quick Start

### For users

1. Install the app build for your platform.
2. Open the app and enter your paperless-ngx server URL.
3. Sign in with the same account you use for paperless-ngx.
4. Start browsing, searching, or scanning documents.

### For local development

Prerequisites:

- Flutter SDK compatible with Dart `^3.9.2`
- A reachable paperless-ngx server for manual testing
- Xcode for iOS builds or Android Studio / Android SDK for Android builds

Common commands:

```bash
flutter pub get
flutter run
flutter test
dart run build_runner build --delete-conflicting-outputs
```

## Tech Stack

- Flutter for the shared mobile UI
- Riverpod for application state management
- Retrofit and Dio for API communication
- Shared Preferences for local settings and credentials
- Hive for local caching

## Release and Store Documentation

Repository docs for release workflows and store operations:

- [Google Play internal testing](docs/google_play_internal_testing.md)
- [Apple TestFlight internal testing](docs/apple_testflight_internal_testing.md)
- [Privacy policy](PRIVACY.md)

## Support

- Documentation and user help: https://github.com/iweinzierl/paperless-go/wiki
- Issue tracker: https://github.com/iweinzierl/paperless-go/issues

## Versioning

The current app version is defined in [pubspec.yaml](pubspec.yaml).