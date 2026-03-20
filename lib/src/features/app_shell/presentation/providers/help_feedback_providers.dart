import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

final helpLinkLauncherProvider = Provider<HelpLinkLauncher>((ref) {
  return const UrlLauncherHelpLinkLauncher();
});

final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return PackageInfo.fromPlatform();
});

abstract class HelpLinkLauncher {
  Future<void> open(Uri uri);
}

class UrlLauncherHelpLinkLauncher implements HelpLinkLauncher {
  const UrlLauncherHelpLinkLauncher();

  @override
  Future<void> open(Uri uri) async {
    final didLaunch = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!didLaunch) {
      throw HelpLinkLaunchFailure(
        'Could not open ${uri.toString()} on this device.',
      );
    }
  }
}

class HelpLinkLaunchFailure implements Exception {
  const HelpLinkLaunchFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
