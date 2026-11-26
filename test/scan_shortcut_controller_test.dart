import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/scan_shortcut_controller.dart';

void main() {
  ProviderContainer createContainer(_FakeBridge bridge) {
    final container = ProviderContainer(
      overrides: [scanShortcutPlatformBridgeProvider.overrideWithValue(bridge)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('a launch from the widget becomes a pending scan request', () async {
    final bridge = _FakeBridge(initialRequest: true);
    addTearDown(bridge.dispose);
    final container = createContainer(bridge);

    expect(container.read(scanShortcutControllerProvider), isFalse);
    await pumpEventQueue();

    expect(container.read(scanShortcutControllerProvider), isTrue);
  });

  test('a widget tap while running becomes a pending scan request', () async {
    final bridge = _FakeBridge();
    addTearDown(bridge.dispose);
    final container = createContainer(bridge);
    container.read(scanShortcutControllerProvider);
    await pumpEventQueue();
    expect(container.read(scanShortcutControllerProvider), isFalse);

    bridge.taps.add(null);
    await pumpEventQueue();

    expect(container.read(scanShortcutControllerProvider), isTrue);
  });

  test('a pending request is consumed exactly once', () async {
    final bridge = _FakeBridge(initialRequest: true);
    addTearDown(bridge.dispose);
    final container = createContainer(bridge);
    container.read(scanShortcutControllerProvider);
    await pumpEventQueue();
    final controller = container.read(scanShortcutControllerProvider.notifier);

    expect(controller.consumePendingScanRequest(), isTrue);
    expect(controller.consumePendingScanRequest(), isFalse);
    expect(container.read(scanShortcutControllerProvider), isFalse);
  });
}

class _FakeBridge implements ScanShortcutPlatformBridge {
  _FakeBridge({this.initialRequest = false});

  final bool initialRequest;
  final StreamController<void> taps = StreamController<void>.broadcast();

  Future<void> dispose() => taps.close();

  @override
  Future<bool> consumeInitialScanRequest() async => initialRequest;

  @override
  Stream<void> get scanRequests => taps.stream;
}
