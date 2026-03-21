import 'package:intl/intl.dart';
import 'package:paperless_ngx_app/l10n/generated/app_localizations.dart';

String formatDocumentTimestamp(
  AppLocalizations l10n,
  String value, {
  required String localeName,
}) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  final hasExplicitTime = value.contains('T') || value.contains(':');
  return hasExplicitTime
      ? formatAbsoluteDateTime(parsed, localeName: localeName)
      : formatAbsoluteDate(parsed, localeName: localeName);
}

String formatAbsoluteDate(DateTime value, {required String localeName}) {
  return DateFormat('d MMM yyyy', localeName).format(value);
}

String formatAbsoluteDateTime(DateTime value, {required String localeName}) {
  return '${formatAbsoluteDate(value, localeName: localeName)}, ${_formatTime(value, localeName: localeName)}';
}

String formatRefreshTimestamp(
  AppLocalizations l10n,
  DateTime value, {
  DateTime? now,
  required String localeName,
}) {
  final reference = now ?? DateTime.now();
  if (_isSameDay(value, reference)) {
    return l10n.todayAtLabel(_formatTime(value, localeName: localeName));
  }

  final yesterday = reference.subtract(const Duration(days: 1));
  if (_isSameDay(value, yesterday)) {
    return l10n.yesterdayAtLabel(_formatTime(value, localeName: localeName));
  }

  return formatAbsoluteDateTime(value, localeName: localeName);
}

bool _isSameDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

String _formatTime(DateTime value, {required String localeName}) {
  return DateFormat.Hm(localeName).format(value);
}
