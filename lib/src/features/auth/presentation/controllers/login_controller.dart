import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/providers/shared_preferences_provider.dart';
import 'package:paperless_ngx_app/src/features/auth/data/local/auth_preferences.dart';
import 'package:paperless_ngx_app/src/features/auth/data/local/auth_token_storage.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_method.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_session.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:paperless_ngx_app/src/features/auth/data/repositories/auth_repository.dart';

final authPreferencesProvider = Provider<AuthPreferences>((ref) {
  return AuthPreferences(
    ref.watch(sharedPreferencesProvider),
    ref.watch(authTokenStorageProvider),
  );
});

final loginControllerProvider =
    NotifierProvider<LoginController, LoginFormState>(LoginController.new);

class LoginController extends Notifier<LoginFormState> {
  AuthPreferences get _authPreferences => ref.read(authPreferencesProvider);
  AuthRepository get _authRepository => ref.read(authRepositoryProvider);
  AuthSessionController get _authSessionController =>
      ref.read(authSessionProvider.notifier);

  @override
  LoginFormState build() {
    final savedSession = _authPreferences.readSession();

    return LoginFormState.fromSession(savedSession);
  }

  void updateServerUrl(String value) {
    state = state.copyWith(serverUrl: value);
  }

  void updateUsername(String value) {
    state = state.copyWith(username: value);
  }

  void updatePassword(String value) {
    state = state.copyWith(password: value);
  }

  void updateMfaCode(String value) {
    state = state.copyWith(mfaCode: value);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void updateMethod(PaperlessAuthMethod value) {
    state = state.copyWith(method: value);
  }

  void updateToken(String value) {
    state = state.copyWith(token: value);
  }

  void toggleTokenVisibility() {
    state = state.copyWith(obscureToken: !state.obscureToken);
  }

  Future<void> submit() async {
    final nextState = state.copyWith(
      hasSubmitted: true,
      loginStatus: const AsyncLoading<void>(),
    );

    if (!nextState.isValid) {
      state = nextState.copyWith(loginStatus: const AsyncData<void>(null));
      return;
    }

    state = nextState;

    final result = await AsyncValue.guard<PaperlessAuthSession>(() async {
      final session = state.method == PaperlessAuthMethod.token
          ? await _authRepository.signInWithToken(
              serverUrl: state.serverUrl,
              token: state.token.trim(),
            )
          : await _authRepository.signIn(
              serverUrl: state.serverUrl,
              username: state.username,
              password: state.password,
              code: state.mfaCode,
            );
      await _authPreferences.saveSession(session);
      return session;
    });

    state = state.copyWith(mfaCode: '');

    result.when(
      data: (session) {
        _authSessionController.setSession(session);
        state = state.copyWith(
          loginStatus: const AsyncData<void>(null),
          connectedDisplayName: session.displayName,
        );
      },
      error: (error, stackTrace) {
        state = state.copyWith(
          loginStatus: AsyncError<void>(error, stackTrace),
        );
      },
      loading: () {},
    );
  }
}

class LoginFormState {
  const LoginFormState({
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.obscurePassword,
    required this.hasSubmitted,
    required this.loginStatus,
    this.method = PaperlessAuthMethod.password,
    this.token = '',
    this.obscureToken = true,
    this.mfaCode = '',
    this.connectedDisplayName,
  });

  factory LoginFormState.fromSession(PaperlessAuthSession session) {
    return LoginFormState(
      serverUrl: session.serverUrl,
      username: session.username,
      password: session.password,
      obscurePassword: true,
      hasSubmitted: false,
      loginStatus: const AsyncData<void>(null),
      method: session.method,
      token: session.method == PaperlessAuthMethod.token
          ? session.authToken ?? ''
          : '',
      connectedDisplayName: session.displayName,
    );
  }

  final String serverUrl;
  final String username;
  final String password;
  final bool obscurePassword;
  final bool hasSubmitted;
  final AsyncValue<void> loginStatus;
  final PaperlessAuthMethod method;
  final String token;
  final bool obscureToken;
  final String mfaCode;
  final String? connectedDisplayName;

  bool get isSubmitting => loginStatus.isLoading;

  bool get isTokenMethod => method == PaperlessAuthMethod.token;

  bool get isValid {
    if (isTokenMethod) {
      return _hasValidServerUrl && token.trim().isNotEmpty;
    }

    return _hasValidServerUrl &&
        username.trim().isNotEmpty &&
        password.isNotEmpty;
  }

  bool get _hasValidServerUrl {
    final trimmed = serverUrl.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    final uri = Uri.tryParse(trimmed);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  String? serverUrlError(String requiredMessage, String fullUrlMessage) {
    if (!hasSubmitted) {
      return null;
    }

    final trimmed = serverUrl.trim();
    if (trimmed.isEmpty) {
      return requiredMessage;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return fullUrlMessage;
    }

    return null;
  }

  String? usernameError(String requiredMessage) {
    if (!hasSubmitted || isTokenMethod) {
      return null;
    }

    if (username.trim().isEmpty) {
      return requiredMessage;
    }

    return null;
  }

  String? passwordError(String requiredMessage) {
    if (!hasSubmitted || isTokenMethod) {
      return null;
    }

    if (password.isEmpty) {
      return requiredMessage;
    }

    return null;
  }

  String? tokenError(String requiredMessage) {
    if (!hasSubmitted) {
      return null;
    }

    if (token.trim().isEmpty) {
      return requiredMessage;
    }

    return null;
  }

  LoginFormState copyWith({
    String? serverUrl,
    String? username,
    String? password,
    bool? obscurePassword,
    bool? hasSubmitted,
    AsyncValue<void>? loginStatus,
    PaperlessAuthMethod? method,
    String? token,
    bool? obscureToken,
    String? mfaCode,
    String? connectedDisplayName,
  }) {
    return LoginFormState(
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      hasSubmitted: hasSubmitted ?? this.hasSubmitted,
      loginStatus: loginStatus ?? this.loginStatus,
      method: method ?? this.method,
      token: token ?? this.token,
      obscureToken: obscureToken ?? this.obscureToken,
      mfaCode: mfaCode ?? this.mfaCode,
      connectedDisplayName: connectedDisplayName ?? this.connectedDisplayName,
    );
  }
}
