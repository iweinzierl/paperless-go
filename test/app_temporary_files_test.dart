import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_ngx_app/src/core/data/local/app_temporary_files.dart';
import 'package:paperless_ngx_app/src/core/providers/shared_preferences_provider.dart';
import 'package:paperless_ngx_app/src/features/auth/data/local/auth_token_storage.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory baseDirectory;
  late AppTemporaryFiles temporaryFiles;

  setUp(() async {
    baseDirectory = await Directory.systemTemp.createTemp('temp-files-test-');
    temporaryFiles = AppTemporaryFiles(baseDirectory: baseDirectory);
  });

  tearDown(() async {
    await baseDirectory.delete(recursive: true);
  });

  group('AppTemporaryFiles', () {
    test('creates the dedicated folder inside the base directory', () async {
      final directory = await temporaryFiles.directory();

      expect(directory.path, '${baseDirectory.path}/paperless_go');
      expect(directory.existsSync(), isTrue);
    });

    test('accepts a path inside the dedicated folder', () async {
      final directory = await temporaryFiles.directory();

      expect(
        await temporaryFiles.contains('${directory.path}/scan.pdf'),
        isTrue,
      );
    });

    test('rejects a sibling path with the same name prefix', () async {
      final directory = await temporaryFiles.directory();

      expect(
        await temporaryFiles.contains('${directory.path}-other/scan.pdf'),
        isFalse,
      );
      expect(
        await temporaryFiles.contains('${baseDirectory.path}/paperless_go2'),
        isFalse,
      );
      expect(
        await temporaryFiles.contains('${directory.path}/../scan.pdf'),
        isFalse,
      );
      expect(await temporaryFiles.contains(directory.path), isFalse);
    });

    test('clears every file in the dedicated folder', () async {
      final directory = await temporaryFiles.directory();
      await File('${directory.path}/a.pdf').writeAsString('a');
      await Directory('${directory.path}/nested').create();
      await File('${directory.path}/nested/b.pdf').writeAsString('b');
      final outsideFile = File('${baseDirectory.path}/keep.pdf');
      await outsideFile.writeAsString('keep');

      await temporaryFiles.clear();

      expect(directory.listSync(), isEmpty);
      expect(outsideFile.existsSync(), isTrue);
    });

    test('clearing a missing folder does not throw', () async {
      final missing = AppTemporaryFiles(
        baseDirectory: Directory('${baseDirectory.path}/missing'),
      );

      await expectLater(missing.clear(), completes);
    });

    test('deleting a missing file does not throw', () async {
      await expectLater(
        temporaryFiles.delete('${baseDirectory.path}/missing.pdf'),
        completes,
      );
    });
  });

  test('signOut clears the dedicated folder and the auth token', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'auth.token': 'token-123',
    });
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth.server_url': 'https://example.com/',
      'auth.username': 'jane',
    });
    final sharedPreferences = await SharedPreferences.getInstance();
    final tokenStorage = await AuthTokenStorage.load(
      const FlutterSecureStorage(),
      sharedPreferences,
    );
    final directory = await temporaryFiles.directory();
    await File('${directory.path}/download.pdf').writeAsString('pdf');

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        authTokenStorageProvider.overrideWithValue(tokenStorage),
        appTemporaryFilesProvider.overrideWithValue(temporaryFiles),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(authSessionProvider).authToken, 'token-123');

    await container.read(authSessionProvider.notifier).signOut();

    expect(!directory.existsSync() || directory.listSync().isEmpty, isTrue);
    expect(container.read(authSessionProvider).authToken, isEmpty);
    expect(tokenStorage.token, isNull);
  });
}
