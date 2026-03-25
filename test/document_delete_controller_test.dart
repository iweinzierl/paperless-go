import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paperless_ngx_app/src/core/providers/shared_preferences_provider.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_session.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document_page.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_delete_controller.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_detail_provider.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';

void main() {
  const document = PaperlessDocument(id: 7, title: 'Invoice.pdf');

  test('delete controller deletes and invalidates document data', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final sharedPreferences = await SharedPreferences.getInstance();
    final repository = _FakeDocumentsRepository();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        documentsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    container.read(recentlyOpenedDocumentsProvider.notifier).record(document);

    await container.read(documentDetailProvider(document.id).future);
    await container.read(documentsPageProvider.future);
    await container.read(recentUploadsProvider.future);
    await container.read(reviewDocumentsProvider.future);

    expect(repository.fetchDocumentCallCount, 1);
    expect(repository.fetchDocumentsCallCount, 1);
    expect(repository.fetchRecentUploadsCallCount, 1);
    expect(repository.fetchAllDocumentsCallCount, 1);
    expect(
      container
          .read(recentlyOpenedDocumentsProvider)
          .where((item) => item.id == document.id),
      isNotEmpty,
    );

    await container
        .read(documentDeleteControllerProvider.notifier)
        .deleteDocument(document);

    expect(repository.deletedDocumentId, document.id);
    expect(container.read(documentDeleteControllerProvider), isEmpty);
    expect(
      container
          .read(recentlyOpenedDocumentsProvider)
          .where((item) => item.id == document.id),
      isEmpty,
    );

    await container.read(documentDetailProvider(document.id).future);
    await container.read(documentsPageProvider.future);
    await container.read(recentUploadsProvider.future);
    await container.read(reviewDocumentsProvider.future);

    expect(repository.fetchDocumentCallCount, 2);
    expect(repository.fetchDocumentsCallCount, 2);
    expect(repository.fetchRecentUploadsCallCount, 2);
    expect(repository.fetchAllDocumentsCallCount, 2);
  });

  test('delete controller clears loading state when deletion fails', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final sharedPreferences = await SharedPreferences.getInstance();
    final repository = _FakeDocumentsRepository(shouldThrowOnDelete: true);
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        documentsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container
          .read(documentDeleteControllerProvider.notifier)
          .deleteDocument(document),
      throwsA(isA<DocumentsFailure>()),
    );

    expect(container.read(documentDeleteControllerProvider), isEmpty);
  });
}

class _FakeDocumentsRepository extends DocumentsRepository {
  _FakeDocumentsRepository({this.shouldThrowOnDelete = false})
    : super(
        dio: Dio(),
        session: const PaperlessAuthSession(
          serverUrl: 'https://example.com/paperless/',
          username: 'jane',
          password: 'secret',
          authToken: 'token-123',
        ),
      );

  final bool shouldThrowOnDelete;

  int? deletedDocumentId;
  int fetchDocumentCallCount = 0;
  int fetchDocumentsCallCount = 0;
  int fetchRecentUploadsCallCount = 0;
  int fetchAllDocumentsCallCount = 0;

  @override
  Future<void> deleteDocument({required int documentId}) async {
    if (shouldThrowOnDelete) {
      throw const DocumentsFailure('Delete failed');
    }

    deletedDocumentId = documentId;
  }

  @override
  Future<PaperlessDocument> fetchDocument(int documentId) async {
    fetchDocumentCallCount += 1;
    return PaperlessDocument(id: documentId, title: 'Invoice.pdf');
  }

  @override
  Future<PaperlessDocumentPage> fetchDocuments({
    int page = 1,
    int pageSize = 20,
    String ordering = '-created',
    String titleFilter = '',
    List<int> tagIds = const <int>[],
    bool? isInInbox,
    int? correspondentId,
    int? documentTypeId,
  }) async {
    fetchDocumentsCallCount += 1;
    return const PaperlessDocumentPage(
      count: 1,
      results: <PaperlessDocument>[
        PaperlessDocument(id: 7, title: 'Invoice.pdf'),
      ],
    );
  }

  @override
  Future<List<PaperlessDocument>> fetchRecentUploads() async {
    fetchRecentUploadsCallCount += 1;
    return const <PaperlessDocument>[
      PaperlessDocument(id: 7, title: 'Invoice.pdf'),
    ];
  }

  @override
  Future<List<PaperlessDocument>> fetchAllDocuments({
    int pageSize = 100,
    String ordering = '-created',
    String titleFilter = '',
    List<int> tagIds = const <int>[],
    bool? isInInbox,
    int? correspondentId,
    int? documentTypeId,
  }) async {
    fetchAllDocumentsCallCount += 1;
    return const <PaperlessDocument>[
      PaperlessDocument(id: 7, title: 'Invoice.pdf'),
    ];
  }
}
