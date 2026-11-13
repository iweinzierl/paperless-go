import 'package:shared_preferences/shared_preferences.dart';
import 'package:paperless_ngx_app/src/features/auth/data/local/auth_token_storage.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_method.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_session.dart';

class AuthPreferences {
  const AuthPreferences(this._sharedPreferences, this._tokenStorage);

  static const _serverUrlKey = 'auth.server_url';
  static const _usernameKey = 'auth.username';
  static const _passwordKey = 'auth.password';
  static const _displayNameKey = 'auth.display_name';
  static const _methodKey = 'auth.method';

  final SharedPreferences _sharedPreferences;
  final AuthTokenStorage _tokenStorage;

  PaperlessAuthSession readSession() {
    return PaperlessAuthSession(
      serverUrl: _sharedPreferences.getString(_serverUrlKey) ?? '',
      username: _sharedPreferences.getString(_usernameKey) ?? '',
      password: _sharedPreferences.getString(_passwordKey) ?? '',
      authToken: _tokenStorage.token,
      displayName: _sharedPreferences.getString(_displayNameKey),
      method: _readMethod(),
    );
  }

  PaperlessAuthMethod _readMethod() {
    final value = _sharedPreferences.getString(_methodKey);
    if (value == PaperlessAuthMethod.token.name) {
      return PaperlessAuthMethod.token;
    }

    return PaperlessAuthMethod.password;
  }

  Future<void> saveSession(PaperlessAuthSession session) async {
    await _sharedPreferences.setString(_serverUrlKey, session.serverUrl);
    await _sharedPreferences.setString(_usernameKey, session.username);
    await _sharedPreferences.setString(_passwordKey, session.password);
    await _sharedPreferences.setString(_methodKey, session.method.name);
    await _tokenStorage.write(session.authToken);

    final displayName = session.displayName;
    if (displayName == null || displayName.isEmpty) {
      await _sharedPreferences.remove(_displayNameKey);
    } else {
      await _sharedPreferences.setString(_displayNameKey, displayName);
    }
  }

  Future<void> clearSession() async {
    await _tokenStorage.delete();
    await _sharedPreferences.remove(_displayNameKey);
  }
}
