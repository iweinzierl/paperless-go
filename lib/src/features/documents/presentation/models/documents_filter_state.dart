class DocumentsFilterState {
  const DocumentsFilterState({
    this.tagIds = const <int>[],
    this.correspondentId,
    this.documentTypeId,
  });

  final List<int> tagIds;
  final int? correspondentId;
  final int? documentTypeId;

  bool get hasActiveFilters =>
      tagIds.isNotEmpty || correspondentId != null || documentTypeId != null;

  DocumentsFilterState copyWith({
    List<int>? tagIds,
    int? correspondentId,
    int? documentTypeId,
    bool clearTag = false,
    bool clearCorrespondent = false,
    bool clearDocumentType = false,
  }) {
    return DocumentsFilterState(
      tagIds: clearTag ? const <int>[] : (tagIds ?? this.tagIds),
      correspondentId: clearCorrespondent
          ? null
          : (correspondentId ?? this.correspondentId),
      documentTypeId: clearDocumentType
          ? null
          : (documentTypeId ?? this.documentTypeId),
    );
  }
}
