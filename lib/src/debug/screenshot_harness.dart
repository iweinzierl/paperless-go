import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/l10n/generated/app_localizations.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_behavior_providers.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/pages/settings_page.dart';
import 'package:paperless_ngx_app/src/core/theme/app_theme.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_session.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/pages/login_page.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document_page.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_filter_option.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/document_detail_page.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/documents_page.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:paperless_ngx_app/src/features/home/presentation/pages/home_page.dart';

const screenshotScenarioPreferenceKey = 'debug.screenshot_scenario';

enum ScreenshotScenario {
  login,
  home,
  documents,
  documentsDrawer,
  documentDetail,
  settings,
}

ScreenshotScenario? maybeParseScreenshotScenario(String? value) {
  return switch (value?.trim()) {
    'login' => ScreenshotScenario.login,
    'home' => ScreenshotScenario.home,
    'documents' => ScreenshotScenario.documents,
    'documents_drawer' => ScreenshotScenario.documentsDrawer,
    'document_detail' => ScreenshotScenario.documentDetail,
    'settings' => ScreenshotScenario.settings,
    _ => null,
  };
}

class ScreenshotHarnessApp extends ConsumerWidget {
  const ScreenshotHarnessApp({required this.scenario, super.key});

  final ScreenshotScenario scenario;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLanguageLocale = ref
        .watch(appBehaviorSettingsProvider)
        .appLanguage
        .locale;
    final child = switch (scenario) {
      ScreenshotScenario.login => const LoginPage(),
      ScreenshotScenario.home => const HomePage(),
      ScreenshotScenario.documents => const DocumentsPage(),
      ScreenshotScenario.documentsDrawer => const DocumentsPage(
        openDrawerOnLoad: true,
      ),
      ScreenshotScenario.documentDetail => const DocumentDetailPage(
        documentId: ScreenshotDocumentsRepository.primaryDocumentId,
      ),
      ScreenshotScenario.settings => const SettingsPage(),
    };

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: appLanguageLocale,
      theme: buildAppTheme(),
      darkTheme: buildAppTheme(brightness: Brightness.dark),
      themeMode: ThemeMode.light,
      home: child,
    );
  }
}

class ScreenshotDocumentsRepository extends DocumentsRepository {
  ScreenshotDocumentsRepository({String languageCode = 'en'})
    : _fixture = _ScreenshotFixture.forLanguage(languageCode),
      super(dio: _dio, session: _session);

  static const primaryDocumentId = 101;

  static final Dio _dio = Dio();
  static const PaperlessAuthSession _session = PaperlessAuthSession(
    serverUrl: 'https://demo.paperless-ngx.local/',
    username: 'demo.user',
    password: 'not-used',
    authToken: 'demo-token',
    displayName: 'Demo User',
  );

  final _ScreenshotFixture _fixture;

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
    final query = titleFilter.trim().toLowerCase();
    final results = _fixture.documents
        .where((document) {
          final matchesTitle =
              query.isEmpty || document.title.toLowerCase().contains(query);
          final matchesTag =
              tagIds.isEmpty || tagIds.every(document.tags.contains);
          final hasInboxTag = document.tags.any(_fixture.inboxTagIds.contains);
          final matchesInbox = isInInbox == null || hasInboxTag == isInInbox;
          final matchesCorrespondent =
              correspondentId == null ||
              document.correspondentId == correspondentId;
          final matchesDocumentType =
              documentTypeId == null ||
              document.documentTypeId == documentTypeId;
          return matchesTitle &&
              matchesTag &&
              matchesInbox &&
              matchesCorrespondent &&
              matchesDocumentType;
        })
        .toList(growable: false);

    return PaperlessDocumentPage(count: results.length, results: results);
  }

  @override
  Future<List<PaperlessDocument>> fetchRecentUploads() async {
    return _fixture.documents;
  }

  @override
  Future<PaperlessDocument> fetchDocument(int documentId) async {
    return _fixture.documents.firstWhere(
      (document) => document.id == documentId,
    );
  }

  @override
  Future<List<PaperlessFilterOption>> fetchTagOptions() async => _fixture.tags;

  @override
  Future<List<PaperlessFilterOption>> fetchCorrespondentOptions() async {
    return _fixture.correspondents;
  }

  @override
  Future<List<PaperlessFilterOption>> fetchDocumentTypeOptions() async {
    return _fixture.documentTypes;
  }

  @override
  Uri buildDocumentThumbnailUri(int documentId) {
    return Uri.parse('file:///thumbnail-not-available-$documentId.png');
  }

  @override
  ImageProvider<Object>? buildDocumentThumbnailImageProvider(int documentId) {
    return null;
  }

  @override
  Widget? buildDocumentThumbnailWidget(PaperlessDocument document) {
    return _MockBillThumbnail(document: document);
  }

  @override
  Map<String, String> buildAuthenticatedHeaders() => const <String, String>{};
}

