import 'package:paperless_ngx_app/src/features/documents/presentation/models/documents_layout_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DocumentsViewPreferences {
  const DocumentsViewPreferences(this._sharedPreferences);

  static const _layoutModeKey = 'documents.layout_mode';

  final SharedPreferences _sharedPreferences;

  DocumentsLayoutMode readLayoutMode() {
    return documentsLayoutModeFromStorage(
      _sharedPreferences.getString(_layoutModeKey),
    );
  }

  Future<void> saveLayoutMode(DocumentsLayoutMode mode) async {
    await _sharedPreferences.setString(_layoutModeKey, mode.storageValue);
  }
}
