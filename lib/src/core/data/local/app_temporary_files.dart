import 'dart:developer';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final appTemporaryFilesProvider = Provider<AppTemporaryFiles>((ref) {
  return const AppTemporaryFiles();
});

/// Owns the app's own subfolder of the temporary directory, which holds
/// downloads, previews, composed scan PDFs and picker byte copies.
class AppTemporaryFiles {
  const AppTemporaryFiles({Directory? baseDirectory})
    : _baseDirectory = baseDirectory;

  static const folderName = 'paperless_go';

  final Directory? _baseDirectory;

  /// Returns the dedicated folder, creating it if it is missing.
  Future<Directory> directory() async {
    final directory = await _resolveDirectory();
    return directory.create(recursive: true);
  }

  /// Whether [filePath] lies inside the dedicated folder.
  Future<bool> contains(String filePath) async {
    final Directory directory;
    try {
      directory = await _resolveDirectory();
    } catch (error, stackTrace) {
      log(
        'Failed to resolve the temporary folder.',
        name: 'AppTemporaryFiles',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }

    final folderSegments = _normalizedSegments(directory.path);
    final fileSegments = _normalizedSegments(filePath);
    if (fileSegments.length <= folderSegments.length) {
      return false;
    }

    for (var index = 0; index < folderSegments.length; index++) {
      if (folderSegments[index] != fileSegments[index]) {
        return false;
      }
    }
    return true;
  }

  /// Deletes a single file. Errors are logged and ignored.
  Future<void> delete(String filePath) async {
    try {
      await File(filePath).delete();
    } catch (error, stackTrace) {
      log(
        'Failed to delete temporary file $filePath.',
        name: 'AppTemporaryFiles',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Deletes everything in the dedicated folder. Errors are logged and
  /// ignored.
  Future<void> clear() async {
    try {
      final directory = await _resolveDirectory();
      if (!await directory.exists()) {
        log(
          'Temporary folder ${directory.path} does not exist.',
          name: 'AppTemporaryFiles',
        );
        return;
      }

      await for (final entity in directory.list(followLinks: false)) {
        try {
          await entity.delete(recursive: true);
        } catch (error, stackTrace) {
          log(
            'Failed to delete temporary file ${entity.path}.',
            name: 'AppTemporaryFiles',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }
    } catch (error, stackTrace) {
      log(
        'Failed to clear the temporary folder.',
        name: 'AppTemporaryFiles',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<Directory> _resolveDirectory() async {
    final baseDirectory = _baseDirectory ?? await getTemporaryDirectory();
    return Directory('${baseDirectory.path}/$folderName');
  }

  List<String> _normalizedSegments(String path) {
    return Uri.file(File(path).absolute.path)
        .normalizePath()
        .pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
  }
}
