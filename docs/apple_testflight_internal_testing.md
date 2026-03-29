# Apple TestFlight Internal Testing

This project now includes Fastlane-based tooling for iOS uploads to App Store Connect and TestFlight internal testing.

## What You Can Manage

- Validate that App Store Connect API credentials are available
- Build a signed iOS IPA for App Store Connect
- Upload a new build to TestFlight for internal testing

## Files And Directories

### Fastlane configuration

- `fastlane/Appfile`
- `fastlane/Fastfile`

### Optional App Store Connect API key file

- `fastlane/app-store-connect-api-key.p8`

### Optional App Store Connect API key metadata file

- `fastlane/app-store-connect-api-key.json`

### Helper script

- `scripts/ios/run_fastlane.sh`

### App Store listing inputs

- `fastlane/Snapfile`
- `fastlane/screenshots/ios/`
- `fastlane/metadata/ios/`

### Optional TestFlight changelog files

- `fastlane/metadata/ios/changelogs/default.txt`
- `fastlane/metadata/ios/changelogs/<build-number>.txt`

## One-Time Setup

### 1. Create an App Store Connect API key

In App Store Connect:

1. Open Users and Access.
2. Open the Integrations tab.
3. Create an API key with access to the app.
4. Download the `.p8` key file.

Export these environment variables before using the iOS lanes:

- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`

Or store them in:

- `fastlane/app-store-connect-api-key.json`

Then provide the private key using one of these options:

- Store it at `fastlane/app-store-connect-api-key.p8`
- Or set `key_filepath` inside `fastlane/app-store-connect-api-key.json`
- Or set `APP_STORE_CONNECT_API_KEY_PATH=/absolute/path/to/AuthKey.p8`
- Or set `APP_STORE_CONNECT_API_KEY_CONTENT` to the raw key content
- Or set `APP_STORE_CONNECT_API_KEY_BASE64` to the base64-encoded key content

Example JSON config:

```json
{
	"key_id": "ABC123XYZ",
	"issuer_id": "00000000-1111-2222-3333-444444444444",
	"key_filepath": "app-store-connect-api-key.p8"
}
```

### 2. Ensure local iOS signing is ready

The iOS project is configured for automatic signing.

Before the first upload, verify in Xcode that:

- the `Runner` target signs with the correct Apple Developer account
- the bundle identifier is correct
- the required App Store distribution certificate and provisioning profile can be resolved

Current defaults in this repo:

- iOS bundle identifier: `dev.iweinzierl.paperlessNgxApp`
- Apple Developer team id: `4NW6U8AW48`

You can override these when needed with:

- `IOS_APP_IDENTIFIER`
- `APPLE_DEVELOPER_TEAM_ID`
- `APP_STORE_CONNECT_TEAM_ID`

### 3. Install Fastlane

Run:

```bash
gem install --user-install fastlane
```

If you use Bundler in your local setup, the helper script will automatically prefer `bundle exec fastlane` when a `Gemfile` is present.

## Common Commands

All commands are run from the project root.

### Validate App Store Connect setup

```bash
./scripts/ios/run_fastlane.sh check_app_store_setup
```

### Build a signed IPA locally

```bash
./scripts/ios/run_fastlane.sh binary
```

### Build and upload a new TestFlight build for internal testing

```bash
./scripts/ios/run_fastlane.sh internal
```

### Capture App Store screenshots

```bash
./scripts/ios/run_fastlane.sh screenshots
```

This lane uses `snapshot` and writes screenshots to `fastlane/screenshots/ios`.
The current project still needs a dedicated iOS UI test target plus `SnapshotHelper.swift` before screenshot capture will run successfully.

### Upload App Store metadata and screenshots

```bash
./scripts/ios/run_fastlane.sh metadata
```

This lane uploads App Store listing metadata and screenshots without uploading a new binary.

If a changelog file exists, the lane uses it automatically.

- `fastlane/metadata/ios/changelogs/19.txt` for build `19`
- otherwise `fastlane/metadata/ios/changelogs/default.txt`

## Build And Upload Options

You can override build metadata when needed:

```bash
./scripts/ios/run_fastlane.sh internal build_name:1.0.5 build_number:19
```

You can also upload an already built IPA without rebuilding:

```bash
./scripts/ios/run_fastlane.sh internal ipa:build/ios/ipa/Runner.ipa
```

Useful optional Fastlane parameters:

- `changelog:Your release notes`
- `changelog_path:fastlane/metadata/ios/changelogs/19.txt`
- `groups:["Internal QA"]`
- `skip_waiting_for_build_processing:false`
- `devices:["iPhone 16 Pro"]`
- `languages:["en-US"]`
- `skip_metadata:true`
- `skip_screenshots:true`

## Notes

- The iOS lane uploads to TestFlight for internal testing. It does not submit the app for App Store review.
- `fastlane ios metadata` uses `deliver` with `skip_binary_upload:true`, so it only updates listing content.
- `fastlane ios screenshots` is ready to call `snapshot`, but it will intentionally stop with a clear error until the repo has an iOS UI-test screenshot flow.
- The build step uses `flutter build ipa --release --export-method app-store`.
- Flutter version metadata comes from `pubspec.yaml` unless you override `build_name` or `build_number`.
- Inline `changelog:` still works, but file-based changelogs are preferred for repeatable releases.