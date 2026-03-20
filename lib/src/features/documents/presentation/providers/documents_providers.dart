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

final todoDocumentsProvider = FutureProvider<List<PaperlessDocument>>((
  ref,
) async {
  const reviewTagName = 'Prüfen';
  final repository = ref.watch(documentsRepositoryProvider);
  final tags = await ref.watch(tagOptionsProvider.future);
  final reviewTag = tags.where((tag) => tag.name == reviewTagName).firstOrNull;

  if (reviewTag == null) {
    return const <PaperlessDocument>[];
  }

  final page = await repository.fetchDocuments(
    ordering: '-added',
    tagId: reviewTag.id,
  );

  return page.results;
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
    tagId: filters.tagId,
    correspondentId: filters.correspondentId,
    documentTypeId: filters.documentTypeId,
  );
});
