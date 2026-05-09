import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {
  private let channelName = "com.github.iweinzierl.paperlessgo/open_document"
  private let eventsChannelName = "com.github.iweinzierl.paperlessgo/open_document/events"
  private var pendingInitialPdfPath: String?
  private var eventSink: FlutterEventSink?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    applyScreenshotLaunchConfigurationIfNeeded()
    GeneratedPluginRegistrant.register(with: self)
    if let flutterViewController = window?.rootViewController as? FlutterViewController {
      let methodChannel = FlutterMethodChannel(
        name: channelName,
        binaryMessenger: flutterViewController.binaryMessenger
      )
      methodChannel.setMethodCallHandler { [weak self] call, result in
        guard let self else {
          result(nil)
          return
        }

        switch call.method {
        case "consumeInitialPdfPath":
          result(self.pendingInitialPdfPath)
          self.pendingInitialPdfPath = nil
        default:
          result(FlutterMethodNotImplemented)
        }
      }

      let eventChannel = FlutterEventChannel(
        name: eventsChannelName,
        binaryMessenger: flutterViewController.binaryMessenger
      )
      eventChannel.setStreamHandler(self)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func applyScreenshotLaunchConfigurationIfNeeded() {
    let environment = ProcessInfo.processInfo.environment
    let launchArguments = screenshotLaunchArguments()
    guard environment["PAPERLESS_SCREENSHOT_MODE"] == "1" else {
      return
    }

    let authenticated = environment["PAPERLESS_SCREENSHOT_AUTHENTICATED"] == "1"
    let dataSource = screenshotDataSource(
      environment: environment,
      launchArguments: launchArguments,
      authenticated: authenticated
    )

    let defaults = UserDefaults.standard
    let managedKeys = [
      "flutter.debug.screenshot_scenario",
      "flutter.debug.screenshot_data_source",
      "flutter.debug.screenshot_state",
      "flutter.debug.screenshot_server_url",
      "flutter.debug.screenshot_username",
      "flutter.debug.screenshot_password",
      "flutter.debug.screenshot_display_name",
      "flutter.app_behavior.app_language",
      "flutter.sync.documents.last_success_at",
      "flutter.documents.layout_mode",
      "flutter.auth.server_url",
      "flutter.auth.username",
      "flutter.auth.password",
      "flutter.auth.token",
      "flutter.auth.display_name",
    ]
    managedKeys.forEach { defaults.removeObject(forKey: $0) }

    if let scenario = environment["PAPERLESS_SCREENSHOT_SCENARIO"], !scenario.isEmpty {
      defaults.set(scenario, forKey: "flutter.debug.screenshot_scenario")
    }
    defaults.set(dataSource, forKey: "flutter.debug.screenshot_data_source")
    defaults.set("loading", forKey: "flutter.debug.screenshot_state")
    if let language = environment["PAPERLESS_SCREENSHOT_LANGUAGE"], !language.isEmpty {
      defaults.set(language, forKey: "flutter.app_behavior.app_language")
    }

    defaults.set(
      environment["PAPERLESS_SCREENSHOT_LAST_SUCCESS_AT"] ?? "2026-03-21T09:30:00.000Z",
      forKey: "flutter.sync.documents.last_success_at"
    )
    defaults.set(
      environment["PAPERLESS_SCREENSHOT_LAYOUT_MODE"] ?? "card",
      forKey: "flutter.documents.layout_mode"
    )

    if authenticated {
      switch dataSource {
      case "live":
        let serverUrl = screenshotSetting(
          named: "PAPERLESS_SCREENSHOT_SERVER_URL",
          environment: environment,
          launchArguments: launchArguments
        ) ?? ""
        let username = screenshotSetting(
          named: "PAPERLESS_SCREENSHOT_USERNAME",
          environment: environment,
          launchArguments: launchArguments
        ) ?? ""
        let password = screenshotSetting(
          named: "PAPERLESS_SCREENSHOT_PASSWORD",
          environment: environment,
          launchArguments: launchArguments
        ) ?? ""
        let displayName = screenshotSetting(
          named: "PAPERLESS_SCREENSHOT_DISPLAY_NAME",
          environment: environment,
          launchArguments: launchArguments
        )

        defaults.set(serverUrl, forKey: "flutter.debug.screenshot_server_url")
        defaults.set(username, forKey: "flutter.debug.screenshot_username")
        defaults.set(password, forKey: "flutter.debug.screenshot_password")
        defaults.set(
          serverUrl,
          forKey: "flutter.auth.server_url"
        )
        defaults.set(
          username,
          forKey: "flutter.auth.username"
        )
        defaults.set(
          password,
          forKey: "flutter.auth.password"
        )
        defaults.removeObject(forKey: "flutter.auth.token")

        if let displayName {
          defaults.set(displayName, forKey: "flutter.debug.screenshot_display_name")
          defaults.set(displayName, forKey: "flutter.auth.display_name")
        } else {
          defaults.removeObject(forKey: "flutter.debug.screenshot_display_name")
          defaults.removeObject(forKey: "flutter.auth.display_name")
        }

      default:
        defaults.set("https://demo.paperless-ngx.local/", forKey: "flutter.auth.server_url")
        defaults.set("demo.user", forKey: "flutter.auth.username")
        defaults.set("not-used", forKey: "flutter.auth.password")
        defaults.set("demo-token", forKey: "flutter.auth.token")
        defaults.set("Demo User", forKey: "flutter.auth.display_name")
      }
    }
  }

  private func screenshotDataSource(
    environment: [String: String],
    launchArguments: [String: String],
    authenticated: Bool
  ) -> String {
    let configuredValue = screenshotSetting(
      named: "PAPERLESS_SCREENSHOT_DATA_SOURCE",
      environment: environment,
      launchArguments: launchArguments
    )?.lowercased()

    if configuredValue == "live" || configuredValue == "mock" {
      return configuredValue ?? "mock"
    }

    return authenticated ? "live" : "mock"
  }

  private func screenshotSetting(
    named name: String,
    environment: [String: String],
    launchArguments: [String: String]
  ) -> String? {
    if let environmentValue = environment[name]?.trimmingCharacters(in: .whitespacesAndNewlines),
       !environmentValue.isEmpty {
      return environmentValue
    }

    guard let launchArgumentValue = launchArguments[name]?.trimmingCharacters(in: .whitespacesAndNewlines),
          !launchArgumentValue.isEmpty else {
      return nil
    }

    return launchArgumentValue
  }

  private func screenshotLaunchArguments() -> [String: String] {
    let arguments = ProcessInfo.processInfo.arguments
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

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if let importedPdfPath = importPdf(from: url) {
      deliver(pdfPath: importedPdfPath)
      return true
    }

    return super.application(app, open: url, options: options)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func deliver(pdfPath: String) {
    if let eventSink {
      eventSink(pdfPath)
      return
    }

    pendingInitialPdfPath = pdfPath
  }

  private func importPdf(from url: URL) -> String? {
    guard url.pathExtension.lowercased() == "pdf" else {
      return nil
    }

    let needsScopedAccess = url.startAccessingSecurityScopedResource()
    defer {
      if needsScopedAccess {
        url.stopAccessingSecurityScopedResource()
      }
    }

    let incomingDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent("incoming-pdf", isDirectory: true)

    do {
      try FileManager.default.createDirectory(
        at: incomingDirectory,
        withIntermediateDirectories: true,
        attributes: nil
      )

      let fileName = sanitizedFileName(url.lastPathComponent)
      let destinationUrl = incomingDirectory.appendingPathComponent(
        "\(UUID().uuidString)-\(fileName)",
        isDirectory: false
      )

      if FileManager.default.fileExists(atPath: destinationUrl.path) {
        try FileManager.default.removeItem(at: destinationUrl)
      }

      try FileManager.default.copyItem(at: url, to: destinationUrl)
      return destinationUrl.path
    } catch {
      return nil
    }
  }

  private func sanitizedFileName(_ fileName: String) -> String {
    let candidate = fileName.isEmpty ? "document.pdf" : fileName
    let ensuredExtension = candidate.lowercased().hasSuffix(".pdf") ? candidate : "\(candidate).pdf"
    let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")

    return String(
      ensuredExtension.unicodeScalars.map { scalar in
        allowedCharacters.contains(scalar) ? Character(scalar) : "_"
      }
    )
  }
}
