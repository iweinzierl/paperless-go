import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';

void main() {
  PaperlessDocument document({String title = 'Invoice', String? mimeType}) {
    return PaperlessDocument.fromJson(<String, dynamic>{
      'id': 7,
      'title': title,
      'mime_type': mimeType,
    });
  }

  String fileName(String? contentDisposition, {PaperlessDocument? of}) {
    return downloadFileName(
      contentDisposition: contentDisposition,
      document: of ?? document(),
    );
  }

  group('downloadFileName', () {
    test('uses the file name of the server', () {
      expect(
        fileName('attachment; filename="2024 invoice.pdf"'),
        '2024 invoice.pdf',
      );
      expect(
        fileName("attachment; filename*=UTF-8''Rechnung%20M%C3%A4rz.pdf"),
        'Rechnung März.pdf',
      );
    });

    test('never leaves the download directory', () {
      expect(fileName('attachment; filename="../escaped.txt"'), 'escaped.txt');
      expect(
        fileName('attachment; filename="..\\..\\escaped.txt"'),
        'escaped.txt',
      );
      expect(fileName('attachment; filename="/etc/passwd"'), 'passwd');
      expect(
        fileName("attachment; filename*=UTF-8''..%2F..%2Fescaped.txt"),
        'escaped.txt',
      );
    });

    test('falls back to the document for an unusable file name', () {
      expect(fileName('attachment; filename=".."'), 'Invoice');
      expect(fileName("attachment; filename*=UTF-8''..%2F"), 'Invoice');
      expect(fileName("attachment; filename*=UTF-8''%E0%A4%A"), 'Invoice');
      expect(fileName(null, of: document(title: '..')), 'document-7');
    });

    test('makes a name from the document without a header', () {
      expect(fileName(null), 'Invoice');
      expect(
        fileName(null, of: document(mimeType: 'application/pdf')),
        'Invoice.pdf',
      );
      expect(fileName(null, of: document(title: 'a/b: c')), 'a_b_ c');
      expect(fileName(null, of: document(title: 'report.txt')), 'report.txt');
    });
  });
}
