import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

abstract class BiometricAuthService {
  Future<bool> isAvailable();

  Future<bool> authenticate({required String localizedReason});
}

class LocalBiometricAuthService implements BiometricAuthService {
  LocalBiometricAuthService({LocalAuthentication? localAuthentication})
    : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  @override
  Future<bool> isAvailable() async {
    try {
      final isDeviceSupported = await _localAuthentication.isDeviceSupported();
      final canCheckBiometrics = await _localAuthentication.canCheckBiometrics;
      return isDeviceSupported && canCheckBiometrics;
    } on LocalAuthException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      final isAvailable = await this.isAvailable();
      if (!isAvailable) {
        return false;
      }

      return await _localAuthentication.authenticate(
        localizedReason: localizedReason,
        biometricOnly: false,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
