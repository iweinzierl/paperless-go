import 'package:flutter/material.dart';

class HelpFeedbackPage extends StatelessWidget {
  const HelpFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Feedback')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: const [
          _SupportTile(
            icon: Icons.help_outline,
            title: 'Usage help',
            description:
                'Guides for search, review, filters, and document opening can be linked from here.',
          ),
          SizedBox(height: 12),
          _SupportTile(
            icon: Icons.feedback_outlined,
            title: 'Feedback',
            description:
                'This section can later send diagnostics or route users to the project issue tracker.',
          ),
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(description),
      ),
    );
  }
}
