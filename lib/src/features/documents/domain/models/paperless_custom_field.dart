enum PaperlessCustomFieldDataType {
  string,
  url,
  date,
  boolean,
  integer,
  float,
  monetary,
  documentLink,
  select,
  longText,
  unknown,
}

class PaperlessCustomFieldSelectOption {
  const PaperlessCustomFieldSelectOption({
    required this.id,
    required this.label,
  });

  factory PaperlessCustomFieldSelectOption.fromJson(Map<String, dynamic> json) {
    return PaperlessCustomFieldSelectOption(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }

  final String id;
  final String label;
}

class PaperlessCustomField {
  const PaperlessCustomField({
    required this.id,
    required this.name,
    required this.dataType,
    this.defaultCurrency,
    this.selectOptions = const <PaperlessCustomFieldSelectOption>[],
  });

  factory PaperlessCustomField.fromJson(Map<String, dynamic> json) {
    final extraData = _asJsonMap(json['extra_data']);
    final options = extraData?['select_options'];

    return PaperlessCustomField(
      id: _asInt(json['id']) ?? 0,
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString().trim()
          : 'Custom field',
      dataType: _customFieldDataTypeFromJson(json['data_type']),
      defaultCurrency: extraData?['default_currency']?.toString(),
      selectOptions: (options is List<dynamic> ? options : const <dynamic>[])
          .whereType<Map>()
          .map(
            (option) => PaperlessCustomFieldSelectOption.fromJson(
              option.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .where((option) => option.id.isNotEmpty)
          .toList(growable: false),
    );
  }

  final int id;
  final String name;
  final PaperlessCustomFieldDataType dataType;
  final String? defaultCurrency;
  final List<PaperlessCustomFieldSelectOption> selectOptions;
}

class PaperlessDocumentCustomField {
  const PaperlessDocumentCustomField({
    required this.field,
    this.document,
    this.created,
    this.value,
  });

  factory PaperlessDocumentCustomField.fromJson(Map<String, dynamic> json) {
    return PaperlessDocumentCustomField(
      field: _asInt(json['field']) ?? 0,
      document: _asInt(json['document']),
      created: json['created']?.toString(),
      value: json['value'],
    );
  }

  final int field;
  final int? document;
  final String? created;
  final Object? value;

  Map<String, Object?> toJson() {
    return <String, Object?>{'field': field, 'value': value};
  }
}

PaperlessCustomFieldDataType _customFieldDataTypeFromJson(Object? value) {
  return switch (value?.toString().toLowerCase()) {
    'string' => PaperlessCustomFieldDataType.string,
    'url' => PaperlessCustomFieldDataType.url,
    'date' => PaperlessCustomFieldDataType.date,
    'boolean' => PaperlessCustomFieldDataType.boolean,
    'integer' => PaperlessCustomFieldDataType.integer,
    'float' => PaperlessCustomFieldDataType.float,
    'monetary' => PaperlessCustomFieldDataType.monetary,
    'documentlink' => PaperlessCustomFieldDataType.documentLink,
    'select' => PaperlessCustomFieldDataType.select,
    'longtext' => PaperlessCustomFieldDataType.longText,
    _ => PaperlessCustomFieldDataType.unknown,
  };
}

Map<String, dynamic>? _asJsonMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  return null;
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value);
  }

  return null;
}
