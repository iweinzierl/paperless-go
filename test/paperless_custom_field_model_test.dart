import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_custom_field.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';

void main() {
  test('parses custom field definition with select options', () {
    final parsed = PaperlessCustomField.fromJson(<String, dynamic>{
      'id': 12,
      'name': 'Category',
      'data_type': 'select',
      'extra_data': <String, dynamic>{
        'select_options': <Map<String, dynamic>>[
          <String, dynamic>{'id': 'a1', 'label': 'Invoice'},
          <String, dynamic>{'id': 'b2', 'label': 'Contract'},
        ],
      },
    });

    expect(parsed.id, 12);
    expect(parsed.name, 'Category');
    expect(parsed.dataType, PaperlessCustomFieldDataType.select);
    expect(parsed.selectOptions.map((item) => item.id), <String>['a1', 'b2']);
  });

  test('parses document custom fields from document payload', () {
    final parsed = PaperlessDocument.fromJson(<String, dynamic>{
      'id': 88,
      'title': 'Doc',
      'custom_fields': <Map<String, dynamic>>[
        <String, dynamic>{
          'field': 5,
          'document': 88,
          'created': '2026-01-01T10:00:00Z',
          'value': 'ABC-123',
        },
        <String, dynamic>{
          'field': 6,
          'document': 88,
          'created': '2026-01-01T10:00:00Z',
          'value': true,
        },
      ],
    });

    expect(parsed.customFields.length, 2);
    expect(parsed.customFields.first.field, 5);
    expect(parsed.customFields.first.value, 'ABC-123');
    expect(parsed.customFields.last.field, 6);
    expect(parsed.customFields.last.value, true);
  });

  test('serializes document custom field patch payload', () {
    const field = PaperlessDocumentCustomField(field: 22, value: 'foo');

    expect(field.toJson(), <String, Object?>{'field': 22, 'value': 'foo'});
  });
}
