class DocumentsFilterState {
  const DocumentsFilterState({
    this.tagId,
    this.correspondentId,
    this.documentTypeId,
  });

  final int? tagId;
  final int? correspondentId;
  final int? documentTypeId;

  bool get hasActiveFilters =>
      tagId != null || correspondentId != null || documentTypeId != null;

  DocumentsFilterState copyWith({
    int? tagId,
    int? correspondentId,
    int? documentTypeId,
    bool clearTag = false,
    bool clearCorrespondent = false,
    bool clearDocumentType = false,
  }) {
    return DocumentsFilterState(
      tagId: clearTag ? null : (tagId ?? this.tagId),
      correspondentId: clearCorrespondent
          ? null
          : (correspondentId ?? this.correspondentId),
      documentTypeId: clearDocumentType
          ? null
          : (documentTypeId ?? this.documentTypeId),
    );
  }
}
