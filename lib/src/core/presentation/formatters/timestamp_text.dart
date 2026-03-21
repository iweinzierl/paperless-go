String formatDocumentTimestamp(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  final hasExplicitTime = value.contains('T') || value.contains(':');
  return hasExplicitTime
      ? formatAbsoluteDateTime(parsed)
      : formatAbsoluteDate(parsed);
}

String formatAbsoluteDate(DateTime value, {DateTime? now}) {
  final month = _monthLabel(value.month);
  return '${value.day} $month ${value.year}';
}

String formatAbsoluteDateTime(DateTime value, {DateTime? now}) {
  return '${formatAbsoluteDate(value, now: now)}, ${_formatTime(value)}';
}

String formatRefreshTimestamp(DateTime value, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  if (_isSameDay(value, reference)) {
    return 'today at ${_formatTime(value)}';
  }

  final yesterday = reference.subtract(const Duration(days: 1));
  if (_isSameDay(value, yesterday)) {
    return 'yesterday at ${_formatTime(value)}';
  }

  return formatAbsoluteDateTime(value, now: reference);
}

bool _isSameDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

String _formatTime(DateTime value) {
  final hours = value.hour.toString().padLeft(2, '0');
  final minutes = value.minute.toString().padLeft(2, '0');
  return '$hours:$minutes';
}

String _monthLabel(int month) {
  switch (month) {
    case 1:
      return 'Jan';
    case 2:
      return 'Feb';
    case 3:
      return 'Mar';
    case 4:
      return 'Apr';
    case 5:
      return 'May';
    case 6:
      return 'Jun';
    case 7:
      return 'Jul';
    case 8:
      return 'Aug';
    case 9:
      return 'Sep';
    case 10:
      return 'Oct';
    case 11:
      return 'Nov';
    case 12:
      return 'Dec';
  }

  return 'Unknown';
}
