# Google Play Internal Testing

This project includes Fastlane-based tooling for Google Play internal testing.

## What You Can Manage

- Store listing text metadata
- Store listing images
- Phone and tablet screenshots
- Android App Bundle uploads to the `internal` track
- Metadata-only or assets-only updates without uploading a new binary

## Files And Directories

### Fastlane configuration

- `fastlane/Appfile`
- `fastlane/Fastfile`

### Editable metadata

- `fastlane/metadata/android/en-US/title.txt`
- `fastlane/metadata/android/en-US/short_description.txt`
- `fastlane/metadata/android/en-US/full_description.txt`
- `fastlane/metadata/android/en-US/changelogs/default.txt`

### Android app name

- `android/app/src/main/res/values/strings.xml`

### Images and screenshots

- `fastlane/metadata/android/en-US/images/icon.png`
- `fastlane/metadata/android/en-US/images/featureGraphic.png`
- `fastlane/metadata/android/en-US/images/phoneScreenshots/`
- `fastlane/metadata/android/en-US/images/sevenInchScreenshots/`
- `fastlane/metadata/android/en-US/images/tenInchScreenshots/`

Use `.png` or `.jpg` files in the screenshot directories. Name them in upload order, for example:

- `01-login.png`
- `02-home.png`
- `03-document-details.png`

## One-Time Setup

### 1. Prepare an Android upload key

Create a keystore and save the credentials in:

- `android/key.properties`

Use the template in:

- `android/key.properties.example`

You can generate an upload keystore with:

```bash
./scripts/android/generate_upload_keystore.sh
```

The Android release build reads signing values from either `android/key.properties` or these environment variables:

- `ANDROID_STORE_FILE`
- `ANDROID_STORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

### 2. Create a Google Play service account

In Google Play Console / Google Cloud:

1. Create a service account for the Play Developer API.
2. Grant it access to the app in Play Console.
3. Download the JSON key.

Store the file at:

- `fastlane/play-store-service-account.json`

Or point Fastlane to a different path with:

- `SUPPLY_JSON_KEY=/absolute/path/to/key.json`

### 3. Install Fastlane

Run:

```bash
gem install --user-install bundler:2.4.22
bundle install
```

If your shell cannot find the user-installed Bundler executable afterwards, add the Ruby user gem bin directory to your shell path. On the default macOS system Ruby this is commonly:

```bash
export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH"
```

## Common Commands

All commands are run from the project root.

### Upload metadata, images, and screenshots only

```bash
./scripts/android/run_fastlane.sh metadata
```

### Upload only images and screenshots

```bash
./scripts/android/run_fastlane.sh assets
```

### Build and upload a new Android App Bundle to internal testing

```bash
./scripts/android/run_fastlane.sh internal
```

### Build and upload only the bundle to internal testing

```bash
./scripts/android/run_fastlane.sh binary
```

### Build a signed Android App Bundle locally

```bash
./scripts/android/build_signed_aab.sh
```

### Validate the upload without publishing it

```bash
./scripts/android/run_fastlane.sh validate
```

## Track And Release Options

You can override the track or release status when needed:

```bash
./scripts/android/run_fastlane.sh internal track:internal release_status:draft
```

Supported `release_status` values typically include:

- `draft`
- `completed`
- `inProgress`
- `halted`

For internal testing, `draft` is a safe default while you are verifying the setup.

## First Release Checklist

Before the first Play Console upload, review these values:

- Android application id in `android/app/build.gradle.kts`
- App title in `fastlane/metadata/android/en-US/title.txt`
- App descriptions in the metadata files
- App icon and feature graphic
- Screenshots for the main flows
- `version` in `pubspec.yaml`

## Notes

- The current Android application id is `com.github.iweinzierl.paperlessgo`.
- The current Android display name is controlled by `android/app/src/main/res/values/strings.xml`.
- The current release build falls back to the debug signing key only when no release signing configuration is present. That fallback is useful for local release builds, but Play uploads should always use your upload keystore.