import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

final helpLinkLauncherProvider = Provider<HelpLinkLauncher>((ref) {
  return const UrlLauncherHelpLinkLauncher();
});

final donationConfigurationProvider = Provider<DonationConfiguration>((ref) {
  return DonationConfiguration.fromEnvironment();
});

final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return PackageInfo.fromPlatform();
});

class DonationConfiguration {
  const DonationConfiguration({
    required this.urlTemplate,
    required this.currencyCode,
    required this.suggestedAmount,
  });

  factory DonationConfiguration.fromEnvironment() {
    final suggestedAmountValue = const String.fromEnvironment(
      'DONATION_SUGGESTED_AMOUNT',
      defaultValue: '1.00',
    );

    return DonationConfiguration(
      urlTemplate: const String.fromEnvironment(
        'DONATION_URL_TEMPLATE',
        defaultValue: 'https://paypal.me/IngoWeinzierl/{amount}',
      ),
      currencyCode: const String.fromEnvironment(
        'DONATION_CURRENCY',
        defaultValue: 'EUR',
      ),
      suggestedAmount: double.tryParse(suggestedAmountValue) ?? 1,
    );
  }

  final String urlTemplate;
  final String currencyCode;
  final double suggestedAmount;

  bool get isEnabled =>
      urlTemplate.trim().isNotEmpty && urlTemplate.contains('{amount}');

  String get suggestedAmountText => suggestedAmount.toStringAsFixed(2);

  Uri buildUri(double amount) {
    return Uri.parse(
      urlTemplate
          .replaceAll('{amount}', amount.toStringAsFixed(2))
          .replaceAll('{currency}', Uri.encodeComponent(currencyCode)),
    );
  }
}

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
