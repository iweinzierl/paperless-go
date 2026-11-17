import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// Throwaway self-signed certificates for tests that talk to a local HTTPS
/// server. They are made with the `openssl` command when the tests start and
/// exist only in memory, so no key material is kept in the repository.
class TestCertificates {
  const TestCertificates._({
    required this.serverCertificatePem,
    required this.serverKeyPem,
    required this.clientCertificatePem,
    required this.clientP12,
  });

  static const clientP12Password = 'test-password';

  final Uint8List serverCertificatePem;
  final Uint8List serverKeyPem;
  final Uint8List clientCertificatePem;

  /// The client certificate with its key as a PKCS #12 file, protected with
  /// [clientP12Password].
  final Uint8List clientP12;

  /// Returns null when the `openssl` command is not available, and says so on
  /// stderr: the tests that need the certificates are then skipped, which must
  /// not go unnoticed.
  static Future<TestCertificates?> generate() async {
    final certificates = await _generate();
    if (certificates == null) {
      stderr.writeln(
        'WARNING: the openssl command is missing or failed, so the tests '
        'against a local HTTPS server are SKIPPED. Install openssl to run '
        'them.',
      );
    }

    return certificates;
  }

  static Future<TestCertificates?> _generate() async {
    final directory = await Directory.systemTemp.createTemp('test_certs_');
    try {
      Future<bool> openssl(List<String> arguments) async {
        final result = await Process.run(
          'openssl',
          arguments,
          workingDirectory: directory.path,
        );
        return result.exitCode == 0;
      }

      Future<bool> selfSigned(String name) {
        return openssl(<String>[
          'req', '-x509', '-newkey', 'rsa:2048', '-nodes', //
          '-keyout', '${name}_key.pem',
          '-out', '${name}_cert.pem',
          '-days', '2',
          '-subj', '/CN=paperless-go test $name',
        ]);
      }

      final succeeded =
          await selfSigned('server') &&
          await selfSigned('client') &&
          await openssl(<String>[
            'pkcs12', '-export', //
            '-inkey', 'client_key.pem',
            '-in', 'client_cert.pem',
            '-out', 'client.p12',
            '-passout', 'pass:$clientP12Password',
          ]);
      if (!succeeded) {
        return null;
      }

      Future<Uint8List> read(String name) {
        return File('${directory.path}/$name').readAsBytes();
      }

      return TestCertificates._(
        serverCertificatePem: await read('server_cert.pem'),
        serverKeyPem: await read('server_key.pem'),
        clientCertificatePem: await read('client_cert.pem'),
        clientP12: await read('client.p12'),
      );
    } on ProcessException {
      return null;
    } finally {
      await directory.delete(recursive: true);
    }
  }
}

/// Declares a test that is skipped when [certificates] returns null, which
/// means the `openssl` command is not available.
void testWithCertificates(
  String description,
  TestCertificates? Function() certificates,
  Future<void> Function() body,
) {
  test(description, () async {
    if (certificates() == null) {
      markTestSkipped('Needs the openssl command to make test certificates.');
      return;
    }

    await body();
  });
}

/// Lets HTTP clients accept the self-signed certificate of a test server on
/// this machine, and keeps whatever client certificate the app set up. Also
/// replaces the override of widget tests that blocks real HTTP.
class TrustLocalTestServer extends HttpOverrides {
  TrustLocalTestServer(this._port);

  final int _port;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (certificate, host, port) {
        return host == '127.0.0.1' && port == _port;
      };
  }
}
