import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/features/app_shell/domain/models/recently_opened_document.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/document_detail_page.dart';

class RecentlyOpenedPage extends ConsumerWidget {
  const RecentlyOpenedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(recentlyOpenedDocumentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recently opened'),
        actions: [
          IconButton(
            tooltip: 'Clear history',
            onPressed: documents.isEmpty
                ? null
                : () => _confirmClearHistory(context, ref),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: documents.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Documents you open or inspect will appear here.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: documents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final document = documents[index];
                return _RecentDocumentTile(document: document);
              },
            ),
    );
  }

  Future<void> _confirmClearHistory(BuildContext context, WidgetRef ref) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear recently opened?'),
          content: const Text(
            'This removes the local history of documents you opened from the drawer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true || !context.mounted) {
      return;
    }

    ref.read(recentlyOpenedDocumentsProvider.notifier).clear();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Recently opened cleared.')));
  }
}

class _RecentDocumentTile extends StatelessWidget {
  const _RecentDocumentTile({required this.document});

  final RecentlyOpenedDocument document;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => DocumentDetailPage(documentId: document.id),
            ),
          );
        },
        leading: const CircleAvatar(child: Icon(Icons.history)),
        title: Text(document.title),
        subtitle: Text(
          '${_formatOpenedAt(document.openedAt)} · ${document.subtitle}',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  String _formatOpenedAt(DateTime value) {
    final hours = value.hour.toString().padLeft(2, '0');
    final minutes = value.minute.toString().padLeft(2, '0');
    return 'Opened $hours:$minutes';
  }
}
