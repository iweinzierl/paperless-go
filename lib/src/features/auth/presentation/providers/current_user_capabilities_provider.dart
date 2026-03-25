import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/features/auth/data/repositories/auth_repository.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_user_capabilities.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/auth_session_controller.dart';

final currentUserCapabilitiesProvider =
    FutureProvider<PaperlessUserCapabilities?>((ref) async {
      final session = ref.watch(authSessionProvider);
      final authToken = session.authToken;
      if (!session.isAuthenticated || authToken == null || authToken.isEmpty) {
        return null;
      }

      return ref
          .watch(authRepositoryProvider)
          .fetchUserCapabilities(
            serverUrl: session.serverUrl,
            authToken: authToken,
          );
    });
