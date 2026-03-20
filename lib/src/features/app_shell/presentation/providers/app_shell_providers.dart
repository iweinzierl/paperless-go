import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/features/app_shell/domain/models/app_drawer_statistics.dart';
import 'package:paperless_ngx_app/src/features/app_shell/domain/models/recently_opened_document.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';

final appShellTabProvider = StateProvider<int>((ref) => 0);

final documentsCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(documentsRepositoryProvider);
  final page = await repository.fetchDocuments(pageSize: 1);
  return page.count;
});

final appDrawerStatisticsProvider = FutureProvider<AppDrawerStatistics>((
  ref,
) async {
  final documents = await ref.watch(documentsCountProvider.future);
  final correspondents = await ref.watch(correspondentOptionsProvider.future);
  final tags = await ref.watch(tagOptionsProvider.future);
  final documentTypes = await ref.watch(documentTypeOptionsProvider.future);

  return AppDrawerStatistics(
    documents: documents,
    correspondents: correspondents.length,
    tags: tags.length,
    documentTypes: documentTypes.length,
  );
});

final recentlyOpenedDocumentsProvider =
    NotifierProvider<
      RecentlyOpenedDocumentsController,
      List<RecentlyOpenedDocument>
    >(RecentlyOpenedDocumentsController.new);

class RecentlyOpenedDocumentsController
    extends Notifier<List<RecentlyOpenedDocument>> {
  static const _maxEntries = 10;

  @override
  List<RecentlyOpenedDocument> build() => const <RecentlyOpenedDocument>[];

  void record(PaperlessDocument document) {
    final entry = RecentlyOpenedDocument.fromDocument(document);
    final remaining = state.where((item) => item.id != document.id).toList();
    state = <RecentlyOpenedDocument>[
      entry,
      ...remaining,
    ].take(_maxEntries).toList(growable: false);
  }
}
