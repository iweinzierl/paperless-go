import 'package:paperless_ngx_app/l10n/generated/app_localizations.dart';

import 'package:paperless_ngx_app/src/core/presentation/formatters/timestamp_text.dart';

String formatDocumentSubtitle({
  required AppLocalizations l10n,
  required String localeName,
  required int id,
  String? added,
  String? created,
  int? pageCount,
  int? archiveSerialNumber,
}) {
  final parts = <String>[];

  final trimmedAdded = added?.trim();
  if (trimmedAdded != null && trimmedAdded.isNotEmpty) {
    parts.add(
      l10n.documentSubtitleUploaded(
        formatDocumentTimestamp(l10n, trimmedAdded, localeName: localeName),
      ),
    );
  } else {
    final trimmedCreated = created?.trim();
    if (trimmedCreated != null && trimmedCreated.isNotEmpty) {
      parts.add(
        l10n.documentSubtitleDated(
          formatDocumentTimestamp(l10n, trimmedCreated, localeName: localeName),
        ),
      );
    }
  }

  if (pageCount != null) {
    parts.add(l10n.documentPages(pageCount));
  }

  if (archiveSerialNumber != null) {
    parts.add(l10n.documentAsn(archiveSerialNumber));
  }

  return parts.isEmpty ? l10n.documentFallback(id) : parts.join(' · ');
}
