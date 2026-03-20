import 'package:shared_preferences/shared_preferences.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_session.dart';

class AuthPreferences {
  const AuthPreferences(this._sharedPreferences);

  static const _serverUrlKey = 'auth.server_url';
  static const _usernameKey = 'auth.username';
  static const _passwordKey = 'auth.password';
  static const _authTokenKey = 'auth.token';
  static const _displayNameKey = 'auth.display_name';

  final SharedPreferences _sharedPreferences;

  PaperlessAuthSession readSession() {
    return PaperlessAuthSession(
      serverUrl: _sharedPreferences.getString(_serverUrlKey) ?? '',
      username: _sharedPreferences.getString(_usernameKey) ?? '',
      password: _sharedPreferences.getString(_passwordKey) ?? '',
      authToken: _sharedPreferences.getString(_authTokenKey),
      displayName: _sharedPreferences.getString(_displayNameKey),
    );
  }

  Future<void> saveSession(PaperlessAuthSession session) async {
    await _sharedPreferences.setString(_serverUrlKey, session.serverUrl);
    await _sharedPreferences.setString(_usernameKey, session.username);
    await _sharedPreferences.setString(_passwordKey, session.password);

    final token = session.authToken;
    if (token == null || token.isEmpty) {
      await _sharedPreferences.remove(_authTokenKey);
    } else {
      await _sharedPreferences.setString(_authTokenKey, token);
    }

    final displayName = session.displayName;
    if (displayName == null || displayName.isEmpty) {
      await _sharedPreferences.remove(_displayNameKey);
    } else {
      await _sharedPreferences.setString(_displayNameKey, displayName);
    }
  }
}
