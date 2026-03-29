# iOS App Store Screenshots

`fastlane ios screenshots` writes captured App Store screenshots here.

The lane is configured to use Fastlane `snapshot`, but the project still needs:

- an iOS UI test target
- screenshot test cases that drive the app to the required screens
- `SnapshotHelper.swift` in the UI test target

Once that setup exists, the screenshots generated here can be uploaded with `fastlane ios metadata`.