import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/providers/shared_preferences_provider.dart';
import 'package:paperless_ngx_app/src/features/documents/data/local/documents_view_preferences.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document_page.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_filter_option.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_saved_view.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/models/documents_filter_state.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/models/documents_layout_mode.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/models/documents_sort_option.dart';

final documentsViewPreferencesProvider = Provider<DocumentsViewPreferences>((
  ref,
) {
  return DocumentsViewPreferences(ref.watch(sharedPreferencesProvider));
});

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
final documentsLayoutModeProvider = StateProvider<DocumentsLayoutMode>((ref) {
  return ref.watch(documentsViewPreferencesProvider).readLayoutMode();
});

final documentsSelectionProvider = StateProvider.autoDispose<Set<int>>(
  (ref) => <int>{},
);

final recentUploadsSelectionProvider = StateProvider.autoDispose<Set<int>>(
  (ref) => <int>{},
);

final reviewDocumentsSelectionProvider = StateProvider.autoDispose<Set<int>>(
  (ref) => <int>{},
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

final storagePathOptionsProvider = FutureProvider<List<PaperlessFilterOption>>((
  ref,
) async {
  final repository = ref.watch(documentsRepositoryProvider);
  return repository.fetchStoragePathOptions();
});

final savedViewsProvider = FutureProvider<List<PaperlessSavedView>>((
  ref,
) async {
  final repository = ref.watch(documentsRepositoryProvider);
  return repository.fetchSavedViews();
});

final savedViewCountsProvider = FutureProvider<Map<int, int>>((ref) async {
  final repository = ref.watch(documentsRepositoryProvider);
  final savedViews = await ref.watch(savedViewsProvider.future);
  if (savedViews.isEmpty) {
    return const <int, int>{};
  }

  final counts = await Future.wait(
    savedViews.map((savedView) async {
      try {
        final count = await repository.fetchSavedViewDocumentCount(
          savedView: savedView,
        );
        return MapEntry(savedView.id, count);
      } catch (_) {
        return null;
      }
    }),
  );

  return Map<int, int>.fromEntries(counts.whereType<MapEntry<int, int>>());
});

final activeSavedViewIdProvider = StateProvider<int?>((ref) => null);

final activeSavedViewProvider = Provider<PaperlessSavedView?>((ref) {
  final activeSavedViewId = ref.watch(activeSavedViewIdProvider);
  final savedViews = ref.watch(savedViewsProvider).valueOrNull;
  if (activeSavedViewId == null || savedViews == null) {
    return null;
  }

  return savedViews.where((view) => view.id == activeSavedViewId).firstOrNull;
});

final documentsPageProvider = FutureProvider<PaperlessDocumentPage>((
  ref,
) async {
  final repository = ref.watch(documentsRepositoryProvider);
  final query = ref.watch(documentsSearchQueryProvider);
  final page = ref.watch(documentsCurrentPageProvider);
  final ordering = ref.watch(documentsOrderingProvider);
  final filters = ref.watch(documentsFilterStateProvider);
  final activeSavedView = ref.watch(activeSavedViewProvider);

  if (activeSavedView != null) {
    return repository.fetchDocumentsForSavedView(
      savedView: activeSavedView,
      page: page,
    );
  }

  return repository.fetchDocuments(
    page: page,
    ordering: ordering,
    titleFilter: query,
    tagIds: filters.tagIds,
    correspondentId: filters.correspondentId,
    documentTypeId: filters.documentTypeId,
  );
});
