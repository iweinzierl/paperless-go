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
    state = <int>{...state, document.id};

    try {
      await ref
          .read(documentsRepositoryProvider)
          .deleteDocument(documentId: document.id);
      ref.invalidate(documentDetailProvider(document.id));
      ref.invalidate(documentsPageProvider);
      ref.invalidate(recentUploadsProvider);
      ref.invalidate(reviewDocumentsProvider);
      ref
          .read(recentlyOpenedDocumentsProvider.notifier)
          .removeDocument(document.id);
    } finally {
      state = <int>{...state}..remove(document.id);
    }
  }
}
