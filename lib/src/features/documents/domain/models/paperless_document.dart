class PaperlessDocument {
  const PaperlessDocument({
    required this.id,
    required this.title,
    this.added,
    this.created,
    this.documentTypeId,
    this.correspondentId,
    this.storagePathId,
    this.archiveSerialNumber,
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
      documentTypeId: json['document_type'] as int?,
      correspondentId: json['correspondent'] as int?,
      storagePathId: json['storage_path'] as int?,
      archiveSerialNumber: json['archive_serial_number'] as int?,
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
  final int? documentTypeId;
  final int? correspondentId;
  final int? storagePathId;
  final int? archiveSerialNumber;
  final String? originalFileName;
  final int? pageCount;
  final List<int> tags;

  String get subtitle {
    final parts = <String>[];

    if (created != null && created!.isNotEmpty) {
      parts.add(_shortDate(created!));
    }
    if (pageCount != null) {
      parts.add('$pageCount page${pageCount == 1 ? '' : 's'}');
    }
    if (archiveSerialNumber != null) {
      parts.add('ASN $archiveSerialNumber');
    }

    return parts.isEmpty ? 'Document #$id' : parts.join(' · ');
  }

  static String _shortDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }

    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');

    return '${parsed.year}-$month-$day';
  }
}
