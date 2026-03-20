import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_behavior_providers.dart';
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
  final repository = ref.watch(documentsRepositoryProvider);
  final behaviorSettings = ref.watch(appBehaviorSettingsProvider);
  final tags = await ref.watch(tagOptionsProvider.future);
  final configuredIds = behaviorSettings.normalizedTodoTagIds.toSet();
  final reviewTags = configuredIds.isNotEmpty
      ? tags
            .where((tag) => configuredIds.contains(tag.id))
            .toList(growable: false)
      : tags
            .where((tag) {
              final configuredNames = behaviorSettings.normalizedTodoTagNames
                  .map((name) => name.toLowerCase())
                  .toSet();
              return configuredNames.contains(tag.name.trim().toLowerCase());
            })
            .toList(growable: false);

  if (reviewTags.isEmpty) {
    return const <PaperlessDocument>[];
  }

  final pages = await Future.wait(
    reviewTags.map(
      (tag) => repository.fetchDocuments(ordering: '-added', tagId: tag.id),
    ),
  );
  final documentsById = <int, PaperlessDocument>{};
  for (final page in pages) {
    for (final document in page.results) {
      documentsById[document.id] = document;
    }
  }

  final documents = documentsById.values.toList(growable: false)
    ..sort((left, right) {
      final leftAdded =
          DateTime.tryParse(left.added ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final rightAdded =
          DateTime.tryParse(right.added ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return rightAdded.compareTo(leftAdded);
    });

  return documents;
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
