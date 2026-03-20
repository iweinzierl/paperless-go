class DocumentsSortOption {
  const DocumentsSortOption({required this.label, required this.ordering});

  final String label;
  final String ordering;
}

const documentsSortOptions = <DocumentsSortOption>[
  DocumentsSortOption(
    label: 'Created date (newest first)',
    ordering: '-created',
  ),
  DocumentsSortOption(
    label: 'Created date (oldest first)',
    ordering: 'created',
  ),
  DocumentsSortOption(label: 'Added date (newest first)', ordering: '-added'),
  DocumentsSortOption(label: 'Added date (oldest first)', ordering: 'added'),
  DocumentsSortOption(label: 'Title (A-Z)', ordering: 'title'),
  DocumentsSortOption(label: 'Title (Z-A)', ordering: '-title'),
];
