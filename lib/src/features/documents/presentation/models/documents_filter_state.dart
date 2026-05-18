class DocumentsFilterState {
  const DocumentsFilterState({
    this.tagIds = const <int>[],
    this.correspondentId,
    this.documentTypeId,
    this.createdFrom,
    this.createdTo,
  });

  final List<int> tagIds;
  final int? correspondentId;
  final int? documentTypeId;
  final String? createdFrom;
  final String? createdTo;

  bool get hasActiveFilters =>
      tagIds.isNotEmpty ||
      correspondentId != null ||
      documentTypeId != null ||
      createdFrom != null ||
      createdTo != null;

  DocumentsFilterState copyWith({
    List<int>? tagIds,
    int? correspondentId,
    int? documentTypeId,
    String? createdFrom,
    String? createdTo,
    bool clearTag = false,
    bool clearCorrespondent = false,
    bool clearDocumentType = false,
    bool clearCreatedFrom = false,
    bool clearCreatedTo = false,
  }) {
    return DocumentsFilterState(
      tagIds: clearTag ? const <int>[] : (tagIds ?? this.tagIds),
      correspondentId: clearCorrespondent
          ? null
          : (correspondentId ?? this.correspondentId),
      documentTypeId: clearDocumentType
          ? null
          : (documentTypeId ?? this.documentTypeId),
      createdFrom: clearCreatedFrom ? null : (createdFrom ?? this.createdFrom),
      createdTo: clearCreatedTo ? null : (createdTo ?? this.createdTo),
    );
  }
}
