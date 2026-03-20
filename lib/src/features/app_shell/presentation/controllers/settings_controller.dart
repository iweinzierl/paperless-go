import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/features/auth/data/local/auth_preferences.dart';
import 'package:paperless_ngx_app/src/features/auth/data/repositories/auth_repository.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_session.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/login_controller.dart';

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsFormState>(
      SettingsController.new,
    );

class SettingsController extends Notifier<SettingsFormState> {
  AuthPreferences get _authPreferences => ref.read(authPreferencesProvider);
  AuthRepository get _authRepository => ref.read(authRepositoryProvider);
  AuthSessionController get _authSessionController =>
      ref.read(authSessionProvider.notifier);

  @override
  SettingsFormState build() {
    final session = ref.watch(authSessionProvider);
    return SettingsFormState.fromSession(session);
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

  void clearFeedback() {
    state = state.copyWith(clearFeedbackMessage: true);
  }

  Future<void> submit() async {
    final nextState = state.copyWith(
      hasSubmitted: true,
      clearFeedbackMessage: true,
      saveStatus: const AsyncLoading<void>(),
    );

    if (!nextState.isValid) {
      state = nextState.copyWith(saveStatus: const AsyncData<void>(null));
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
          saveStatus: const AsyncData<void>(null),
          connectedDisplayName: session.displayName,
          feedbackMessage: 'Settings saved and connection verified.',
        );
      },
      error: (error, stackTrace) {
        state = state.copyWith(
          saveStatus: AsyncError<void>(error, stackTrace),
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

    return 'Could not save settings. Please try again.';
  }
}

class SettingsFormState {
  const SettingsFormState({
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.hasSubmitted,
    required this.saveStatus,
    this.feedbackMessage,
    this.connectedDisplayName,
  });

  factory SettingsFormState.fromSession(PaperlessAuthSession session) {
    return SettingsFormState(
      serverUrl: session.serverUrl,
      username: session.username,
      password: session.password,
      hasSubmitted: false,
      saveStatus: const AsyncData<void>(null),
      feedbackMessage: null,
      connectedDisplayName: session.displayName,
    );
  }

  final String serverUrl;
  final String username;
  final String password;
  final bool hasSubmitted;
  final AsyncValue<void> saveStatus;
  final String? feedbackMessage;
  final String? connectedDisplayName;

  bool get isSaving => saveStatus.isLoading;

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

  SettingsFormState copyWith({
    String? serverUrl,
    String? username,
    String? password,
    bool? hasSubmitted,
    AsyncValue<void>? saveStatus,
    String? feedbackMessage,
    String? connectedDisplayName,
    bool clearFeedbackMessage = false,
  }) {
    return SettingsFormState(
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      hasSubmitted: hasSubmitted ?? this.hasSubmitted,
      saveStatus: saveStatus ?? this.saveStatus,
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
      connectedDisplayName: connectedDisplayName ?? this.connectedDisplayName,
    );
  }
}
