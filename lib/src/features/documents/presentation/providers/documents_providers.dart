import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document_page.dart';

final recentUploadsProvider = FutureProvider<List<PaperlessDocument>>((
  ref,
) async {
  final repository = ref.watch(documentsRepositoryProvider);
  return repository.fetchRecentUploads();
});

final documentsSearchQueryProvider = StateProvider<String>((ref) => '');
final documentsCurrentPageProvider = StateProvider<int>((ref) => 1);

final documentsPageProvider = FutureProvider<PaperlessDocumentPage>((
  ref,
) async {
  final repository = ref.watch(documentsRepositoryProvider);
  final query = ref.watch(documentsSearchQueryProvider);
  final page = ref.watch(documentsCurrentPageProvider);

  return repository.fetchDocuments(page: page, titleFilter: query);
});
