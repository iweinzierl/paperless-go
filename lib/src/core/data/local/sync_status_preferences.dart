import 'package:shared_preferences/shared_preferences.dart';

enum SyncStatusScope { recentUploads, todoDocuments, documents }

class SyncStatusPreferences {
  const SyncStatusPreferences(this._sharedPreferences);

  static const _recentUploadsKey = 'sync.recent_uploads.last_success_at';
  static const _todoDocumentsKey = 'sync.todo_documents.last_success_at';
  static const _documentsKey = 'sync.documents.last_success_at';

  final SharedPreferences _sharedPreferences;

  DateTime? readLastSuccessfulSync(SyncStatusScope scope) {
    final value = _sharedPreferences.getString(_keyForScope(scope));
    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  Future<void> saveLastSuccessfulSync(
    SyncStatusScope scope,
    DateTime timestamp,
  ) async {
    await _sharedPreferences.setString(
      _keyForScope(scope),
      timestamp.toIso8601String(),
    );
  }

  String _keyForScope(SyncStatusScope scope) {
    return switch (scope) {
      SyncStatusScope.recentUploads => _recentUploadsKey,
      SyncStatusScope.todoDocuments => _todoDocumentsKey,
      SyncStatusScope.documents => _documentsKey,
    };
  }
}
