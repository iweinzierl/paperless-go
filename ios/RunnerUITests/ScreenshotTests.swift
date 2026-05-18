import XCTest

@MainActor
final class ScreenshotTests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testCondensedDocumentsScreen() {
    captureScreenshot(
      named: "01-document-list-condensed",
      scenario: .documentsList,
      authenticated: true
    )
  }

  func testDocumentsDrawerScreen() {
    captureScreenshot(
      named: "02-documents-drawer",
      scenario: .documentsDrawer,
      authenticated: true
    )
  }

  func testDocumentsFiltersScreen() {
    captureScreenshot(
      named: "03-filter-sort",
      scenario: .documentsFilters,
      authenticated: true
    )
  }

  func testDocumentDetailScreen() {
    captureScreenshot(
      named: "04-document-detail",
      scenario: .documentDetail,
      authenticated: true
    )
  }

  func testLoginScreen() {
    captureScreenshot(
      named: "05-login-screen",
      scenario: .login,
      authenticated: false
    )
  }

  func testSettingsScreen() {
    captureScreenshot(
      named: "06-settings-screen",
      scenario: .settings,
      authenticated: true
    )
  }

  func testDocumentMetadataEditScreen() {
    captureScreenshot(
      named: "07-document-metadata-edit",
      scenario: .documentMetadataEdit,
      authenticated: true
    )
  }

  func testDocumentsScreen() {
    captureScreenshot(
      named: "08-document-list",
      scenario: .documents,
      authenticated: true
    )
  }

  private func captureScreenshot(
    named name: String,
    scenario: Scenario,
    authenticated: Bool
  ) {
    let app = XCUIApplication()
    setupSnapshot(app)
    configure(app, scenario: scenario, authenticated: authenticated)
    app.launch()
    configureDeviceOrientation()
    waitForScreenshotHarnessReady(in: app, scenario: scenario)
    NSLog(
      "paperless-screenshot capture name=%@ locale=%@ device=%@",
      name,
      currentScreenshotLocale(),
      currentSimulatorName()
    )
    snapshot(name, waitForLoadingIndicator: false)
    app.terminate()
  }

  private func configure(
    _ app: XCUIApplication,
    scenario: Scenario,
    authenticated: Bool
  ) {
    let environment = ProcessInfo.processInfo.environment
    let launchArguments = screenshotLaunchArguments(for: app)
    let fileConfiguration = screenshotConfigurationFromFile()
    let dataSource = screenshotDataSource(
      environment: environment,
      launchArguments: launchArguments,
      fileConfiguration: fileConfiguration,
      authenticated: authenticated
    )

    app.launchEnvironment["PAPERLESS_SCREENSHOT_MODE"] = "1"
    app.launchEnvironment["PAPERLESS_SCREENSHOT_SCENARIO"] = scenario.preferenceValue
    app.launchEnvironment["PAPERLESS_SCREENSHOT_DATA_SOURCE"] = dataSource
    app.launchEnvironment["PAPERLESS_SCREENSHOT_LANGUAGE"] = appLanguageForCurrentLocale()
    app.launchEnvironment["PAPERLESS_SCREENSHOT_LAYOUT_MODE"] = scenario.layoutMode
    app.launchEnvironment["PAPERLESS_SCREENSHOT_LAST_SUCCESS_AT"] = "2026-03-21T09:30:00.000Z"
    app.launchEnvironment["PAPERLESS_SCREENSHOT_AUTHENTICATED"] = authenticated ? "1" : "0"

    if dataSource == "live" {
      if let serverUrl = screenshotSetting(
        named: "PAPERLESS_SCREENSHOT_SERVER_URL",
        environment: environment,
        launchArguments: launchArguments,
        fileConfiguration: fileConfiguration
      ) {
        app.launchEnvironment["PAPERLESS_SCREENSHOT_SERVER_URL"] = serverUrl
      }
      if let username = screenshotSetting(
        named: "PAPERLESS_SCREENSHOT_USERNAME",
        environment: environment,
        launchArguments: launchArguments,
        fileConfiguration: fileConfiguration
      ) {
        app.launchEnvironment["PAPERLESS_SCREENSHOT_USERNAME"] = username
      }
      if let password = screenshotSetting(
        named: "PAPERLESS_SCREENSHOT_PASSWORD",
        environment: environment,
        launchArguments: launchArguments,
        fileConfiguration: fileConfiguration
      ) {
        app.launchEnvironment["PAPERLESS_SCREENSHOT_PASSWORD"] = password
      }
      if let displayName = screenshotSetting(
        named: "PAPERLESS_SCREENSHOT_DISPLAY_NAME",
        environment: environment,
        launchArguments: launchArguments,
        fileConfiguration: fileConfiguration
      ) {
        app.launchEnvironment["PAPERLESS_SCREENSHOT_DISPLAY_NAME"] = displayName
      }
    }
  }

  private func screenshotDataSource(
    environment: [String: String],
    launchArguments: [String: String],
    fileConfiguration: [String: String],
    authenticated: Bool
  ) -> String {
    let configuredValue = screenshotSetting(
      named: "PAPERLESS_SCREENSHOT_DATA_SOURCE",
      environment: environment,
      launchArguments: launchArguments,
      fileConfiguration: fileConfiguration
    )?.lowercased()

    if configuredValue == "live" || configuredValue == "mock" {
      return configuredValue ?? "mock"
    }

    return authenticated ? "live" : "mock"
  }

  private func screenshotSetting(
    named name: String,
    environment: [String: String],
    launchArguments: [String: String],
    fileConfiguration: [String: String]
  ) -> String? {
    if let value = environment[name]?.trimmingCharacters(in: .whitespacesAndNewlines),
       !value.isEmpty {
      return value
    }

    if let value = fileConfiguration[name]?.trimmingCharacters(in: .whitespacesAndNewlines),
       !value.isEmpty {
      return value
    }

    guard let value = launchArguments[name]?.trimmingCharacters(in: .whitespacesAndNewlines),
          !value.isEmpty else {
      return nil
    }

    return value
  }

  private func screenshotLaunchArguments(for app: XCUIApplication) -> [String: String] {
    let arguments = app.launchArguments
    guard !arguments.isEmpty else {
      return [:]
    }

    var values: [String: String] = [:]
    var index = 0
    while index < arguments.count {
      let argument = arguments[index]
      guard argument.hasPrefix("-PAPERLESS_SCREENSHOT_") else {
        index += 1
        continue
      }

      let key = String(argument.dropFirst())
      let nextIndex = index + 1
      if nextIndex < arguments.count {
        values[key] = arguments[nextIndex]
        index += 2
      } else {
        values[key] = ""
        index += 1
      }
    }

    return values
  }

  private func screenshotConfigurationFromFile() -> [String: String] {
    let repoRoot = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
    let configurationURL = repoRoot
      .appendingPathComponent("fastlane")
      .appendingPathComponent(".generated")
      .appendingPathComponent("ios")
      .appendingPathComponent("screenshot_configuration.json")

    guard
      let data = try? Data(contentsOf: configurationURL),
      let object = try? JSONSerialization.jsonObject(with: data) as? [String: String]
    else {
      return [:]
    }

    return object
  }

  private func appLanguageForCurrentLocale() -> String {
    for identifier in [Snapshot.currentLocale, Snapshot.deviceLanguage] {
      let normalizedIdentifier = identifier
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased()

      if normalizedIdentifier.hasPrefix("de") {
        return "de"
      }
      if normalizedIdentifier.hasPrefix("es") {
        return "es"
      }
      if normalizedIdentifier.hasPrefix("fr") {
        return "fr"
      }
      if normalizedIdentifier.hasPrefix("it") {
        return "it"
      }
      if normalizedIdentifier.hasPrefix("en") {
        return "en"
      }
    }

    return "en"
  }

  private func currentScreenshotLocale() -> String {
    for identifier in [Snapshot.currentLocale, Snapshot.deviceLanguage] {
      let normalizedIdentifier = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
      if !normalizedIdentifier.isEmpty {
        return normalizedIdentifier
      }
    }

    return "unknown-locale"
  }

  private func currentSimulatorName() -> String {
    let deviceName = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "unknown-device"
    return deviceName.replacingOccurrences(
      of: "Clone [0-9]+ of ",
      with: "",
      options: .regularExpression
    )
  }

  private func configureDeviceOrientation() {
    XCUIDevice.shared.orientation = screenshotDeviceOrientation()
  }

  private func screenshotDeviceOrientation() -> UIDeviceOrientation {
    let deviceName = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? ""
    return deviceName.contains("iPad") ? .landscapeLeft : .portrait
  }

  private func waitForScreenshotHarnessReady(in app: XCUIApplication, scenario: Scenario) {
    let readyTimeout: TimeInterval = scenario.requiresPreviewReadyMarker ? 45 : 30
    let readyMarker = app.staticTexts["paperless-screenshot-state-ready"]
    let errorMarker = app.staticTexts.matching(
      NSPredicate(format: "label BEGINSWITH %@", "paperless-screenshot-state-error")
    ).firstMatch

    if errorMarker.waitForExistence(timeout: 1) {
      XCTFail("Screenshot harness entered error state before capture.")
    }

    XCTAssertTrue(
      readyMarker.waitForExistence(timeout: readyTimeout),
      "Timed out waiting for screenshot harness ready state."
    )

    guard scenario.requiresPreviewReadyMarker else {
      return
    }

    let previewReadyMarker = app.staticTexts["paperless-screenshot-document-preview-ready"]
    let previewLoadingMarker = app.staticTexts["paperless-screenshot-document-preview-loading"]

    XCTAssertTrue(
      previewReadyMarker.waitForExistence(timeout: 20),
      "Timed out waiting for document preview readiness."
    )
    XCTAssertFalse(
      previewLoadingMarker.exists,
      "Document preview is still loading at capture time."
    )
  }
}

private enum Scenario {
  case login
  case documents
  case documentsList
  case documentsFilters
  case documentsDrawer
  case documentDetail
  case documentMetadataEdit
  case settings

  var preferenceValue: String {
    switch self {
    case .login:
      return "login"
    case .documents:
      return "documents"
    case .documentsList:
      return "documents_list"
    case .documentsFilters:
      return "documents_filters"
    case .documentsDrawer:
      return "documents_drawer"
    case .documentDetail:
      return "document_detail"
    case .documentMetadataEdit:
      return "document_metadata_edit"
    case .settings:
      return "settings"
    }
  }

  var layoutMode: String {
    switch self {
    case .documentsList:
      return "list"
    default:
      return "card"
    }
  }

  var requiresPreviewReadyMarker: Bool {
    switch self {
    case .documentDetail, .documentMetadataEdit:
      return true
    default:
      return false
    }
  }
}