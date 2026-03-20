import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';

class RecentlyOpenedDocument {
  const RecentlyOpenedDocument({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.openedAt,
  });

  factory RecentlyOpenedDocument.fromDocument(
    PaperlessDocument document, {
    DateTime? openedAt,
  }) {
    return RecentlyOpenedDocument(
      id: document.id,
      title: document.title,
      subtitle: document.subtitle,
      openedAt: openedAt ?? DateTime.now(),
    );
  }

  final int id;
  final String title;
  final String subtitle;
  final DateTime openedAt;
}
