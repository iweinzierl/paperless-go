import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_ngx_app/src/core/data/local/app_temporary_files.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_session.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_scan_controller.dart';

void main() {
  late Directory baseDirectory;
  late AppTemporaryFiles temporaryFiles;

  setUp(() async {
    baseDirectory = await Directory.systemTemp.createTemp('scan-test-');
    temporaryFiles = AppTemporaryFiles(baseDirectory: baseDirectory);
  });

  tearDown(() async {
    await baseDirectory.delete(recursive: true);
  });

  test('scan controller collects pages and uploads a generated pdf', () async {
    final repository = _FakeDocumentsRepository();
    final scanner = _FakeDocumentScanner();
    final composer = _FakeDocumentScanComposer(temporaryFiles);
    final container = ProviderContainer(
      overrides: [
        appTemporaryFilesProvider.overrideWithValue(temporaryFiles),
        documentsRepositoryProvider.overrideWithValue(repository),
        documentScannerProvider.overrideWithValue(scanner),
        documentScanComposerProvider.overrideWithValue(composer),
      ],
    );
    addTearDown(container.dispose);
    container.listen(documentScanControllerProvider, (previous, next) {});

    final notifier = container.read(documentScanControllerProvider.notifier);

    await notifier.scanPages();
    notifier.updateTitle('Inbox receipt');
    final taskId = await notifier.upload();

    expect(container.read(documentScanControllerProvider).pagePaths, [
      '/tmp/page-1.jpg',
      '/tmp/page-2.jpg',
    ]);
    expect(composer.composedPaths, ['/tmp/page-1.jpg', '/tmp/page-2.jpg']);
    expect(repository.uploadedFilePath, composer.composedFilePath);
    expect(repository.uploadedTitle, 'Inbox receipt');
    expect(taskId, 'task-123');
  });

  test(
    'scan controller uploads an imported pdf without composing pages',
    () async {
      final repository = _FakeDocumentsRepository();
      final composer = _FakeDocumentScanComposer(temporaryFiles);
      final container = ProviderContainer(
        overrides: [
          appTemporaryFilesProvider.overrideWithValue(temporaryFiles),
          documentsRepositoryProvider.overrideWithValue(repository),
          documentScannerProvider.overrideWithValue(_FakeDocumentScanner()),
          documentScanComposerProvider.overrideWithValue(composer),
        ],
      );
      addTearDown(container.dispose);
      container.listen(documentScanControllerProvider, (previous, next) {});

      final notifier = container.read(documentScanControllerProvider.notifier);

      notifier.importDocument('/tmp/annual-report.pdf');
      final taskId = await notifier.upload();

      expect(
        container.read(documentScanControllerProvider).importedDocumentPath,
        '/tmp/annual-report.pdf',
      );
      expect(
        container.read(documentScanControllerProvider).title,
        'annual-report',
      );
      expect(composer.composedPaths, isEmpty);
      expect(repository.uploadedFilePath, '/tmp/annual-report.pdf');
      expect(repository.uploadedTitle, 'annual-report');
      expect(taskId, 'task-123');
    },
  );

  test('scan controller clears a removed page', () async {
    final container = ProviderContainer(
      overrides: [
        appTemporaryFilesProvider.overrideWithValue(temporaryFiles),
        documentScannerProvider.overrideWithValue(_FakeDocumentScanner()),
        documentScanComposerProvider.overrideWithValue(
          _FakeDocumentScanComposer(temporaryFiles),
        ),
        documentsRepositoryProvider.overrideWithValue(
          _FakeDocumentsRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(documentScanControllerProvider, (previous, next) {});

    final notifier = container.read(documentScanControllerProvider.notifier);
    await notifier.scanPages();
    notifier.removePageAt(0);

    expect(container.read(documentScanControllerProvider).pagePaths, [
      '/tmp/page-2.jpg',
    ]);
  });

  test('scan controller deletes the composed pdf after an upload', () async {
    final composer = _FakeDocumentScanComposer(temporaryFiles);
    final container = ProviderContainer(
      overrides: [
        appTemporaryFilesProvider.overrideWithValue(temporaryFiles),
        documentsRepositoryProvider.overrideWithValue(
          _FakeDocumentsRepository(),
        ),
        documentScannerProvider.overrideWithValue(_FakeDocumentScanner()),
        documentScanComposerProvider.overrideWithValue(composer),
      ],
    );
    addTearDown(container.dispose);
    container.listen(documentScanControllerProvider, (previous, next) {});

    final notifier = container.read(documentScanControllerProvider.notifier);
    await notifier.scanPages();
    await notifier.upload();

    expect(composer.composedFilePath, isNotNull);
    expect(File(composer.composedFilePath!).existsSync(), isFalse);
  });

  test(
    'scan controller deletes the composed pdf after a failed upload',
    () async {
      final composer = _FakeDocumentScanComposer(temporaryFiles);
      final container = ProviderContainer(
        overrides: [
          appTemporaryFilesProvider.overrideWithValue(temporaryFiles),
          documentsRepositoryProvider.overrideWithValue(
            _FakeDocumentsRepository(shouldThrowOnUpload: true),
          ),
          documentScannerProvider.overrideWithValue(_FakeDocumentScanner()),
          documentScanComposerProvider.overrideWithValue(composer),
        ],
      );
      addTearDown(container.dispose);
      container.listen(documentScanControllerProvider, (previous, next) {});

      final notifier = container.read(documentScanControllerProvider.notifier);
      await notifier.scanPages();

      await expectLater(notifier.upload(), throwsA(isA<DocumentsFailure>()));
      expect(composer.composedFilePath, isNotNull);
      expect(File(composer.composedFilePath!).existsSync(), isFalse);
      expect(container.read(documentScanControllerProvider).pagePaths, [
        '/tmp/page-1.jpg',
        '/tmp/page-2.jpg',
      ]);
    },
  );

  test(
    'scan controller keeps an imported file outside the temporary folder',
    () async {
      final pickedFile = File('${baseDirectory.path}/picked.pdf');
      await pickedFile.writeAsString('pdf');
      final container = ProviderContainer(
        overrides: [
          appTemporaryFilesProvider.overrideWithValue(temporaryFiles),
          documentsRepositoryProvider.overrideWithValue(
            _FakeDocumentsRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(documentScanControllerProvider, (previous, next) {});

      final notifier = container.read(documentScanControllerProvider.notifier);
      notifier.importDocument(pickedFile.path);
      await notifier.upload();

      expect(pickedFile.existsSync(), isTrue);
    },
  );

  test(
    'scan controller deletes an imported copy inside the temporary folder',
    () async {
      final directory = await temporaryFiles.directory();
      final copiedFile = File('${directory.path}/123-copy.pdf');
      await copiedFile.writeAsString('pdf');
      final container = ProviderContainer(
        overrides: [
          appTemporaryFilesProvider.overrideWithValue(temporaryFiles),
          documentsRepositoryProvider.overrideWithValue(
            _FakeDocumentsRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(documentScanControllerProvider, (previous, next) {});

      final notifier = container.read(documentScanControllerProvider.notifier);
      notifier.importDocument(copiedFile.path);
      await notifier.upload();

      expect(copiedFile.existsSync(), isFalse);
    },
  );
}

class _FakeDocumentsRepository extends DocumentsRepository {
  _FakeDocumentsRepository({this.shouldThrowOnUpload = false})
    : super(
        dio: Dio(),
        session: const PaperlessAuthSession(
          serverUrl: 'https://example.com/paperless/',
          username: 'jane',
          password: 'secret',
          authToken: 'token-123',
        ),
      );

  final bool shouldThrowOnUpload;
  String? uploadedFilePath;
  String? uploadedTitle;

  @override
  Future<String> uploadDocument({
    required String filePath,
    String? title,
  }) async {
    if (shouldThrowOnUpload) {
      throw const DocumentsFailure('Upload failed.');
    }
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
  _FakeDocumentScanComposer(this._temporaryFiles);

  final AppTemporaryFiles _temporaryFiles;
  List<String> composedPaths = <String>[];
  String? composedFilePath;

  @override
  Future<String> composeDocument(List<String> pagePaths) async {
    composedPaths = pagePaths;
    final directory = await _temporaryFiles.directory();
    final file = File('${directory.path}/scan.pdf');
    await file.writeAsString('pdf');
    composedFilePath = file.path;
    return file.path;
  }
}
