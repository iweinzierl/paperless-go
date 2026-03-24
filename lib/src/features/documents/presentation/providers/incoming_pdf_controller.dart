import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final incomingPdfPlatformBridgeProvider = Provider<IncomingPdfPlatformBridge>(
  (ref) => const MethodChannelIncomingPdfPlatformBridge(),
);

final incomingPdfControllerProvider =
    NotifierProvider<IncomingPdfController, IncomingPdfState>(
      IncomingPdfController.new,
    );

abstract class IncomingPdfPlatformBridge {
  Future<String?> consumeInitialPdfPath();

  Stream<String> get openedPdfPaths;
}

class MethodChannelIncomingPdfPlatformBridge
    implements IncomingPdfPlatformBridge {
  const MethodChannelIncomingPdfPlatformBridge();

  static const MethodChannel _methodChannel = MethodChannel(
    'com.github.iweinzierl.paperlessgo/open_document',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.github.iweinzierl.paperlessgo/open_document/events',
  );

  @override
  Future<String?> consumeInitialPdfPath() async {
    final path = await _methodChannel.invokeMethod<String>(
      'consumeInitialPdfPath',
    );
    if (path == null || path.trim().isEmpty) {
      return null;
    }

    return path.trim();
  }

  @override
  Stream<String> get openedPdfPaths => _eventChannel
      .receiveBroadcastStream()
      .map((dynamic path) => path is String ? path.trim() : '')
      .where((path) => path.isNotEmpty);
}

class IncomingPdfController extends Notifier<IncomingPdfState> {
  StreamSubscription<String>? _subscription;
  bool _didLoadInitialDocument = false;

  @override
  IncomingPdfState build() {
    final bridge = ref.watch(incomingPdfPlatformBridgeProvider);

    _subscription ??= bridge.openedPdfPaths.listen(enqueuePdfPath);
    ref.onDispose(() => _subscription?.cancel());

    if (!_didLoadInitialDocument) {
      _didLoadInitialDocument = true;
      Future<void>(() async {
        final initialPath = await bridge.consumeInitialPdfPath();
        if (initialPath != null) {
          enqueuePdfPath(initialPath);
        }
      });
    }

    return const IncomingPdfState();
  }

  void enqueuePdfPath(String filePath) {
    final normalizedPath = filePath.trim();
    if (normalizedPath.isEmpty) {
      return;
    }

    state = state.copyWith(pendingPdfPath: normalizedPath);
  }

  String? consumePendingPdfPath() {
    final pendingPdfPath = state.pendingPdfPath;
    if (pendingPdfPath == null || pendingPdfPath.isEmpty) {
      return null;
    }

    state = state.copyWith(clearPendingPdfPath: true);
    return pendingPdfPath;
  }
}

class IncomingPdfState {
  const IncomingPdfState({this.pendingPdfPath});

  final String? pendingPdfPath;

  IncomingPdfState copyWith({
    String? pendingPdfPath,
    bool clearPendingPdfPath = false,
  }) {
    return IncomingPdfState(
      pendingPdfPath: clearPendingPdfPath
          ? null
          : pendingPdfPath ?? this.pendingPdfPath,
    );
  }
}
