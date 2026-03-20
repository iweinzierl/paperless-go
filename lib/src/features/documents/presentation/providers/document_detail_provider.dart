import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';

final documentDetailProvider = FutureProvider.family<PaperlessDocument, int>((
  ref,
  documentId,
) async {
  final repository = ref.watch(documentsRepositoryProvider);
  return repository.fetchDocument(documentId);
});
