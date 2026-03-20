import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:paperless_ngx_app/src/features/app_shell/domain/models/recently_opened_document.dart';

class RecentlyOpenedPreferences {
  const RecentlyOpenedPreferences(this._sharedPreferences);

  static const _recentlyOpenedKey = 'app_shell.recently_opened_documents';

  final SharedPreferences _sharedPreferences;

  List<RecentlyOpenedDocument> readDocuments() {
    final rawValue = _sharedPreferences.getString(_recentlyOpenedKey);
    if (rawValue == null || rawValue.isEmpty) {
      return const <RecentlyOpenedDocument>[];
    }

    final decoded = jsonDecode(rawValue);
    if (decoded is! List) {
      return const <RecentlyOpenedDocument>[];
    }

    return decoded
        .whereType<Map>()
        .map(
          (item) => RecentlyOpenedDocument.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(growable: false);
  }

  Future<void> saveDocuments(List<RecentlyOpenedDocument> documents) async {
    final payload = jsonEncode(
      documents.map((document) => document.toJson()).toList(growable: false),
    );
    await _sharedPreferences.setString(_recentlyOpenedKey, payload);
  }
}
