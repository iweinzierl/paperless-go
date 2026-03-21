import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';

final documentScannerProvider = Provider<DocumentScanner>(
  (ref) => const SystemDocumentScanner(),
);

final documentScanComposerProvider = Provider<DocumentScanComposer>(
  (ref) => const PdfDocumentScanComposer(),
);

final documentScanControllerProvider =
    NotifierProvider<DocumentScanController, DocumentScanState>(
      DocumentScanController.new,
    );

abstract class DocumentScanner {
  Future<List<String>> scanPages();
}

abstract class DocumentScanComposer {
  Future<String> composeDocument(List<String> pagePaths);
}

class SystemDocumentScanner implements DocumentScanner {
  const SystemDocumentScanner();

  @override
  Future<List<String>> scanPages() async {
    final pagePaths = await CunningDocumentScanner.getPictures();
    if (pagePaths == null) {
      return const <String>[];
    }

    return pagePaths
        .where((path) => path.trim().isNotEmpty)
        .toList(growable: false);
  }
}

class PdfDocumentScanComposer implements DocumentScanComposer {
  const PdfDocumentScanComposer();

  @override
  Future<String> composeDocument(List<String> pagePaths) async {
    if (pagePaths.isEmpty) {
      throw const DocumentsFailure('No scanned pages available.');
    }

    final pdf = pw.Document();
    for (final pagePath in pagePaths) {
      final pageBytes = await File(pagePath).readAsBytes();
      final image = pw.MemoryImage(pageBytes);
      pdf.addPage(
        pw.Page(
          build: (context) {
            return pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain));
          },
        ),
      );
    }

    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/scan-${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save(), flush: true);
    return file.path;
  }
}

class DocumentScanController extends Notifier<DocumentScanState> {
  @override
  DocumentScanState build() => const DocumentScanState();

  void updateTitle(String value) {
    state = state.copyWith(title: value);
  }

  void removePageAt(int index) {
    if (index < 0 || index >= state.pagePaths.length || state.isBusy) {
      return;
    }

    final nextPages = [...state.pagePaths]..removeAt(index);
    state = state.copyWith(pagePaths: nextPages);
  }

  Future<void> scanPages({bool replaceExisting = false}) async {
    if (state.isBusy) {
      return;
    }

    state = state.copyWith(isScanning: true, clearUploadStatus: true);

    try {
      final scannedPages = await ref.read(documentScannerProvider).scanPages();
      if (scannedPages.isEmpty) {
        return;
      }

      state = state.copyWith(
        pagePaths: replaceExisting
            ? scannedPages
            : [...state.pagePaths, ...scannedPages],
      );
    } finally {
      state = state.copyWith(isScanning: false);
    }
  }

  Future<String> upload() async {
    if (state.pagePaths.isEmpty) {
      throw const DocumentsFailure('No scanned pages available.');
    }

    state = state.copyWith(uploadStatus: const AsyncLoading<String>());

    final result = await AsyncValue.guard<String>(() async {
      final filePath = await ref
          .read(documentScanComposerProvider)
          .composeDocument(state.pagePaths);
      return ref
          .read(documentsRepositoryProvider)
          .uploadDocument(filePath: filePath, title: state.title);
    });

    state = state.copyWith(uploadStatus: result);

    if (result.hasValue) {
      ref.invalidate(recentUploadsProvider);
      ref.invalidate(documentsPageProvider);
      return result.requireValue;
    }

    throw result.error!;
  }
}

class DocumentScanState {
  const DocumentScanState({
    this.pagePaths = const <String>[],
    this.title = '',
    this.isScanning = false,
    this.uploadStatus = const AsyncData<String>(''),
  });

  final List<String> pagePaths;
  final String title;
  final bool isScanning;
  final AsyncValue<String> uploadStatus;

  bool get hasPages => pagePaths.isNotEmpty;
  bool get isUploading => uploadStatus.isLoading;
  bool get isBusy => isScanning || isUploading;

  DocumentScanState copyWith({
    List<String>? pagePaths,
    String? title,
    bool? isScanning,
    AsyncValue<String>? uploadStatus,
    bool clearUploadStatus = false,
  }) {
    return DocumentScanState(
      pagePaths: pagePaths ?? this.pagePaths,
      title: title ?? this.title,
      isScanning: isScanning ?? this.isScanning,
      uploadStatus: clearUploadStatus
          ? const AsyncData<String>('')
          : uploadStatus ?? this.uploadStatus,
    );
  }
}
