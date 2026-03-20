import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: const [
          _InfoCard(
            title: 'Server connection',
            description:
                'Connection and account settings will be managed here in a follow-up step.',
          ),
          SizedBox(height: 12),
          _InfoCard(
            title: 'App behavior',
            description:
                'Future options can cover caching, downloads, scan defaults, and review workflows.',
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(title: Text(title), subtitle: Text(description)),
    );
  }
}
