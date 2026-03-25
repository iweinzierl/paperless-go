class PaperlessUserCapabilities {
  const PaperlessUserCapabilities({
    required this.userId,
    required this.groupIds,
    required this.permissionCodenames,
    required this.isStaff,
    required this.isSuperuser,
  });

  factory PaperlessUserCapabilities.fromJson(Map<String, dynamic> json) {
    final user =
        json['user'] as Map<dynamic, dynamic>? ?? const <dynamic, dynamic>{};
    final permissions =
        json['permissions'] as List<dynamic>? ?? const <dynamic>[];

    return PaperlessUserCapabilities(
      userId: user['id'] as int? ?? 0,
      groupIds: (user['groups'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<int>()
          .toList(growable: false),
      permissionCodenames: permissions
          .whereType<String>()
          .map((permission) => permission.trim())
          .where((permission) => permission.isNotEmpty)
          .toSet(),
      isStaff: user['is_staff'] as bool? ?? false,
      isSuperuser: user['is_superuser'] as bool? ?? false,
    );
  }

  final int userId;
  final List<int> groupIds;
  final Set<String> permissionCodenames;
  final bool isStaff;
  final bool isSuperuser;

  bool hasPermission(String codename) {
    return isSuperuser || permissionCodenames.contains(codename);
  }
}
