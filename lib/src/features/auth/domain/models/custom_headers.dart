/// Custom HTTP headers the user wants sent with every request, for example
/// the service token headers of an authenticating reverse proxy.
///
/// On the login form they are edited as text, one `Name: value` pair per line.
library;

// A header name is an RFC 9110 token.
final _headerNamePattern = RegExp(r"^[!#$%&'*+\-.^_`|~0-9A-Za-z]+$");

// A value may only be printable ASCII. That keeps out line breaks, which
// could smuggle in further headers, and characters the HTTP client rejects.
final _invalidValueCharacterPattern = RegExp(r'[^\x20-\x7E]');

/// Parses one `Name: value` pair per line and skips blank lines. Returns null
/// when a line is not a valid header.
Map<String, String>? parseCustomHeaders(String text) {
  final headers = <String, String>{};

  for (final line in text.split('\n')) {
    final trimmedLine = line.trim();
    if (trimmedLine.isEmpty) {
      continue;
    }

    final separatorIndex = trimmedLine.indexOf(':');
    if (separatorIndex <= 0) {
      return null;
    }

    final name = trimmedLine.substring(0, separatorIndex).trim();
    final value = trimmedLine.substring(separatorIndex + 1).trim();
    if (!_headerNamePattern.hasMatch(name) ||
        value.isEmpty ||
        _invalidValueCharacterPattern.hasMatch(value)) {
      return null;
    }

    headers[name] = value;
  }

  return headers;
}

String formatCustomHeaders(Map<String, String> headers) {
  return headers.entries
      .map((entry) => '${entry.key}: ${entry.value}')
      .join('\n');
}

/// Custom headers usually carry secrets, so they are only sent over an
/// encrypted connection, where the server has proven who it is.
bool allowsCustomHeaders(Uri uri) => uri.isScheme('https');

/// Returns [headers] plus every custom header whose name is not already in
/// [headers]. Header names are compared case-insensitively, so a custom header
/// never replaces one the app sets itself, such as `Authorization`.
Map<String, T> withCustomHeaders<T>(
  Map<String, T> headers,
  Map<String, T> customHeaders,
) {
  if (customHeaders.isEmpty) {
    return headers;
  }

  final existingNames = headers.keys.map((name) => name.toLowerCase()).toSet();

  return <String, T>{
    ...headers,
    for (final entry in customHeaders.entries)
      if (!existingNames.contains(entry.key.toLowerCase()))
        entry.key: entry.value,
  };
}
