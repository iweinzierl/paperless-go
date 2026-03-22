import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/l10n/generated/app_localizations.dart';
import 'package:paperless_ngx_app/src/core/theme/app_theme.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_session.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/pages/login_page.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document_page.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_filter_option.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/document_detail_page.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/documents_page.dart';

const screenshotScenarioPreferenceKey = 'debug.screenshot_scenario';

enum ScreenshotScenario { login, documents, documentDetail }

ScreenshotScenario? maybeParseScreenshotScenario(String? value) {
  return switch (value?.trim()) {
    'login' => ScreenshotScenario.login,
    'documents' => ScreenshotScenario.documents,
    'document_detail' => ScreenshotScenario.documentDetail,
    _ => null,
  };
}

class ScreenshotHarnessApp extends StatelessWidget {
  const ScreenshotHarnessApp({required this.scenario, super.key});

  final ScreenshotScenario scenario;

  @override
  Widget build(BuildContext context) {
    final child = switch (scenario) {
      ScreenshotScenario.login => const LoginPage(),
      ScreenshotScenario.documents => const DocumentsPage(),
      ScreenshotScenario.documentDetail => const DocumentDetailPage(
        documentId: _ScreenshotDocumentsRepository.primaryDocumentId,
      ),
    };

    return ProviderScope(
      overrides: [
        documentsRepositoryProvider.overrideWithValue(
          _ScreenshotDocumentsRepository(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: buildAppTheme(),
        darkTheme: buildAppTheme(brightness: Brightness.dark),
        themeMode: ThemeMode.light,
        home: child,
      ),
    );
  }
}

class _ScreenshotDocumentsRepository extends DocumentsRepository {
  _ScreenshotDocumentsRepository() : super(dio: _dio, session: _session);

  static const primaryDocumentId = 101;

  static final Dio _dio = Dio();
  static const PaperlessAuthSession _session = PaperlessAuthSession(
    serverUrl: 'https://demo.paperless-ngx.local/',
    username: 'demo.user',
    password: 'not-used',
    authToken: 'demo-token',
    displayName: 'Demo User',
  );

  static const List<PaperlessDocument> _documents = <PaperlessDocument>[
    PaperlessDocument(
      id: primaryDocumentId,
      title: 'March electricity bill.pdf',
      created: '2026-03-14',
      added: '2026-03-15T09:30:00Z',
      pageCount: 2,
      correspondentId: 1,
      documentTypeId: 1,
      archiveSerialNumber: 4127,
      originalFileName: 'march-electricity-bill.pdf',
      mimeType: 'application/pdf',
      tags: <int>[1],
      content:
          'Electricity statement for March 2026. Total due 86.40 EUR. Direct debit on 25 March.',
    ),
    PaperlessDocument(
      id: 102,
      title: 'Insurance renewal notice.pdf',
      created: '2026-03-11',
      added: '2026-03-12T14:05:00Z',
      pageCount: 4,
      correspondentId: 2,
      documentTypeId: 2,
      originalFileName: 'insurance-renewal-notice.pdf',
      mimeType: 'application/pdf',
      tags: <int>[2],
    ),
  ];

  static const List<PaperlessFilterOption> _tags = <PaperlessFilterOption>[
    PaperlessFilterOption(id: 1, name: 'Inbox'),
    PaperlessFilterOption(id: 2, name: 'Review'),
  ];
  static const List<PaperlessFilterOption> _correspondents =
      <PaperlessFilterOption>[
        PaperlessFilterOption(id: 1, name: 'City Energy'),
        PaperlessFilterOption(id: 2, name: 'North Shield Insurance'),
      ];
  static const List<PaperlessFilterOption> _documentTypes =
      <PaperlessFilterOption>[
        PaperlessFilterOption(id: 1, name: 'Invoice'),
        PaperlessFilterOption(id: 2, name: 'Letter'),
      ];

  @override
  Future<PaperlessDocumentPage> fetchDocuments({
    int page = 1,
    int pageSize = 20,
    String ordering = '-created',
    String titleFilter = '',
    int? tagId,
    int? correspondentId,
    int? documentTypeId,
  }) async {
    final query = titleFilter.trim().toLowerCase();
    final results = _documents
        .where((document) {
          final matchesTitle =
              query.isEmpty || document.title.toLowerCase().contains(query);
          final matchesTag = tagId == null || document.tags.contains(tagId);
          final matchesCorrespondent =
              correspondentId == null ||
              document.correspondentId == correspondentId;
          final matchesDocumentType =
              documentTypeId == null ||
              document.documentTypeId == documentTypeId;
          return matchesTitle &&
              matchesTag &&
              matchesCorrespondent &&
              matchesDocumentType;
        })
        .toList(growable: false);

    return PaperlessDocumentPage(count: results.length, results: results);
  }

  @override
  Future<List<PaperlessDocument>> fetchRecentUploads() async {
    return _documents;
  }

  @override
  Future<PaperlessDocument> fetchDocument(int documentId) async {
    return _documents.firstWhere((document) => document.id == documentId);
  }

  @override
  Future<List<PaperlessFilterOption>> fetchTagOptions() async => _tags;

  @override
  Future<List<PaperlessFilterOption>> fetchCorrespondentOptions() async {
    return _correspondents;
  }

  @override
  Future<List<PaperlessFilterOption>> fetchDocumentTypeOptions() async {
    return _documentTypes;
  }

  @override
  Uri buildDocumentThumbnailUri(int documentId) {
    return Uri.parse('file:///thumbnail-not-available-$documentId.png');
  }

  @override
  Map<String, String> buildAuthenticatedHeaders() => const <String, String>{};
}
