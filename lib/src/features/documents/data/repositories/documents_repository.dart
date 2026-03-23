import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:paperless_ngx_app/src/core/network/dio_provider.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_session.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document_page.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_filter_option.dart';

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

  Future<PaperlessDocument> fetchDocument(int documentId) async {
    final token = _requireAuthToken();
    final apiUri = Uri.parse(
      _session.serverUrl,
    ).resolve('api/documents/$documentId/');
    final response = await _dio.getUri(
      apiUri.replace(
        queryParameters: const <String, String>{'full_perms': 'true'},
      ),
      options: Options(
        headers: <String, Object>{'Authorization': 'Token $token'},
      ),
    );

    return PaperlessDocument.fromJson(_asJsonMap(response.data));
  }

  Future<PaperlessDocument> updateDocumentMetadata({
    required int documentId,
    required String title,
    String? created,
    int? correspondentId,
    int? documentTypeId,
    required List<int> tagIds,
  }) async {
    final token = _requireAuthToken();
    final apiUri = Uri.parse(
      _session.serverUrl,
    ).resolve('api/documents/$documentId/');
    final response = await _dio.patchUri(
      apiUri,
      data: <String, Object?>{
        'title': title.trim(),
        'created': created?.trim().isEmpty == true ? null : created?.trim(),
        'correspondent': correspondentId,
        'document_type': documentTypeId,
        'tags': tagIds,
      },
      options: Options(
        headers: <String, Object>{'Authorization': 'Token $token'},
      ),
    );

    return PaperlessDocument.fromJson(_asJsonMap(response.data));
  }

  Future<String> uploadDocument({
    required String filePath,
    String? title,
  }) async {
    final token = _requireAuthToken();
    final apiUri = Uri.parse(
      _session.serverUrl,
    ).resolve('api/documents/post_document/');

    try {
      final response = await _dio.postUri(
        apiUri,
        data: FormData.fromMap(<String, Object>{
          'document': await MultipartFile.fromFile(
            filePath,
            filename: _fileNameFromPath(filePath),
          ),
          if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        }),
        options: Options(
          headers: <String, Object>{'Authorization': 'Token $token'},
        ),
      );

      final data = response.data;
      if (data is String && data.trim().isNotEmpty) {
        return data.trim();
      }

      if (data is num) {
        return data.toString();
      }

      throw const DocumentsFailure(
        'The server returned an unexpected upload response.',
      );
    } on DioException catch (error) {
      throw _uploadFailureFromDio(error);
    }
  }

  Future<PaperlessDocumentPage> fetchDocuments({
    int page = 1,
    int pageSize = 20,
    String ordering = '-created',
    String titleFilter = '',
    int? tagId,
    bool? isInInbox,
    int? correspondentId,
    int? documentTypeId,
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
          if (tagId != null) 'tags__id__all': tagId.toString(),
          if (isInInbox != null) 'is_in_inbox': isInInbox.toString(),
          if (correspondentId != null)
            'correspondent__id': correspondentId.toString(),
          if (documentTypeId != null)
            'document_type__id': documentTypeId.toString(),
        },
      ),
      options: Options(
        headers: <String, Object>{'Authorization': 'Token $token'},
      ),
    );

    final payload = _asJsonMap(response.data);
    return PaperlessDocumentPage.fromJson(payload);
  }

  Future<List<PaperlessFilterOption>> fetchTagOptions() {
    return _fetchFilterOptions(endpoint: 'tags/');
  }

  Future<List<PaperlessFilterOption>> fetchCorrespondentOptions() {
    return _fetchFilterOptions(endpoint: 'correspondents/');
  }

  Future<List<PaperlessFilterOption>> fetchDocumentTypeOptions() {
    return _fetchFilterOptions(endpoint: 'document_types/');
  }

  Future<PaperlessFilterOption> createTag({required String name}) {
    return _createFilterOption(endpoint: 'tags/', name: name);
  }

  Future<PaperlessFilterOption> createCorrespondent({required String name}) {
    return _createFilterOption(endpoint: 'correspondents/', name: name);
  }

  Future<PaperlessFilterOption> createDocumentType({required String name}) {
    return _createFilterOption(endpoint: 'document_types/', name: name);
  }

  Future<String> downloadDocumentToTemporaryFile({
    required PaperlessDocument document,
    bool original = false,
  }) async {
    return _downloadFileToTemporaryDirectory(
      document: document,
      endpoint: 'download/',
      original: original,
    );
  }

  Future<String> downloadPreviewToTemporaryFile({
    required PaperlessDocument document,
    bool original = false,
  }) async {
    return _downloadFileToTemporaryDirectory(
      document: document,
      endpoint: 'preview/',
      original: original,
    );
  }

  Uri buildDocumentThumbnailUri(int documentId) {
    return Uri.parse(
      _session.serverUrl,
    ).resolve('api/documents/$documentId/thumb/');
  }

  ImageProvider<Object>? buildDocumentThumbnailImageProvider(int documentId) {
    return null;
  }

  Widget? buildDocumentThumbnailWidget(PaperlessDocument document) {
    return null;
  }

  Map<String, String> buildAuthenticatedHeaders() {
    final token = _requireAuthToken();
    return <String, String>{'Authorization': 'Token $token'};
  }

  Future<String> _downloadFileToTemporaryDirectory({
    required PaperlessDocument document,
    required String endpoint,
    bool original = false,
  }) async {
    final apiUri = Uri.parse(
      _session.serverUrl,
    ).resolve('api/documents/${document.id}/$endpoint');
    final response = await _dio.getUri<List<int>>(
      apiUri.replace(
        queryParameters: <String, String>{if (original) 'original': 'true'},
      ),
      options: Options(
        headers: buildAuthenticatedHeaders(),
        responseType: ResponseType.bytes,
      ),
    );

    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw const DocumentsFailure(
        'The server returned an empty document file.',
      );
    }

    final directory = await getTemporaryDirectory();
    final fileName = _fileNameFromResponse(response, document);
    final file = File('${directory.path}/$fileName');

    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<List<PaperlessFilterOption>> _fetchFilterOptions({
    required String endpoint,
  }) async {
    final token = _requireAuthToken();

    final apiUri = Uri.parse(_session.serverUrl).resolve('api/$endpoint');
    final response = await _dio.getUri(
      apiUri.replace(
        queryParameters: const <String, String>{
          'page': '1',
          'page_size': '1000',
        },
      ),
      options: Options(
        headers: <String, Object>{'Authorization': 'Token $token'},
      ),
    );

    final payload = _asJsonMap(response.data);
    final results = payload['results'] as List<dynamic>? ?? const <dynamic>[];

    return results
        .whereType<Map>()
        .map(
          (item) => PaperlessFilterOption.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  Future<PaperlessFilterOption> _createFilterOption({
    required String endpoint,
    required String name,
  }) async {
    final token = _requireAuthToken();
    final apiUri = Uri.parse(_session.serverUrl).resolve('api/$endpoint');
    final response = await _dio.postUri(
      apiUri,
      data: <String, Object?>{'name': name.trim()},
      options: Options(
        headers: <String, Object>{'Authorization': 'Token $token'},
      ),
    );

    return PaperlessFilterOption.fromJson(_asJsonMap(response.data));
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

  String _requireAuthToken() {
    final token = _session.authToken;
    if (token == null || token.isEmpty) {
      throw const DocumentsFailure('No authenticated session found.');
    }

    return token;
  }

  String _fileNameFromResponse(
    Response<List<int>> response,
    PaperlessDocument document,
  ) {
    final contentDisposition = response.headers.value('content-disposition');
    final encodedFileName = RegExp(
      r"filename\*=UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(contentDisposition ?? '');
    if (encodedFileName != null) {
      return Uri.decodeComponent(encodedFileName.group(1)!);
    }

    final plainFileName = RegExp(
      r'filename="?([^";]+)"?',
      caseSensitive: false,
    ).firstMatch(contentDisposition ?? '');
    if (plainFileName != null) {
      return plainFileName.group(1)!;
    }

    final sanitizedBaseName = document.preferredFileName
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim();
    if (sanitizedBaseName.contains('.')) {
      return sanitizedBaseName;
    }

    final extension = switch (document.mimeType) {
      'application/pdf' => '.pdf',
      'text/plain' => '.txt',
      'text/csv' => '.csv',
      _ => '',
    };

    return '$sanitizedBaseName$extension';
  }

  DocumentsFailure _uploadFailureFromDio(DioException error) {
    final response = error.response;
    final data = response?.data;

    if (data is String && data.trim().isNotEmpty) {
      return DocumentsFailure(data.trim());
    }

    if (data is Map) {
      final values = data.values
          .expand<String>((value) {
            if (value is Iterable) {
              return value.map((item) => item.toString().trim());
            }
            return <String>[value.toString().trim()];
          })
          .where((message) => message.isNotEmpty)
          .toList(growable: false);
      if (values.isNotEmpty) {
        return DocumentsFailure(values.join('\n'));
      }
    }

    return const DocumentsFailure('Could not upload the scanned document.');
  }

  String _fileNameFromPath(String filePath) {
    return Uri.file(filePath).pathSegments.last;
  }
}

class DocumentsFailure implements Exception {
  const DocumentsFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
