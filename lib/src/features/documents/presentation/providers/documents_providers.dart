import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document_page.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_filter_option.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/models/documents_filter_state.dart';

final recentUploadsProvider = FutureProvider<List<PaperlessDocument>>((
  ref,
) async {
  final repository = ref.watch(documentsRepositoryProvider);
  return repository.fetchRecentUploads();
});

final documentsSearchQueryProvider = StateProvider<String>((ref) => '');
final documentsCurrentPageProvider = StateProvider<int>((ref) => 1);
final documentsFilterStateProvider = StateProvider<DocumentsFilterState>(
  (ref) => const DocumentsFilterState(),
);

final tagOptionsProvider = FutureProvider<List<PaperlessFilterOption>>((
  ref,
) async {
  final repository = ref.watch(documentsRepositoryProvider);
  return repository.fetchTagOptions();
});

final correspondentOptionsProvider =
    FutureProvider<List<PaperlessFilterOption>>((ref) async {
      final repository = ref.watch(documentsRepositoryProvider);
      return repository.fetchCorrespondentOptions();
    });

final documentTypeOptionsProvider = FutureProvider<List<PaperlessFilterOption>>(
  (ref) async {
    final repository = ref.watch(documentsRepositoryProvider);
    return repository.fetchDocumentTypeOptions();
  },
);

final documentsPageProvider = FutureProvider<PaperlessDocumentPage>((
  ref,
) async {
  final repository = ref.watch(documentsRepositoryProvider);
  final query = ref.watch(documentsSearchQueryProvider);
  final page = ref.watch(documentsCurrentPageProvider);
  final filters = ref.watch(documentsFilterStateProvider);

  return repository.fetchDocuments(
    page: page,
    titleFilter: query,
    tagId: filters.tagId,
    correspondentId: filters.correspondentId,
    documentTypeId: filters.documentTypeId,
  );
});
