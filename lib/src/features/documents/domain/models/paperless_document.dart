import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_user_capabilities.dart';

class PaperlessDocument {
  const PaperlessDocument({
    required this.id,
    required this.title,
    this.added,
    this.created,
    this.content,
    this.documentTypeId,
    this.correspondentId,
    this.ownerId,
    this.storagePathId,
    this.archiveSerialNumber,
    this.archivedFileName,
    this.mimeType,
    this.originalFileName,
    this.pageCount,
    this.permissions,
    this.userCanChange,
    this.isSharedByRequester,
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
      ownerId: json['owner'] as int?,
      storagePathId: json['storage_path'] as int?,
      archiveSerialNumber: json['archive_serial_number'] as int?,
      archivedFileName: json['archived_file_name'] as String?,
      mimeType: json['mime_type'] as String?,
      originalFileName: json['original_file_name'] as String?,
      pageCount: json['page_count'] as int?,
      permissions: _paperlessPermissionsFromJson(json['permissions']),
      userCanChange: json['user_can_change'] as bool?,
      isSharedByRequester: json['is_shared_by_requester'] as bool?,
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
  final int? ownerId;
  final int? storagePathId;
  final int? archiveSerialNumber;
  final String? archivedFileName;
  final String? mimeType;
  final String? originalFileName;
  final int? pageCount;
  final PaperlessObjectPermissions? permissions;
  final bool? userCanChange;
  final bool? isSharedByRequester;
  final List<int> tags;

  bool canBeChangedBy(PaperlessUserCapabilities capabilities) {
    if (!capabilities.hasPermission('change_document')) {
      return false;
    }

    if (isOwnedBy(capabilities)) {
      return true;
    }

    if (userCanChange == true) {
      return true;
    }

    return permissions?.change.grantsAccess(capabilities) ?? false;
  }

  bool canBeDeletedBy(PaperlessUserCapabilities capabilities) {
    if (!capabilities.hasPermission('delete_document')) {
      return false;
    }

    return capabilities.isSuperuser || ownerId == capabilities.userId;
  }

  bool isOwnedBy(PaperlessUserCapabilities capabilities) {
    return capabilities.isSuperuser ||
        ownerId == null ||
        ownerId == capabilities.userId;
  }

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

class PaperlessObjectPermissions {
  const PaperlessObjectPermissions({required this.view, required this.change});

  factory PaperlessObjectPermissions.fromJson(Map<String, dynamic> json) {
    return PaperlessObjectPermissions(
      view: PaperlessPermissionAssignments.fromJson(
        json['view'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      change: PaperlessPermissionAssignments.fromJson(
        json['change'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
    );
  }

  final PaperlessPermissionAssignments view;
  final PaperlessPermissionAssignments change;
}

class PaperlessPermissionAssignments {
  const PaperlessPermissionAssignments({
    required this.userIds,
    required this.groupIds,
  });

  factory PaperlessPermissionAssignments.fromJson(Map<String, dynamic> json) {
    return PaperlessPermissionAssignments(
      userIds: (json['users'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<int>()
          .toList(growable: false),
      groupIds: (json['groups'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<int>()
          .toList(growable: false),
    );
  }

  final List<int> userIds;
  final List<int> groupIds;

  bool grantsAccess(PaperlessUserCapabilities capabilities) {
    if (userIds.contains(capabilities.userId)) {
      return true;
    }

    for (final groupId in capabilities.groupIds) {
      if (groupIds.contains(groupId)) {
        return true;
      }
    }

    return false;
  }
}

PaperlessObjectPermissions? _paperlessPermissionsFromJson(Object? value) {
  if (value is Map<String, dynamic>) {
    return PaperlessObjectPermissions.fromJson(value);
  }

  if (value is Map) {
    return PaperlessObjectPermissions.fromJson(
      value.map((key, item) => MapEntry(key.toString(), item)),
    );
  }

  return null;
}
