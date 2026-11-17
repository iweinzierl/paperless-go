# Paperless Go

Paperless Go is a Flutter mobile client for [paperless-ngx](https://github.com/paperless-ngx/paperless-ngx). It connects directly to your self-hosted paperless-ngx instance so you can browse, search, scan, upload, and manage documents from iPhone, iPad, and Android devices.

## Highlights

- Connect to a paperless-ngx server with your base URL and either your username and password or an API token.
- Browse recent uploads, review documents, and the full document library.
- Search documents and filter by tags, correspondents, and document types.
- Open documents, inspect metadata, and perform supported document actions.
- Scan paper documents on-device and upload them to your server.
- Protect app access with biometric or device-credential unlocking.
- Use the app in English, German, French, Italian, or Spanish.
- Benefit from layouts that adapt to phones and larger tablet screens.

## Feature Overview

### Authentication and session handling

The app signs in against your paperless-ngx API and stores the connection details locally on your device so you can reconnect quickly. It includes optional biometric protection for reopening the app after it has been in the background. Accounts with MFA enabled can enter the one-time code from their authenticator app at login, or sign in with an API token instead.

If your server sits behind an authenticating reverse proxy, such as Cloudflare Access (Zero Trust), open "Custom HTTP headers" on the login screen and enter one `Name: value` pair per line, for example the `CF-Access-Client-Id` and `CF-Access-Client-Secret` of a service token. The app stores these headers in the platform secure storage and sends them with every request to your server. Because they are secrets, they are only sent over HTTPS: the login screen does not accept custom headers together with an `http://` server URL. Once saved, the login screen shows only the names of the headers, not their values.

For a server that requires mutual TLS (mTLS), open "Client certificate" on the login screen, choose your PKCS #12 file (`.p12` or `.pfx`) and enter its password. The app stores the certificate in the platform secure storage and presents it on HTTPS connections. You can use custom headers, a client certificate, both, or neither. Both stay on the device when you sign out, so you do not have to enter them again; "Remove" on the login screen deletes them from the device right away.

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

### Automated store screenshots

Android and iOS screenshot lanes can now run against a live demo server instead of the mock screenshot repository.

1. Copy `scripts/screenshot-env.sh.example` to `scripts/screenshot-env.sh`.
2. Set `PAPERLESS_SCREENSHOT_DATA_SOURCE=live` together with `PAPERLESS_SCREENSHOT_SERVER_URL`, `PAPERLESS_SCREENSHOT_USERNAME`, and `PAPERLESS_SCREENSHOT_PASSWORD`.
3. Run `./scripts/android/run_fastlane.sh screenshots` for Play Store screenshots or `./scripts/ios/run_fastlane.sh screenshots` for App Store screenshots.

To re-create only specific screenshots, pass a comma-separated `screenshots:` filter with the stable screenshot file names, for example `./scripts/android/run_fastlane.sh screenshots screenshots:"03-filter-sort,06-settings-screen"`.

The local `scripts/screenshot-env.sh` file is ignored by git and is sourced automatically by both Fastlane wrapper scripts.

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