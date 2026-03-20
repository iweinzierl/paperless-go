class PaperlessUserProfile {
  const PaperlessUserProfile({
    required this.username,
    this.firstName,
    this.lastName,
    this.email,
  });

  factory PaperlessUserProfile.fromJson(Map<String, dynamic> json) {
    return PaperlessUserProfile(
      username: json['username'] as String? ?? '',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
    );
  }

  final String username;
  final String? firstName;
  final String? lastName;
  final String? email;

  String get displayName {
    final fullName = [firstName, lastName]
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .join(' ')
        .trim();

    if (fullName.isNotEmpty) {
      return fullName;
    }

    return username;
  }
}
