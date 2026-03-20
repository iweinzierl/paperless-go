import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_ngx_app/src/features/auth/data/repositories/auth_repository.dart';

void main() {
  group('normalizePaperlessBaseUrl', () {
    test('keeps a server subpath intact', () {
      final normalized = normalizePaperlessBaseUrl(
        'https://example.com/paperless',
      );

      expect(normalized, 'https://example.com/paperless/');
      expect(
        buildPaperlessApiBaseUri(normalized).toString(),
        'https://example.com/paperless/api/',
      );
    });

    test('accepts a URL that already points to /api', () {
      final normalized = normalizePaperlessBaseUrl(
        'https://example.com/paperless/api/',
      );

      expect(normalized, 'https://example.com/paperless/');
      expect(
        buildPaperlessApiBaseUri(normalized).toString(),
        'https://example.com/paperless/api/',
      );
    });
  });
}
