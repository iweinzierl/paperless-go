import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/features/auth/data/local/auth_preferences.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_session.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/login_controller.dart';

final authSessionProvider =
    NotifierProvider<AuthSessionController, PaperlessAuthSession>(
      AuthSessionController.new,
    );

class AuthSessionController extends Notifier<PaperlessAuthSession> {
  AuthPreferences get _authPreferences => ref.read(authPreferencesProvider);

  @override
  PaperlessAuthSession build() {
    return _authPreferences.readSession();
  }

  void setSession(PaperlessAuthSession session) {
    state = session;
  }

  Future<void> signOut() async {
    final clearedSession = state.copyWith(authToken: '', displayName: '');
    await _authPreferences.clearSession();
    state = clearedSession;
  }
}
