import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_detail_provider.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';

final documentDeleteControllerProvider =
    NotifierProvider<DocumentDeleteController, Set<int>>(
      DocumentDeleteController.new,
    );

class DocumentDeleteController extends Notifier<Set<int>> {
  @override
  Set<int> build() => <int>{};

  Future<void> deleteDocument(PaperlessDocument document) async {
    await deleteDocuments([document]);
  }

  Future<void> deleteDocuments(Iterable<PaperlessDocument> documents) async {
    final documentsList = documents.toList(growable: false);
    if (documentsList.isEmpty) {
      return;
    }

    final documentIds = documentsList.map((document) => document.id).toSet();
    state = <int>{...state, ...documentIds};

    try {
      final repository = ref.read(documentsRepositoryProvider);
      for (final document in documentsList) {
        await repository.deleteDocument(documentId: document.id);
        _handleDeletedDocument(document.id);
      }
    } finally {
      state = <int>{...state}..removeAll(documentIds);
    }
  }

  void _handleDeletedDocument(int documentId) {
    ref.invalidate(documentDetailProvider(documentId));
    ref.invalidate(documentsPageProvider);
    ref.invalidate(recentUploadsProvider);
    ref.invalidate(reviewDocumentsProvider);
    ref
        .read(recentlyOpenedDocumentsProvider.notifier)
        .removeDocument(documentId);
  }
}
