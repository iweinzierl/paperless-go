import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/features/app_shell/data/device/biometric_auth_service.dart';

final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return LocalBiometricAuthService();
});
