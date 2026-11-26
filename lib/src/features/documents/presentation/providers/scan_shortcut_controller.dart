import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final scanShortcutPlatformBridgeProvider = Provider<ScanShortcutPlatformBridge>(
  (ref) => const MethodChannelScanShortcutPlatformBridge(),
);

final scanShortcutControllerProvider =
    NotifierProvider<ScanShortcutController, bool>(ScanShortcutController.new);

/// Receives "open the scan screen" requests from the Android home screen
/// widget.
abstract class ScanShortcutPlatformBridge {
  /// Whether the app was launched from the widget. Returns true only once.
  Future<bool> consumeInitialScanRequest();

  /// Emits whenever the widget is tapped while the app is running.
  Stream<void> get scanRequests;
}

class MethodChannelScanShortcutPlatformBridge
    implements ScanShortcutPlatformBridge {
  const MethodChannelScanShortcutPlatformBridge();

  static const MethodChannel _methodChannel = MethodChannel(
    'com.github.iweinzierl.paperlessgo/scan_shortcut',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.github.iweinzierl.paperlessgo/scan_shortcut/events',
  );

  @override
  Future<bool> consumeInitialScanRequest() async {
    try {
      return await _methodChannel.invokeMethod<bool>(
            'consumeInitialScanRequest',
          ) ??
          false;
    } on MissingPluginException {
      // iOS has no widget, so the channel isn't registered there.
      return false;
    }
  }

  @override
  Stream<void> get scanRequests => _eventChannel
      .receiveBroadcastStream()
      .handleError(
        (Object _) {},
        test: (error) => error is MissingPluginException,
      )
      .map((_) {});
}

/// Holds whether a scan request from the widget is waiting to be handled.
class ScanShortcutController extends Notifier<bool> {
  StreamSubscription<void>? _subscription;
  bool _didLoadInitialRequest = false;

  @override
  bool build() {
    final bridge = ref.watch(scanShortcutPlatformBridgeProvider);

    _subscription ??= bridge.scanRequests.listen((_) => requestScan());
    ref.onDispose(() => _subscription?.cancel());

    if (!_didLoadInitialRequest) {
      _didLoadInitialRequest = true;
      Future<void>.microtask(() async {
        if (await bridge.consumeInitialScanRequest()) {
          requestScan();
        }
      });
    }

    return false;
  }

  void requestScan() => state = true;

  /// Returns true and clears the request if one was pending.
  bool consumePendingScanRequest() {
    if (!state) {
      return false;
    }

    state = false;
    return true;
  }
}
