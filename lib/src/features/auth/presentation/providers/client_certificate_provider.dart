import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/features/auth/data/local/connection_secrets_storage.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/client_certificate.dart';

/// The TLS client certificate the app presents, if any. Starts with the saved
/// one; the login form replaces it before it signs in.
final clientCertificateProvider = StateProvider<ClientCertificate?>((ref) {
  return ref.watch(connectionSecretsStorageProvider).clientCertificate;
});

final clientCertificatePickerProvider = Provider<ClientCertificatePicker>(
  (ref) => const SystemClientCertificatePicker(),
);

typedef PickedClientCertificateFile = ({String fileName, Uint8List bytes});

abstract class ClientCertificatePicker {
  /// Returns null when the user cancels. Throws a
  /// [ClientCertificateFileException] when the file can't be a certificate.
  Future<PickedClientCertificateFile?> pick();
}

class ClientCertificateFileException implements Exception {
  const ClientCertificateFileException();

  @override
  String toString() => 'The file is too large or could not be read.';
}

/// A PKCS #12 file with a certificate chain is a few kilobytes. The limit
/// keeps a wrongly picked file out of memory and out of the secure storage.
const maxClientCertificateFileSize = 256 * 1024;

class SystemClientCertificatePicker implements ClientCertificatePicker {
  const SystemClientCertificatePicker();

  @override
  Future<PickedClientCertificateFile?> pick() async {
    // Not filtered by extension: iOS doesn't offer .p12 files reliably then.
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    if (file.size > maxClientCertificateFileSize) {
      throw const ClientCertificateFileException();
    }

    final path = file.path;
    final bytes =
        file.bytes ?? (path == null ? null : await File(path).readAsBytes());
    if (bytes == null || bytes.length > maxClientCertificateFileSize) {
      throw const ClientCertificateFileException();
    }

    return (fileName: file.name, bytes: bytes);
  }
}
