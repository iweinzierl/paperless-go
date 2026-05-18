import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperless_ngx_app/l10n/generated/app_localizations.dart';
import 'package:paperless_ngx_app/src/core/providers/shared_preferences_provider.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_session.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_user_capabilities.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/providers/current_user_capabilities_provider.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_custom_field.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_filter_option.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/document_detail_page.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_detail_provider.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';

void main() {
  const editableCapabilities = PaperlessUserCapabilities(
    userId: 7,
    groupIds: <int>[],
    permissionCodenames: <String>{'change_document', 'delete_document'},
    isStaff: false,
    isSuperuser: false,
  );

  const monetaryDefinition = PaperlessCustomField(
    id: 9,
    name: 'Amount Paid',
    dataType: PaperlessCustomFieldDataType.monetary,
    defaultCurrency: 'EUR',
  );

  const documentWithMonetaryField = PaperlessDocument(
    id: 1,
    title: 'Invoice.pdf',
    created: '2026-03-20',
    added: '2026-03-20T12:00:00Z',
    pageCount: 1,
    ownerId: 7,
    customFields: <PaperlessDocumentCustomField>[
      PaperlessDocumentCustomField(field: 9, value: 'EUR1234.50'),
    ],
  );

  Future<void> pumpDocumentPage(
    WidgetTester tester, {
    required PaperlessDocument document,
    required _CapturingDocumentsRepository repository,
    required List<PaperlessCustomField> customFields,
    bool openEditMetadataOnLoad = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1800);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          documentsRepositoryProvider.overrideWithValue(repository),
          currentUserCapabilitiesProvider.overrideWith(
            (ref) async => editableCapabilities,
          ),
          documentDetailProvider(
            document.id,
          ).overrideWith((ref) async => document),
          customFieldDefinitionsProvider.overrideWith(
            (ref) async => customFields,
          ),
          tagOptionsProvider.overrideWith(
            (ref) async => const <PaperlessFilterOption>[],
          ),
          correspondentOptionsProvider.overrideWith(
            (ref) async => const <PaperlessFilterOption>[],
          ),
          documentTypeOptionsProvider.overrideWith(
            (ref) async => const <PaperlessFilterOption>[],
          ),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DocumentDetailPage(
            documentId: document.id,
            openEditMetadataOnLoad: openEditMetadataOnLoad,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  Future<void> pumpUntilFound(
    WidgetTester tester,
    Finder finder, {
    int maxPumps = 20,
  }) async {
    for (var index = 0; index < maxPumps; index++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }

    expect(finder, findsWidgets);
  }

  Finder textFieldWithHint(String hintText) {
    return find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == hintText,
    );
  }

  Finder textContaining(String value) {
    return find.byWidgetPredicate(
      (widget) => widget is Text && (widget.data?.contains(value) ?? false),
    );
  }

  testWidgets('formats monetary custom field values using the active locale', (
    WidgetTester tester,
  ) async {
    final repository = _CapturingDocumentsRepository();

    await pumpDocumentPage(
      tester,
      document: documentWithMonetaryField,
      repository: repository,
      customFields: const <PaperlessCustomField>[monetaryDefinition],
    );

    await pumpUntilFound(tester, textContaining('EUR 1.234,50'));

    expect(textContaining('EUR 1.234,50'), findsOneWidget);
  });

  testWidgets('saves split monetary editor values as one API payload field', (
    WidgetTester tester,
  ) async {
    final repository = _CapturingDocumentsRepository();

    await pumpDocumentPage(
      tester,
      document: documentWithMonetaryField,
      repository: repository,
      customFields: const <PaperlessCustomField>[monetaryDefinition],
      openEditMetadataOnLoad: true,
    );

    final currencyField = textFieldWithHint('EUR');
    final amountField = textFieldWithHint('11.10');

    await pumpUntilFound(tester, currencyField);
    await pumpUntilFound(tester, amountField);

    expect(
      find.descendant(of: amountField, matching: find.text('1.234,50')),
      findsOneWidget,
    );

    await tester.enterText(currencyField, 'CHF');
    await tester.pump();
    await tester.enterText(amountField, '9.876,50');
    await tester.pump();

    await tester.tap(find.widgetWithText(TextButton, 'Speichern'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.savedCustomFields, isNotNull);
    expect(repository.savedCustomFields, hasLength(1));
    expect(repository.savedCustomFields!.single.field, 9);
    expect(repository.savedCustomFields!.single.value, 'CHF9876.50');
  });
}

class _CapturingDocumentsRepository extends DocumentsRepository {
  _CapturingDocumentsRepository()
    : super(
        dio: Dio(),
        session: const PaperlessAuthSession(
          serverUrl: 'https://example.com/paperless/',
          username: 'jane.doe',
          password: 'secret',
          authToken: 'token-123',
        ),
      );

  List<PaperlessDocumentCustomField>? savedCustomFields;

  @override
  Future<List<PaperlessFilterOption>> fetchTagOptions() async {
    return const <PaperlessFilterOption>[];
  }

  @override
  Future<List<PaperlessFilterOption>> fetchCorrespondentOptions() async {
    return const <PaperlessFilterOption>[];
  }

  @override
  Future<List<PaperlessFilterOption>> fetchDocumentTypeOptions() async {
    return const <PaperlessFilterOption>[];
  }

  @override
  Widget? buildDocumentThumbnailWidget(PaperlessDocument document) {
    return const SizedBox.shrink();
  }

  @override
  Future<PaperlessDocument> updateDocumentMetadata({
    required int documentId,
    required String title,
    String? created,
    int? correspondentId,
    int? documentTypeId,
    int? storagePathId,
    required List<int> tagIds,
    List<PaperlessDocumentCustomField>? customFields,
  }) async {
    savedCustomFields = customFields;
    return PaperlessDocument(
      id: documentId,
      title: title,
      created: created,
      correspondentId: correspondentId,
      documentTypeId: documentTypeId,
      storagePathId: storagePathId,
      tags: tagIds,
      customFields: customFields ?? const <PaperlessDocumentCustomField>[],
      ownerId: 7,
    );
  }
}
