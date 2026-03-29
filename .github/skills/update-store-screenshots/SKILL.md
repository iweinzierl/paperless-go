---
name: update-store-screenshots
description: 'Automates the generation of app screenshots for the Play Store using Fastlane Screengrab.'
---

# Skill: Automated Screenshot Generation for Paperless Go

### Context & Goal
The agent should automate the creation of Android app screenshots using Fastlane Screengrab. The goal is to handle everything in a single run, from creating the test to placing the images in the metadata folder.

### Instructions for the AI Agent:

1.  **Environment Check:**
    * Check whether `fastlane` is installed in the project.
    * Look for the file `fastlane/Screengrabfile`. If it does not exist, create it with default values for the package `com.github.iweinzierl.paperlessgo`.

2.  **UI-Test Engineering (Espresso):**
    * Analyze `MainActivity.kt` and the login layouts.
    * Create or update a UI test at `app/src/androidTest/java/.../ScreenshotTest.kt`.
    * **Important:** The test must call `Screengrab.screenshot("name")` at strategic points such as the login screen, document list, and document details.

3.  **Fastlane Integration:**
    * Create a new lane in the `Fastfile` named `generate_screenshots`.
    * This lane must run `gradle(task: 'assembleDebug assembleAndroidTest')`, followed by the `screengrab` command.

4.  **Execution & Verification:**
    * Run `bundle exec fastlane generate_screenshots` in the terminal.
    * After completion, verify that the images are located in `fastlane/metadata/android/[LOCALE]/images/phoneScreenshots/`.

---

### How to activate this skill now

When you open **Copilot Agent Mode** in VS Code (`Cmd+Alt+I` / `Ctrl+Alt+I`), you can simply say:

> **"Nutze den Skill 'Automated Screenshot Generation'. Analysiere meine App-Struktur, schreibe den nötigen UI-Test für den Login- und Dokumenten-Screen und führe die Fastlane-Lane aus, um die Screenshots für den Play Store zu erzeugen."**

> **"Use the 'Automated Screenshot Generation' skill. Analyze my app structure, write the required UI test for the login and document screens, and run the Fastlane lane to generate the screenshots for the Play Store."**

### A small "pro tip" for Paperless Go:
Since Paperless-ngx requires an API connection, the UI test will fail if no server is reachable. You can also instruct the agent to:
* *"Create a mock server or use test data so the UI test runs without a live server and still produces valid screenshots."*

**Should I also create the matching `Screengrabfile` configuration so the agent has a solid template to start from?**