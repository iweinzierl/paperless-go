import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/network/dio_provider.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_session.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document_page.dart';

final documentsRepositoryProvider = Provider<DocumentsRepository>((ref) {
  final session = ref.watch(authSessionProvider);

  return DocumentsRepository(dio: ref.watch(dioProvider), session: session);
});

class DocumentsRepository {
  const DocumentsRepository({
    required Dio dio,
    required PaperlessAuthSession session,
  }) : _dio = dio,
       _session = session;

  final Dio _dio;
  final PaperlessAuthSession _session;

  Future<List<PaperlessDocument>> fetchRecentUploads() async {
    final page = await fetchDocuments(ordering: '-added');
    return page.results;
  }

  Future<PaperlessDocumentPage> fetchDocuments({
    int page = 1,
    int pageSize = 20,
    String ordering = '-created',
    String titleFilter = '',
  }) async {
    final token = _session.authToken;
    if (token == null || token.isEmpty) {
      throw const DocumentsFailure('No authenticated session found.');
    }

    final apiUri = Uri.parse(_session.serverUrl).resolve('api/documents/');
    final response = await _dio.getUri(
      apiUri.replace(
        queryParameters: <String, String>{
          'page': page.toString(),
          'page_size': pageSize.toString(),
          'ordering': ordering,
          'truncate_content': 'true',
          if (titleFilter.trim().isNotEmpty)
            'title__icontains': titleFilter.trim(),
        },
      ),
      options: Options(
        headers: <String, Object>{'Authorization': 'Token $token'},
      ),
    );

    final payload = _asJsonMap(response.data);
    return PaperlessDocumentPage.fromJson(payload);
  }

  Map<String, dynamic> _asJsonMap(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }

    throw const DocumentsFailure(
      'The server returned an unexpected document response.',
    );
  }
}

class DocumentsFailure implements Exception {
  const DocumentsFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
