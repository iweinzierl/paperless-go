import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';

class PaperlessDocumentPage {
  const PaperlessDocumentPage({required this.count, required this.results});

  factory PaperlessDocumentPage.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List<dynamic>? ?? const <dynamic>[];

    return PaperlessDocumentPage(
      count: json['count'] as int? ?? rawResults.length,
      results: rawResults
          .whereType<Map>()
          .map(
            (item) => PaperlessDocument.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(),
    );
  }

  final int count;
  final List<PaperlessDocument> results;
}
