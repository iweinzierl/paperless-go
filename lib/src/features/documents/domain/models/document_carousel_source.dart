import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_saved_view.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/models/documents_filter_state.dart';

sealed class DocumentCarouselSource {
  const DocumentCarouselSource();
}

/// Source from the paginated documents list page.
class DocumentListSource extends DocumentCarouselSource {
  const DocumentListSource({
    required this.searchQuery,
    required this.ordering,
    required this.filters,
    required this.currentServerPage,
    required this.totalCount,
    this.activeSavedView,
  });

  final String searchQuery;
  final String ordering;
  final DocumentsFilterState filters;
  final PaperlessSavedView? activeSavedView;
  final int currentServerPage;
  final int totalCount;
}

/// Source from the home screen recent uploads list.
/// No server-side pagination — the list is a fixed recent set.
class RecentUploadsSource extends DocumentCarouselSource {
  const RecentUploadsSource();
}
