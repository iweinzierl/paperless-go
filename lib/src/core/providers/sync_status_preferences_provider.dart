import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/data/local/sync_status_preferences.dart';
import 'package:paperless_ngx_app/src/core/providers/shared_preferences_provider.dart';

final syncStatusPreferencesProvider = Provider<SyncStatusPreferences>((ref) {
  return SyncStatusPreferences(ref.watch(sharedPreferencesProvider));
});