class _MockBillThumbnail extends StatelessWidget {
  const _MockBillThumbnail({required this.document});

  final PaperlessDocument document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8F4EB), Color(0xFFF0F4F8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 300,
              height: 160,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        width: 26,
                        height: 26,
                        child: Container(
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.receipt_long,
                            color: accent,
                            size: 15,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 36,
                        right: 0,
                        top: 1,
                        child: Text(
                          document.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: const Color(0xFF1F2937),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 36,
                        top: 22,
                        child: Text(
                          'Utility statement',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 48,
                        child: Container(
                          height: 1,
                          color: const Color(0xFFE5E7EB),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 60,
                        right: 118,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            _BillPlaceholderLine(width: 116),
                            SizedBox(height: 8),
                            _BillPlaceholderLine(width: 136),
                            SizedBox(height: 8),
                            _BillPlaceholderLine(width: 128),
                            SizedBox(height: 8),
                            _BillPlaceholderLine(width: 92),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 60,
                        width: 104,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Amount due',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _amountForDocument(document.id),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: const Color(0xFF111827),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                height: 1,
                                color: const Color(0xFFD7DEE5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Auto debit',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF111827), Color(0xFF374151)],
                            ),
                          ),
                          child: CustomPaint(painter: _BarcodePainter()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _amountForDocument(int documentId) {
    return switch (documentId) {
      ScreenshotDocumentsRepository.primaryDocumentId => 'EUR 86.40',
      _ => 'EUR 214.10',
    };
  }
}

class _BillPlaceholderLine extends StatelessWidget {
  const _BillPlaceholderLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 7,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final whitePaint = Paint()..color = Colors.white;
    final bars = <double>[3, 1, 2, 4, 1, 3, 2, 1, 4, 2, 1, 3, 1, 2, 4, 1, 3];
    var x = 18.0;

    for (final bar in bars) {
      canvas.drawRect(
        Rect.fromLTWH(x, 6, bar * 2, size.height - 12),
        whitePaint,
      );
      x += (bar * 2) + 4;
      if (x >= size.width - 18) {
        break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScreenshotFixture {
  const _ScreenshotFixture({
    required this.documents,
    required this.tags,
    required this.inboxTagIds,
    required this.correspondents,
    required this.documentTypes,
  });

  final List<PaperlessDocument> documents;
  final List<PaperlessFilterOption> tags;
  final Set<int> inboxTagIds;
  final List<PaperlessFilterOption> correspondents;
  final List<PaperlessFilterOption> documentTypes;

  static _ScreenshotFixture forLanguage(String languageCode) {
    return switch (languageCode.toLowerCase()) {
      'de' => _de,
      'es' => _es,
      'fr' => _fr,
      'it' => _it,
      _ => _en,
    };
  }

  static final _en = _ScreenshotFixture(
    documents: <PaperlessDocument>[
      PaperlessDocument(
        id: ScreenshotDocumentsRepository.primaryDocumentId,
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
    ],
    tags: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Inbox'),
      PaperlessFilterOption(id: 2, name: 'Review'),
    ],
    inboxTagIds: <int>{1},
    correspondents: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'City Energy'),
      PaperlessFilterOption(id: 2, name: 'North Shield Insurance'),
    ],
    documentTypes: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Invoice'),
      PaperlessFilterOption(id: 2, name: 'Letter'),
    ],
  );

  static final _de = _ScreenshotFixture(
    documents: <PaperlessDocument>[
      PaperlessDocument(
        id: ScreenshotDocumentsRepository.primaryDocumentId,
        title: 'Stromrechnung Maerz.pdf',
        created: '2026-03-14',
        added: '2026-03-15T09:30:00Z',
        pageCount: 2,
        correspondentId: 1,
        documentTypeId: 1,
        archiveSerialNumber: 4127,
        originalFileName: 'stromrechnung-maerz.pdf',
        mimeType: 'application/pdf',
        tags: <int>[1],
        content:
            'Stromabrechnung fuer Maerz 2026. Gesamtbetrag 86.40 EUR. Lastschrift am 25. Maerz.',
      ),
      PaperlessDocument(
        id: 102,
        title: 'Versicherungsverlaengerung.pdf',
        created: '2026-03-11',
        added: '2026-03-12T14:05:00Z',
        pageCount: 4,
        correspondentId: 2,
        documentTypeId: 2,
        originalFileName: 'versicherungsverlaengerung.pdf',
        mimeType: 'application/pdf',
        tags: <int>[2],
      ),
    ],
    tags: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Eingang'),
      PaperlessFilterOption(id: 2, name: 'Pruefen'),
    ],
    inboxTagIds: <int>{1},
    correspondents: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Stadtwerke'),
      PaperlessFilterOption(id: 2, name: 'Nordschutz Versicherung'),
    ],
    documentTypes: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Rechnung'),
      PaperlessFilterOption(id: 2, name: 'Brief'),
    ],
  );

  static final _es = _ScreenshotFixture(
    documents: <PaperlessDocument>[
      PaperlessDocument(
        id: ScreenshotDocumentsRepository.primaryDocumentId,
        title: 'Factura de electricidad marzo.pdf',
        created: '2026-03-14',
        added: '2026-03-15T09:30:00Z',
        pageCount: 2,
        correspondentId: 1,
        documentTypeId: 1,
        archiveSerialNumber: 4127,
        originalFileName: 'factura-electricidad-marzo.pdf',
        mimeType: 'application/pdf',
        tags: <int>[1],
        content:
            'Factura de electricidad de marzo de 2026. Importe total 86.40 EUR. Cargo domiciliado el 25 de marzo.',
      ),
      PaperlessDocument(
        id: 102,
        title: 'Aviso de renovacion del seguro.pdf',
        created: '2026-03-11',
        added: '2026-03-12T14:05:00Z',
        pageCount: 4,
        correspondentId: 2,
        documentTypeId: 2,
        originalFileName: 'renovacion-seguro.pdf',
        mimeType: 'application/pdf',
        tags: <int>[2],
      ),
    ],
    tags: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Entrada'),
      PaperlessFilterOption(id: 2, name: 'Revisar'),
    ],
    inboxTagIds: <int>{1},
    correspondents: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Energia Urbana'),
      PaperlessFilterOption(id: 2, name: 'Seguro Escudo Norte'),
    ],
    documentTypes: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Factura'),
      PaperlessFilterOption(id: 2, name: 'Carta'),
    ],
  );

  static final _fr = _ScreenshotFixture(
    documents: <PaperlessDocument>[
      PaperlessDocument(
        id: ScreenshotDocumentsRepository.primaryDocumentId,
        title: 'Facture electricite mars.pdf',
        created: '2026-03-14',
        added: '2026-03-15T09:30:00Z',
        pageCount: 2,
        correspondentId: 1,
        documentTypeId: 1,
        archiveSerialNumber: 4127,
        originalFileName: 'facture-electricite-mars.pdf',
        mimeType: 'application/pdf',
        tags: <int>[1],
        content:
            'Facture d electricite de mars 2026. Montant total 86.40 EUR. Prelevement le 25 mars.',
      ),
      PaperlessDocument(
        id: 102,
        title: 'Avis de renouvellement assurance.pdf',
        created: '2026-03-11',
        added: '2026-03-12T14:05:00Z',
        pageCount: 4,
        correspondentId: 2,
        documentTypeId: 2,
        originalFileName: 'renouvellement-assurance.pdf',
        mimeType: 'application/pdf',
        tags: <int>[2],
      ),
    ],
    tags: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Boite de reception'),
      PaperlessFilterOption(id: 2, name: 'A verifier'),
    ],
    inboxTagIds: <int>{1},
    correspondents: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Energie Urbaine'),
      PaperlessFilterOption(id: 2, name: 'North Shield Assurance'),
    ],
    documentTypes: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Facture'),
      PaperlessFilterOption(id: 2, name: 'Lettre'),
    ],
  );

  static final _it = _ScreenshotFixture(
    documents: <PaperlessDocument>[
      PaperlessDocument(
        id: ScreenshotDocumentsRepository.primaryDocumentId,
        title: 'Bolletta elettrica marzo.pdf',
        created: '2026-03-14',
        added: '2026-03-15T09:30:00Z',
        pageCount: 2,
        correspondentId: 1,
        documentTypeId: 1,
        archiveSerialNumber: 4127,
        originalFileName: 'bolletta-elettrica-marzo.pdf',
        mimeType: 'application/pdf',
        tags: <int>[1],
        content:
            'Bolletta elettrica di marzo 2026. Totale dovuto 86.40 EUR. Addebito il 25 marzo.',
      ),
      PaperlessDocument(
        id: 102,
        title: 'Avviso rinnovo assicurazione.pdf',
        created: '2026-03-11',
        added: '2026-03-12T14:05:00Z',
        pageCount: 4,
        correspondentId: 2,
        documentTypeId: 2,
        originalFileName: 'rinnovo-assicurazione.pdf',
        mimeType: 'application/pdf',
        tags: <int>[2],
      ),
    ],
    tags: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Posta in arrivo'),
      PaperlessFilterOption(id: 2, name: 'Da rivedere'),
    ],
    inboxTagIds: <int>{1},
    correspondents: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Energia Cittadina'),
      PaperlessFilterOption(id: 2, name: 'North Shield Assicurazioni'),
    ],
    documentTypes: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Fattura'),
      PaperlessFilterOption(id: 2, name: 'Lettera'),
    ],
  );
}
