import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_ngx_app/src/features/auth/data/repositories/auth_repository.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';

void main() {
  const requiredEnvKeys = <String>[
    'PAPERLESS_SCREENSHOT_SERVER_URL',
    'PAPERLESS_SCREENSHOT_USERNAME',
    'PAPERLESS_SCREENSHOT_PASSWORD',
  ];
  final missingEnvKeys = requiredEnvKeys
      .where((key) => (Platform.environment[key] ?? '').trim().isEmpty)
      .toList(growable: false);

  test(
    'live screenshot demo server smoke test',
    () async {
      final authRepository = AuthRepository(_buildDio());
      final session = await authRepository.signIn(
        serverUrl: Platform.environment['PAPERLESS_SCREENSHOT_SERVER_URL']!,
        username: Platform.environment['PAPERLESS_SCREENSHOT_USERNAME']!,
        password: Platform.environment['PAPERLESS_SCREENSHOT_PASSWORD']!,
      );

      expect(session.authToken, isNotNull);
      expect(session.authToken, isNotEmpty);
      expect(normalizePaperlessBaseUrl(session.serverUrl), session.serverUrl);

      final documentsRepository = DocumentsRepository(
        dio: _buildDio(),
        session: session,
      );
      final firstPage = await documentsRepository.fetchDocuments(
        ordering: '-added',
      );

      expect(firstPage.results, isNotEmpty);

      final firstDocument = firstPage.results.first;
      final detailedDocument = await documentsRepository.fetchDocument(
        firstDocument.id,
      );
      expect(detailedDocument.id, firstDocument.id);

      final tagOptions = await documentsRepository.fetchTagOptions();
      final correspondentOptions = await documentsRepository
          .fetchCorrespondentOptions();
      final documentTypeOptions = await documentsRepository
          .fetchDocumentTypeOptions();

      expect(tagOptions, isA<List>());
      expect(correspondentOptions, isA<List>());
      expect(documentTypeOptions, isA<List>());
    },
    skip: missingEnvKeys.isEmpty
        ? false
        : 'Missing screenshot env: ${missingEnvKeys.join(', ')}',
  );
}

Dio _buildDio() {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: const <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );
}
