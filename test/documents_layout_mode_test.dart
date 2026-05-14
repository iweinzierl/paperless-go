import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paperless_ngx_app/src/features/documents/data/local/documents_view_preferences.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/models/documents_layout_mode.dart';

void main() {
  test('reads compact list layout mode from storage', () {
    expect(
      documentsLayoutModeFromStorage('compact_list'),
      equals(DocumentsLayoutMode.compactList),
    );
  });

  test('defaults to card layout mode for unknown values', () {
    expect(
      documentsLayoutModeFromStorage('unexpected'),
      equals(DocumentsLayoutMode.card),
    );
  });

  test('persists compact list layout mode', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final sharedPreferences = await SharedPreferences.getInstance();
    final preferences = DocumentsViewPreferences(sharedPreferences);

    await preferences.saveLayoutMode(DocumentsLayoutMode.compactList);

    expect(
      preferences.readLayoutMode(),
      equals(DocumentsLayoutMode.compactList),
    );
    expect(
      sharedPreferences.getString('documents.layout_mode'),
      equals('compact_list'),
    );
  });
}
