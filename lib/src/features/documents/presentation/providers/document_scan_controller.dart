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
    AutoDisposeNotifierProvider<DocumentScanController, DocumentScanState>(
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

class DocumentScanController extends AutoDisposeNotifier<DocumentScanState> {
  @override
  DocumentScanState build() => const DocumentScanState();

  void updateTitle(String value) {
    state = state.copyWith(title: value);
  }

  void importPdf(String filePath) {
    final normalizedPath = filePath.trim();
    if (normalizedPath.isEmpty || state.isBusy) {
      return;
    }

    state = state.copyWith(
      pagePaths: const <String>[],
      importedDocumentPath: normalizedPath,
      title: _defaultTitleFromPath(normalizedPath),
      clearUploadStatus: true,
    );
  }

  void removePageAt(int index) {
    if (index < 0 || index >= state.pagePaths.length || state.isBusy) {
      return;
    }

    final nextPages = [...state.pagePaths]..removeAt(index);
    state = state.copyWith(pagePaths: nextPages);
  }

  void removeImportedDocument() {
    if (!state.hasImportedDocument || state.isBusy) {
      return;
    }

    state = state.copyWith(
      clearImportedDocument: true,
      clearUploadStatus: true,
    );
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
            : state.hasImportedDocument
            ? scannedPages
            : [...state.pagePaths, ...scannedPages],
        clearImportedDocument: true,
      );
    } finally {
      state = state.copyWith(isScanning: false);
    }
  }

  Future<String> upload() async {
    if (!state.hasContent) {
      throw const DocumentsFailure('No scanned pages available.');
    }

    state = state.copyWith(uploadStatus: const AsyncLoading<String>());

    final result = await AsyncValue.guard<String>(() async {
      final filePath =
          state.importedDocumentPath ??
          await ref
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

  String _defaultTitleFromPath(String filePath) {
    final fileName = Uri.file(filePath).pathSegments.last;
    if (fileName.isEmpty) {
      return '';
    }

    const extension = '.pdf';
    if (fileName.toLowerCase().endsWith(extension)) {
      return fileName.substring(0, fileName.length - extension.length);
    }

    return fileName;
  }
}

class DocumentScanState {
  const DocumentScanState({
    this.pagePaths = const <String>[],
    this.importedDocumentPath,
    this.title = '',
    this.isScanning = false,
    this.uploadStatus = const AsyncData<String>(''),
  });

  final List<String> pagePaths;
  final String? importedDocumentPath;
  final String title;
  final bool isScanning;
  final AsyncValue<String> uploadStatus;

  bool get hasPages => pagePaths.isNotEmpty;
  bool get hasImportedDocument =>
      importedDocumentPath != null && importedDocumentPath!.isNotEmpty;
  bool get hasContent => hasPages || hasImportedDocument;
  bool get isUploading => uploadStatus.isLoading;
  bool get isBusy => isScanning || isUploading;

  DocumentScanState copyWith({
    List<String>? pagePaths,
    String? importedDocumentPath,
    String? title,
    bool? isScanning,
    AsyncValue<String>? uploadStatus,
    bool clearUploadStatus = false,
    bool clearImportedDocument = false,
  }) {
    return DocumentScanState(
      pagePaths: pagePaths ?? this.pagePaths,
      importedDocumentPath: clearImportedDocument
          ? null
          : importedDocumentPath ?? this.importedDocumentPath,
      title: title ?? this.title,
      isScanning: isScanning ?? this.isScanning,
      uploadStatus: clearUploadStatus
          ? const AsyncData<String>('')
          : uploadStatus ?? this.uploadStatus,
    );
  }
}
