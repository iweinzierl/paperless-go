import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_ngx_app/src/features/documents/data/query/paperless_saved_view_query_parameters.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_saved_view.dart';

void main() {
  group('queryParametersFromSavedViewFilterRules', () {
    test(
      'maps legacy text and multi-value rules to document query parameters',
      () {
        final parameters = queryParametersFromSavedViewFilterRules([
          const PaperlessSavedViewFilterRule(ruleType: 19, value: 'invoice'),
          const PaperlessSavedViewFilterRule(ruleType: 6, value: '12'),
          const PaperlessSavedViewFilterRule(ruleType: 6, value: '99'),
        ]);

        expect(parameters['text'], 'invoice');
        expect(parameters['tags__id__all'], '12,99');
      },
    );

    test('maps null and boolean rules using Paperless null semantics', () {
      final parameters = queryParametersFromSavedViewFilterRules([
        const PaperlessSavedViewFilterRule(ruleType: 3, value: null),
        const PaperlessSavedViewFilterRule(ruleType: 7, value: 'false'),
      ]);

      expect(parameters['correspondent__isnull'], '1');
      expect(parameters['is_tagged'], '0');
    });

    test('transforms legacy custom field rules into a custom field query', () {
      final transformed = transformLegacySavedViewFilterRules([
        const PaperlessSavedViewFilterRule(ruleType: 39, value: '7'),
        const PaperlessSavedViewFilterRule(ruleType: 39, value: '8'),
      ]);

      expect(transformed, hasLength(1));
      expect(transformed.single.ruleType, 42);
      expect(
        transformed.single.value,
        '["OR",[[7,"exists",true],[8,"exists",true]]]',
      );
    });
  });
}
