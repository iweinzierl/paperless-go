import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_ngx_app/src/features/auth/data/repositories/auth_repository.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_session.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_user_capabilities.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/providers/current_user_capabilities_provider.dart';

void main() {
  test('returns null when no authenticated session is available', () async {
    final container = ProviderContainer(
      overrides: [
        authSessionProvider.overrideWith(
          () => _FakeAuthSessionController(
            const PaperlessAuthSession(
              serverUrl: 'https://example.com/paperless/',
              username: 'jane',
              password: 'secret',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(currentUserCapabilitiesProvider.future),
      isNull,
    );
  });

  test('loads capabilities for an authenticated session', () async {
    const capabilities = PaperlessUserCapabilities(
      userId: 7,
      groupIds: <int>[3],
      permissionCodenames: <String>{'delete_document'},
      isStaff: false,
      isSuperuser: false,
    );
    final repository = _FakeAuthRepository(capabilities);
    final container = ProviderContainer(
      overrides: [
        authSessionProvider.overrideWith(
          () => _FakeAuthSessionController(
            const PaperlessAuthSession(
              serverUrl: 'https://example.com/paperless/',
              username: 'jane',
              password: 'secret',
              authToken: 'token-123',
            ),
          ),
        ),
        authRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final resolved = await container.read(
      currentUserCapabilitiesProvider.future,
    );

    expect(resolved, capabilities);
    expect(repository.requestedServerUrl, 'https://example.com/paperless/');
    expect(repository.requestedAuthToken, 'token-123');
  });
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository(this.capabilities) : super(Dio());

  final PaperlessUserCapabilities capabilities;
  String? requestedServerUrl;
  String? requestedAuthToken;

  @override
  Future<PaperlessUserCapabilities> fetchUserCapabilities({
    required String serverUrl,
    required String authToken,
  }) async {
    requestedServerUrl = serverUrl;
    requestedAuthToken = authToken;
    return capabilities;
  }
}

class _FakeAuthSessionController extends AuthSessionController {
  _FakeAuthSessionController(this.session);

  final PaperlessAuthSession session;

  @override
  PaperlessAuthSession build() => session;
}
