import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_session.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_open_controller.dart';

void main() {
  const document = PaperlessDocument(id: 7, title: 'Invoice.pdf');

  test('open controller downloads and opens a document', () async {
    final repository = _FakeDocumentsRepository();
    final opener = _FakeDocumentFileOpener();
    final container = ProviderContainer(
      overrides: [
        documentsRepositoryProvider.overrideWithValue(repository),
        documentFileOpenerProvider.overrideWithValue(opener),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(documentOpenControllerProvider.notifier)
        .openDocument(document);

    expect(repository.downloadedDocumentId, document.id);
    expect(repository.previewRequested, isFalse);
    expect(opener.openedPaths, ['/tmp/document-7.pdf']);
    expect(container.read(documentOpenControllerProvider), isEmpty);
  });

  test('open controller clears loading state when opening fails', () async {
    final repository = _FakeDocumentsRepository();
    final opener = _FakeDocumentFileOpener(shouldThrow: true);
    final container = ProviderContainer(
      overrides: [
        documentsRepositoryProvider.overrideWithValue(repository),
        documentFileOpenerProvider.overrideWithValue(opener),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container
          .read(documentOpenControllerProvider.notifier)
          .openDocument(document),
      throwsA(isA<DocumentsFailure>()),
    );

    expect(container.read(documentOpenControllerProvider), isEmpty);
  });
}

class _FakeDocumentsRepository extends DocumentsRepository {
  _FakeDocumentsRepository()
    : super(
        dio: Dio(),
        session: const PaperlessAuthSession(
          serverUrl: 'https://example.com/paperless/',
          username: 'jane',
          password: 'secret',
          authToken: 'token-123',
        ),
      );

  int? downloadedDocumentId;
  bool previewRequested = false;

  @override
  Future<String> downloadDocumentToTemporaryFile({
    required PaperlessDocument document,
    bool original = false,
  }) async {
    downloadedDocumentId = document.id;
    previewRequested = false;
    return '/tmp/document-${document.id}.pdf';
  }

  @override
  Future<String> downloadPreviewToTemporaryFile({
    required PaperlessDocument document,
    bool original = false,
  }) async {
    downloadedDocumentId = document.id;
    previewRequested = true;
    return '/tmp/preview-${document.id}.pdf';
  }
}

class _FakeDocumentFileOpener implements DocumentFileOpener {
  _FakeDocumentFileOpener({this.shouldThrow = false});

  final bool shouldThrow;
  final List<String> openedPaths = <String>[];

  @override
  Future<void> open(String filePath) async {
    if (shouldThrow) {
      throw const DocumentsFailure('Open failed');
    }

    openedPaths.add(filePath);
  }
}
