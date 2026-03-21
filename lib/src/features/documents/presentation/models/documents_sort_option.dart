import 'package:paperless_ngx_app/l10n/generated/app_localizations.dart';

class DocumentsSortOption {
  const DocumentsSortOption({required this.ordering});

  final String ordering;
}

const documentsSortOptions = <DocumentsSortOption>[
  DocumentsSortOption(ordering: '-created'),
  DocumentsSortOption(ordering: 'created'),
  DocumentsSortOption(ordering: '-added'),
  DocumentsSortOption(ordering: 'added'),
  DocumentsSortOption(ordering: 'title'),
  DocumentsSortOption(ordering: '-title'),
];

String documentSortOptionLabel(AppLocalizations l10n, String ordering) {
  switch (ordering) {
    case '-created':
      return l10n.sortCreatedNewest;
    case 'created':
      return l10n.sortCreatedOldest;
    case '-added':
      return l10n.sortAddedNewest;
    case 'added':
      return l10n.sortAddedOldest;
    case 'title':
      return l10n.sortTitleAz;
    case '-title':
      return l10n.sortTitleZa;
  }

  return ordering;
}
