import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:paperless_ngx_app/l10n/generated/app_localizations.dart';
import 'package:paperless_ngx_app/src/core/theme/app_theme.dart';
import 'package:paperless_ngx_app/src/features/app_shell/domain/models/recently_opened_document.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/pages/recently_opened_page.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('recently opened page shows bordered empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _TestHarness(
        overrides: [
          recentlyOpenedDocumentsProvider.overrideWith(
            () => _FakeRecentlyOpenedDocumentsController(const []),
          ),
        ],
        child: const RecentlyOpenedPage(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Recently opened'), findsOneWidget);
    expect(
      find.text('Documents you open or inspect will appear here.'),
      findsOneWidget,
    );

    final emptyContainer = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.text('Documents you open or inspect will appear here.'),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = emptyContainer.decoration as BoxDecoration;

    expect(decoration.borderRadius, BorderRadius.circular(12));
    expect(decoration.border, isNotNull);
  });

  testWidgets('recently opened page shows bordered document rows', (
    WidgetTester tester,
  ) async {
    final document = RecentlyOpenedDocument(
      id: 99,
      title: 'Rent contract.pdf',
      openedAt: DateTime(2026, 3, 20, 9, 45),
      added: '2026-03-18T10:15:00Z',
      pageCount: 6,
    );

    await tester.pumpWidget(
      _TestHarness(
        overrides: [
          recentlyOpenedDocumentsProvider.overrideWith(
            () => _FakeRecentlyOpenedDocumentsController([document]),
          ),
        ],
        child: const RecentlyOpenedPage(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Rent contract.pdf'), findsOneWidget);
    expect(find.textContaining('Opened 09:45'), findsOneWidget);

    final tileMaterial = tester.widget<Material>(
      find
          .ancestor(
            of: find.text('Rent contract.pdf'),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Material && widget.shape is RoundedRectangleBorder,
            ),
          )
          .first,
    );
    final shape = tileMaterial.shape! as RoundedRectangleBorder;

    expect(shape.borderRadius, BorderRadius.circular(12));
    expect(shape.side.style, BorderStyle.solid);
  });
}

class _TestHarness extends StatelessWidget {
  const _TestHarness({
    required this.child,
    this.overrides = const <Override>[],
  });

  final Widget child;
  final List<Override> overrides;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: buildAppTheme(brightness: Brightness.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }
}

class _FakeRecentlyOpenedDocumentsController
    extends RecentlyOpenedDocumentsController {
  _FakeRecentlyOpenedDocumentsController(this.documents);

  final List<RecentlyOpenedDocument> documents;

  @override
  List<RecentlyOpenedDocument> build() => documents;
}
