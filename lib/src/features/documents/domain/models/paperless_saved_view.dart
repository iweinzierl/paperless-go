class PaperlessSavedViewFilterRule {
  const PaperlessSavedViewFilterRule({
    required this.ruleType,
    required this.value,
  });

  factory PaperlessSavedViewFilterRule.fromJson(Map<String, dynamic> json) {
    return PaperlessSavedViewFilterRule(
      ruleType: json['rule_type'] as int? ?? 0,
      value: json['value']?.toString(),
    );
  }

  final int ruleType;
  final String? value;
}

class PaperlessSavedView {
  const PaperlessSavedView({
    required this.id,
    required this.name,
    required this.sortField,
    required this.sortReverse,
    required this.filterRules,
    this.pageSize,
  });

  factory PaperlessSavedView.fromJson(Map<String, dynamic> json) {
    final rawFilterRules =
        json['filter_rules'] as List<dynamic>? ?? const <dynamic>[];

    return PaperlessSavedView(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unnamed',
      sortField: json['sort_field'] as String? ?? 'created',
      sortReverse: json['sort_reverse'] as bool? ?? false,
      filterRules: rawFilterRules
          .whereType<Map>()
          .map(
            (item) => PaperlessSavedViewFilterRule.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(growable: false),
      pageSize: json['page_size'] as int?,
    );
  }

  final int id;
  final String name;
  final String sortField;
  final bool sortReverse;
  final List<PaperlessSavedViewFilterRule> filterRules;
  final int? pageSize;
}
