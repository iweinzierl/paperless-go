import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';

final documentFileOpenerProvider = Provider<DocumentFileOpener>(
  (ref) => const SystemDocumentFileOpener(),
);

final documentOpenControllerProvider =
    NotifierProvider<DocumentOpenController, Set<int>>(
      DocumentOpenController.new,
    );

abstract class DocumentFileOpener {
  Future<void> open(String filePath);
}

enum DocumentOpenVariant { download, preview }

class SystemDocumentFileOpener implements DocumentFileOpener {
  const SystemDocumentFileOpener();

  @override
  Future<void> open(String filePath) async {
    final result = await OpenFilex.open(filePath);
    if (result.type != ResultType.done) {
      throw DocumentsFailure(
        result.message.isNotEmpty
            ? result.message
            : 'The document could not be opened on this device.',
      );
    }
  }
}

class DocumentOpenController extends Notifier<Set<int>> {
  @override
  Set<int> build() => <int>{};

  Future<void> openDocument(
    PaperlessDocument document, {
    bool original = false,
    DocumentOpenVariant variant = DocumentOpenVariant.download,
  }) async {
    state = <int>{...state, document.id};

    try {
      final repository = ref.read(documentsRepositoryProvider);
      final filePath = await switch (variant) {
        DocumentOpenVariant.download =>
          repository.downloadDocumentToTemporaryFile(
            document: document,
            original: original,
          ),
        DocumentOpenVariant.preview =>
          repository.downloadPreviewToTemporaryFile(
            document: document,
            original: original,
          ),
      };
      await ref.read(documentFileOpenerProvider).open(filePath);
    } finally {
      state = state.where((id) => id != document.id).toSet();
    }
  }
}
