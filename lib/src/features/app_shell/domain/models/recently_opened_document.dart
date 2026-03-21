import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';

class RecentlyOpenedDocument {
  const RecentlyOpenedDocument({
    required this.id,
    required this.title,
    required this.openedAt,
    this.added,
    this.created,
    this.pageCount,
    this.archiveSerialNumber,
    this.legacySubtitle,
  });

  factory RecentlyOpenedDocument.fromJson(Map<String, dynamic> json) {
    return RecentlyOpenedDocument(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Untitled document',
      openedAt:
          DateTime.tryParse(json['opened_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      added: json['added'] as String?,
      created: json['created'] as String?,
      pageCount: json['page_count'] as int?,
      archiveSerialNumber: json['archive_serial_number'] as int?,
      legacySubtitle: json['subtitle'] as String?,
    );
  }

  factory RecentlyOpenedDocument.fromDocument(
    PaperlessDocument document, {
    DateTime? openedAt,
  }) {
    return RecentlyOpenedDocument(
      id: document.id,
      title: document.title,
      openedAt: openedAt ?? DateTime.now(),
      added: document.added,
      created: document.created,
      pageCount: document.pageCount,
      archiveSerialNumber: document.archiveSerialNumber,
    );
  }

  final int id;
  final String title;
  final DateTime openedAt;
  final String? added;
  final String? created;
  final int? pageCount;
  final int? archiveSerialNumber;
  final String? legacySubtitle;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'opened_at': openedAt.toIso8601String(),
      'added': added,
      'created': created,
      'page_count': pageCount,
      'archive_serial_number': archiveSerialNumber,
      if (legacySubtitle != null) 'subtitle': legacySubtitle,
    };
  }
}
