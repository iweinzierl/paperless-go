import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/providers/shared_preferences_provider.dart';
import 'package:paperless_ngx_app/src/features/auth/data/local/auth_preferences.dart';
import 'package:paperless_ngx_app/src/features/auth/data/repositories/auth_repository.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_session.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/auth_session_controller.dart';

final authPreferencesProvider = Provider<AuthPreferences>((ref) {
  return AuthPreferences(ref.watch(sharedPreferencesProvider));
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
    state = state.copyWith(serverUrl: value, clearFeedbackMessage: true);
  }

  void updateUsername(String value) {
    state = state.copyWith(username: value, clearFeedbackMessage: true);
  }

  void updatePassword(String value) {
    state = state.copyWith(password: value, clearFeedbackMessage: true);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  Future<void> submit() async {
    final nextState = state.copyWith(
      hasSubmitted: true,
      clearFeedbackMessage: true,
      loginStatus: const AsyncLoading<void>(),
    );

    if (!nextState.isValid) {
      state = nextState.copyWith(loginStatus: const AsyncData<void>(null));
      return;
    }

    state = nextState;

    final result = await AsyncValue.guard<PaperlessAuthSession>(() async {
      final session = await _authRepository.signIn(
        serverUrl: state.serverUrl,
        username: state.username,
        password: state.password,
      );
      await _authPreferences.saveSession(session);
      return session;
    });

    result.when(
      data: (session) {
        _authSessionController.setSession(session);
        state = state.copyWith(
          loginStatus: const AsyncData<void>(null),
          connectedDisplayName: session.displayName,
          feedbackMessage: 'Connected successfully.',
        );
      },
      error: (error, stackTrace) {
        state = state.copyWith(
          loginStatus: AsyncError<void>(error, stackTrace),
          feedbackMessage: _toErrorMessage(error),
        );
      },
      loading: () {},
    );
  }

  String _toErrorMessage(Object error) {
    if (error is AuthFailure) {
      return error.message;
    }

    return 'Login failed. Please try again.';
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
    this.feedbackMessage,
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
      connectedDisplayName: session.displayName,
    );
  }

  final String serverUrl;
  final String username;
  final String password;
  final bool obscurePassword;
  final bool hasSubmitted;
  final AsyncValue<void> loginStatus;
  final String? feedbackMessage;
  final String? connectedDisplayName;

  bool get isSubmitting => loginStatus.isLoading;

  bool get isValid =>
      serverUrlError == null && usernameError == null && passwordError == null;

  String? get serverUrlError {
    if (!hasSubmitted) {
      return null;
    }

    final trimmed = serverUrl.trim();
    if (trimmed.isEmpty) {
      return 'Enter your paperless-ngx server URL.';
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Use a full URL like https://paperless.example.com.';
    }

    return null;
  }

  String? get usernameError {
    if (!hasSubmitted) {
      return null;
    }

    if (username.trim().isEmpty) {
      return 'Enter your username.';
    }

    return null;
  }

  String? get passwordError {
    if (!hasSubmitted) {
      return null;
    }

    if (password.isEmpty) {
      return 'Enter your password.';
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
    String? feedbackMessage,
    String? connectedDisplayName,
    bool clearFeedbackMessage = false,
  }) {
    return LoginFormState(
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      hasSubmitted: hasSubmitted ?? this.hasSubmitted,
      loginStatus: loginStatus ?? this.loginStatus,
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
      connectedDisplayName: connectedDisplayName ?? this.connectedDisplayName,
    );
  }
}
