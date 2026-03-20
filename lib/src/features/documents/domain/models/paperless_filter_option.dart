class PaperlessFilterOption {
  const PaperlessFilterOption({required this.id, required this.name});

  factory PaperlessFilterOption.fromJson(Map<String, dynamic> json) {
    return PaperlessFilterOption(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unnamed',
    );
  }

  final int id;
  final String name;
}
