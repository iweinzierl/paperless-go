import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_session.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_scan_controller.dart';

void main() {
  test('scan controller collects pages and uploads a generated pdf', () async {
    final repository = _FakeDocumentsRepository();
    final scanner = _FakeDocumentScanner();
    final composer = _FakeDocumentScanComposer();
    final container = ProviderContainer(
      overrides: [
        documentsRepositoryProvider.overrideWithValue(repository),
        documentScannerProvider.overrideWithValue(scanner),
        documentScanComposerProvider.overrideWithValue(composer),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(documentScanControllerProvider.notifier);

    await notifier.scanPages();
    notifier.updateTitle('Inbox receipt');
    final taskId = await notifier.upload();

    expect(container.read(documentScanControllerProvider).pagePaths, [
      '/tmp/page-1.jpg',
      '/tmp/page-2.jpg',
    ]);
    expect(composer.composedPaths, ['/tmp/page-1.jpg', '/tmp/page-2.jpg']);
    expect(repository.uploadedFilePath, '/tmp/scan.pdf');
    expect(repository.uploadedTitle, 'Inbox receipt');
    expect(taskId, 'task-123');
  });

  test('scan controller clears a removed page', () async {
    final container = ProviderContainer(
      overrides: [
        documentScannerProvider.overrideWithValue(_FakeDocumentScanner()),
        documentScanComposerProvider.overrideWithValue(
          _FakeDocumentScanComposer(),
        ),
        documentsRepositoryProvider.overrideWithValue(
          _FakeDocumentsRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(documentScanControllerProvider.notifier);
    await notifier.scanPages();
    notifier.removePageAt(0);

    expect(container.read(documentScanControllerProvider).pagePaths, [
      '/tmp/page-2.jpg',
    ]);
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

  String? uploadedFilePath;
  String? uploadedTitle;

  @override
  Future<String> uploadDocument({
    required String filePath,
    String? title,
  }) async {
    uploadedFilePath = filePath;
    uploadedTitle = title;
    return 'task-123';
  }
}

class _FakeDocumentScanner implements DocumentScanner {
  @override
  Future<List<String>> scanPages() async {
    return ['/tmp/page-1.jpg', '/tmp/page-2.jpg'];
  }
}

class _FakeDocumentScanComposer implements DocumentScanComposer {
  List<String> composedPaths = const <String>[];

  @override
  Future<String> composeDocument(List<String> pagePaths) async {
    composedPaths = pagePaths;
    return '/tmp/scan.pdf';
  }
}
