import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document_page.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_filter_option.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/models/documents_filter_state.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/models/documents_sort_option.dart';

final recentUploadsProvider = FutureProvider<List<PaperlessDocument>>((
  ref,
) async {
  final repository = ref.watch(documentsRepositoryProvider);
  return repository.fetchRecentUploads();
});

final reviewDocumentsProvider = FutureProvider<List<PaperlessDocument>>((
  ref,
) async {
  final repository = ref.watch(documentsRepositoryProvider);
  final documents = await repository.fetchAllDocuments(
    ordering: '-added',
    isInInbox: true,
  );
  final sortedDocuments = documents.toList(growable: false)
    ..sort((left, right) {
      final leftAdded =
          DateTime.tryParse(left.added ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final rightAdded =
          DateTime.tryParse(right.added ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return rightAdded.compareTo(leftAdded);
    });

  return sortedDocuments;
});

final documentsSearchQueryProvider = StateProvider<String>((ref) => '');
final documentsCurrentPageProvider = StateProvider<int>((ref) => 1);
final documentsOrderingProvider = StateProvider<String>(
  (ref) => documentsSortOptions.first.ordering,
);
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
  final ordering = ref.watch(documentsOrderingProvider);
  final filters = ref.watch(documentsFilterStateProvider);

  return repository.fetchDocuments(
    page: page,
    ordering: ordering,
    titleFilter: query,
    tagIds: filters.tagIds,
    correspondentId: filters.correspondentId,
    documentTypeId: filters.documentTypeId,
  );
});
