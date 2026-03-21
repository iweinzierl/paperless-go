class PaperlessDocument {
  const PaperlessDocument({
    required this.id,
    required this.title,
    this.added,
    this.created,
    this.content,
    this.documentTypeId,
    this.correspondentId,
    this.storagePathId,
    this.archiveSerialNumber,
    this.archivedFileName,
    this.mimeType,
    this.originalFileName,
    this.pageCount,
    this.tags = const <int>[],
  });

  factory PaperlessDocument.fromJson(Map<String, dynamic> json) {
    return PaperlessDocument(
      id: json['id'] as int? ?? 0,
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? json['title'] as String
          : 'Untitled document',
      added: json['added'] as String?,
      created: json['created'] as String?,
      content: json['content'] as String?,
      documentTypeId: json['document_type'] as int?,
      correspondentId: json['correspondent'] as int?,
      storagePathId: json['storage_path'] as int?,
      archiveSerialNumber: json['archive_serial_number'] as int?,
      archivedFileName: json['archived_file_name'] as String?,
      mimeType: json['mime_type'] as String?,
      originalFileName: json['original_file_name'] as String?,
      pageCount: json['page_count'] as int?,
      tags: (json['tags'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<int>()
          .toList(),
    );
  }

  final int id;
  final String title;
  final String? added;
  final String? created;
  final String? content;
  final int? documentTypeId;
  final int? correspondentId;
  final int? storagePathId;
  final int? archiveSerialNumber;
  final String? archivedFileName;
  final String? mimeType;
  final String? originalFileName;
  final int? pageCount;
  final List<int> tags;

  String get preferredFileName {
    final candidates = <String?>[originalFileName, archivedFileName, title];

    for (final candidate in candidates) {
      final trimmed = candidate?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }

    return 'document-$id';
  }
}
