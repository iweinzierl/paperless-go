import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/help_feedback_providers.dart';

class HelpFeedbackPage extends ConsumerWidget {
  const HelpFeedbackPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Feedback')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _SupportTile(
            icon: Icons.help_outline,
            title: 'Documentation',
            description:
                'Open the paperless-ngx documentation for setup, usage, and API guidance.',
            onTap: () => _openLink(
              context,
              ref,
              Uri.parse('https://docs.paperless-ngx.com/'),
            ),
          ),
          const SizedBox(height: 12),
          _SupportTile(
            icon: Icons.feedback_outlined,
            title: 'Report an issue',
            description:
                'Open the upstream issue tracker to report bugs or request improvements.',
            onTap: () => _openLink(
              context,
              ref,
              Uri.parse(
                'https://github.com/paperless-ngx/paperless-ngx/issues',
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SupportTile(
            icon: Icons.forum_outlined,
            title: 'Project discussions',
            description:
                'Open the community discussions board for questions and product feedback.',
            onTap: () => _openLink(
              context,
              ref,
              Uri.parse(
                'https://github.com/paperless-ngx/paperless-ngx/discussions',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLink(BuildContext context, WidgetRef ref, Uri uri) async {
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
