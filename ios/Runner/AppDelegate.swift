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
