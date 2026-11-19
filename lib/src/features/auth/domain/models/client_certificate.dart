import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// A TLS client certificate with its private key, as a PKCS #12 file (.p12 or
/// .pfx). The app presents it to servers that ask for mutual TLS (mTLS).
class ClientCertificate {
  const ClientCertificate({
    required this.fileName,
    required this.bytes,
    required this.password,
  });

  factory ClientCertificate.fromJson(Map<String, dynamic> json) {
    return ClientCertificate(
      fileName: json['file_name'] as String,
      bytes: base64Decode(json['data'] as String),
      password: json['password'] as String,
    );
  }

  final String fileName;
  final Uint8List bytes;
  final String password;

  /// A context that trusts the usual certificate authorities and presents this
  /// certificate. Throws a [TlsException] when the file is not a PKCS #12 file
  /// or the password is wrong.
  SecurityContext toSecurityContext() {
    return SecurityContext(withTrustedRoots: true)
      ..useCertificateChainBytes(bytes, password: password)
      ..usePrivateKeyBytes(bytes, password: password);
  }

  Map<String, Object> toJson() {
    return <String, Object>{
      'file_name': fileName,
      'data': base64Encode(bytes),
      'password': password,
    };
  }
}
