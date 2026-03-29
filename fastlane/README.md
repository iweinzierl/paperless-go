fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android check_play_store_setup

```sh
[bundle exec] fastlane android check_play_store_setup
```

Check that Play Store release prerequisites are available

### android metadata

```sh
[bundle exec] fastlane android metadata
```

Upload listing metadata, store images, and screenshots

### android assets

```sh
[bundle exec] fastlane android assets
```

Upload only Play Store images and screenshots

### android binary

```sh
[bundle exec] fastlane android binary
```

Build a release app bundle and upload only the binary to the internal track

### android internal

```sh
[bundle exec] fastlane android internal
```

Build a release app bundle and upload it with metadata/assets to the internal track

### android validate

```sh
[bundle exec] fastlane android validate
```

Validate a Play upload without publishing it

### android generate_screenshots

```sh
[bundle exec] fastlane android generate_screenshots
```

Build screenshot artifacts and capture Play Store screenshots with Screengrab

----


## iOS

### ios check_app_store_setup

```sh
[bundle exec] fastlane ios check_app_store_setup
```

Check that App Store Connect/TestFlight release prerequisites are available

### ios binary

```sh
[bundle exec] fastlane ios binary
```

Build a signed iOS IPA for App Store Connect/TestFlight

### ios internal

```sh
[bundle exec] fastlane ios internal
```

Build a signed iOS IPA and upload it to TestFlight for internal testing

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
