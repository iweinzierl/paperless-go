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
    guard environment["PAPERLESS_SCREENSHOT_MODE"] == "1" else {
      return
    }

    let defaults = UserDefaults.standard
    let managedKeys = [
      "flutter.debug.screenshot_scenario",
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

    if environment["PAPERLESS_SCREENSHOT_AUTHENTICATED"] == "1" {
      defaults.set(
        environment["PAPERLESS_SCREENSHOT_SERVER_URL"] ?? "https://demo.paperless-ngx.local/",
        forKey: "flutter.auth.server_url"
      )
      defaults.set(
        environment["PAPERLESS_SCREENSHOT_USERNAME"] ?? "demo.user",
        forKey: "flutter.auth.username"
      )
      defaults.set(
        environment["PAPERLESS_SCREENSHOT_PASSWORD"] ?? "not-used",
        forKey: "flutter.auth.password"
      )
      defaults.set(
        environment["PAPERLESS_SCREENSHOT_TOKEN"] ?? "demo-token",
        forKey: "flutter.auth.token"
      )
      defaults.set(
        environment["PAPERLESS_SCREENSHOT_DISPLAY_NAME"] ?? "Demo User",
        forKey: "flutter.auth.display_name"
      )
    }
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
