import XCTest

@MainActor
final class ScreenshotTests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testLoginScreen() {
    captureScreenshot(
      named: "01-login-screen",
      scenario: .login,
      authenticated: false
    )
  }

  func testDocumentsScreen() {
    captureScreenshot(
      named: "02-document-list",
      scenario: .documents,
      authenticated: true
    )
  }

  func testCondensedDocumentsScreen() {
    captureScreenshot(
      named: "03-document-list-condensed",
      scenario: .documentsList,
      authenticated: true
    )
  }

  func testDocumentsFiltersScreen() {
    captureScreenshot(
      named: "04-filter-sort",
      scenario: .documentsFilters,
      authenticated: true
    )
  }

  func testDocumentDetailScreen() {
    captureScreenshot(
      named: "05-document-detail",
      scenario: .documentDetail,
      authenticated: true
    )
  }

  func testDocumentMetadataEditScreen() {
    captureScreenshot(
      named: "06-document-metadata-edit",
      scenario: .documentMetadataEdit,
      authenticated: true
    )
  }

  func testDocumentsDrawerScreen() {
    captureScreenshot(
      named: "07-documents-drawer",
      scenario: .documentsDrawer,
      authenticated: true
    )
  }

  func testSettingsScreen() {
    captureScreenshot(
      named: "08-settings-screen",
      scenario: .settings,
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
    waitForFlutterToSettle()
    snapshot(name, waitForLoadingIndicator: false)
    app.terminate()
  }

  private func configure(
    _ app: XCUIApplication,
    scenario: Scenario,
    authenticated: Bool
  ) {
    app.launchEnvironment["PAPERLESS_SCREENSHOT_MODE"] = "1"
    app.launchEnvironment["PAPERLESS_SCREENSHOT_SCENARIO"] = scenario.preferenceValue
    app.launchEnvironment["PAPERLESS_SCREENSHOT_LANGUAGE"] = appLanguageForCurrentLocale()
    app.launchEnvironment["PAPERLESS_SCREENSHOT_LAYOUT_MODE"] = scenario.layoutMode
    app.launchEnvironment["PAPERLESS_SCREENSHOT_LAST_SUCCESS_AT"] = "2026-03-21T09:30:00.000Z"
    app.launchEnvironment["PAPERLESS_SCREENSHOT_AUTHENTICATED"] = authenticated ? "1" : "0"
  }

  private func appLanguageForCurrentLocale() -> String {
    let identifier = Snapshot.deviceLanguage.lowercased()
    if identifier.hasPrefix("de") {
      return "de"
    }
    if identifier.hasPrefix("es") {
      return "es"
    }
    if identifier.hasPrefix("fr") {
      return "fr"
    }
    if identifier.hasPrefix("it") {
      return "it"
    }
    return "en"
  }

  private func waitForFlutterToSettle() {
    sleep(2)
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
}