enum DocumentsLayoutMode { card, list, compactList }

DocumentsLayoutMode documentsLayoutModeFromStorage(String? value) {
  return switch (value) {
    'list' => DocumentsLayoutMode.list,
    'compact_list' => DocumentsLayoutMode.compactList,
    _ => DocumentsLayoutMode.card,
  };
}

extension DocumentsLayoutModeStorage on DocumentsLayoutMode {
  String get storageValue => switch (this) {
    DocumentsLayoutMode.card => 'card',
    DocumentsLayoutMode.list => 'list',
    DocumentsLayoutMode.compactList => 'compact_list',
  };
}
