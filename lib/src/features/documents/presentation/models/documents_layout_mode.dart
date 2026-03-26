enum DocumentsLayoutMode { card, list }

DocumentsLayoutMode documentsLayoutModeFromStorage(String? value) {
  return switch (value) {
    'list' => DocumentsLayoutMode.list,
    _ => DocumentsLayoutMode.card,
  };
}

extension DocumentsLayoutModeStorage on DocumentsLayoutMode {
  String get storageValue => switch (this) {
    DocumentsLayoutMode.card => 'card',
    DocumentsLayoutMode.list => 'list',
  };
}
