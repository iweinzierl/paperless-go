# iOS App Store Metadata

Fastlane `deliver` reads App Store listing files from this directory.

Add locale folders such as `en-US/` and provide the metadata files App Store Connect expects there, for example:

- `name.txt`
- `subtitle.txt`
- `description.txt`
- `keywords.txt`
- `release_notes.txt`
- `promotional_text.txt`
- `support_url.txt`
- `marketing_url.txt`
- `privacy_url.txt`

`fastlane ios screenshots` stores generated screenshots under locale-specific folders in this directory, for example `fastlane/metadata/ios/en-US/images/phoneScreenshots/`.

`fastlane ios metadata` uploads the files from this directory together with the generated screenshots.