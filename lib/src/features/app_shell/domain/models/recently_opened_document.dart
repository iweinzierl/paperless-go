import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';

class RecentlyOpenedDocument {
  const RecentlyOpenedDocument({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.openedAt,
  });

  factory RecentlyOpenedDocument.fromJson(Map<String, dynamic> json) {
    return RecentlyOpenedDocument(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Untitled document',
      subtitle: json['subtitle'] as String? ?? '',
      openedAt:
          DateTime.tryParse(json['opened_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'opened_at': openedAt.toIso8601String(),
    };
  }
}
