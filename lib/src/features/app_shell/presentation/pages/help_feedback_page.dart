import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/presentation/localization/app_localizations_x.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/help_feedback_providers.dart';

class HelpFeedbackPage extends ConsumerWidget {
  const HelpFeedbackPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final packageInfo = ref.watch(packageInfoProvider);
    final l10n = context.l10n;
    final appVersion = packageInfo.maybeWhen(
      data: (value) => '${value.version}+${value.buildNumber}',
      orElse: () => l10n.unknownLabel,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpFeedbackTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _SupportTile(
            icon: Icons.help_outline,
            title: l10n.documentationTitle,
            description: l10n.documentationDescription,
            onTap: () => _openLink(
              context,
              ref,
              Uri.parse('https://docs.paperless-ngx.com/'),
            ),
          ),
          const SizedBox(height: 12),
          _SupportTile(
            icon: Icons.feedback_outlined,
            title: l10n.reportIssueTitle,
            description: l10n.reportIssueDescription,
            onTap: () => _openLink(
              context,
              ref,
              _buildIssueUri(
                serverUrl: session.serverUrl,
                appVersion: appVersion,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SupportTile(
            icon: Icons.content_copy_outlined,
            title: l10n.copySupportSummaryTitle,
            description: l10n.copySupportSummaryDescription,
            onTap: () => _openLink(
              context,
              ref,
              _buildCopyUri(
                serverUrl: session.serverUrl,
                appVersion: appVersion,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLink(BuildContext context, WidgetRef ref, Uri uri) async {
    if (uri.scheme == 'copy') {
      await Clipboard.setData(
        ClipboardData(text: Uri.decodeComponent(uri.query)),
      );
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.supportSummaryCopied)),
        );
      return;
    }

    try {
      await ref.read(helpLinkLauncherProvider).open(uri);
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Uri _buildIssueUri({required String serverUrl, required String appVersion}) {
    final body = StringBuffer()
      ..writeln('### Context')
      ..writeln('- Flutter app version: $appVersion')
      ..writeln('- paperless-ngx server: $serverUrl')
      ..writeln()
      ..writeln('### What happened?')
      ..writeln('- Describe the issue here')
      ..writeln()
      ..writeln('### Steps to reproduce')
      ..writeln('1. ')
      ..writeln('2. ');

    return Uri.https(
      'github.com',
      '/paperless-ngx/paperless-ngx/issues/new',
      <String, String>{
        'title': 'Flutter app feedback',
        'body': body.toString(),
      },
    );
  }

  Uri _buildCopyUri({required String serverUrl, required String appVersion}) {
    return Uri(
      scheme: 'copy',
      query:
          'Flutter app version: $appVersion\npaperless-ngx server: $serverUrl',
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.open_in_new),
      ),
    );
  }
}
