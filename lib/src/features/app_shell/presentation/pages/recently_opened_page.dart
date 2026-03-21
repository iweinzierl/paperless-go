import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/presentation/formatters/document_text.dart';
import 'package:paperless_ngx_app/src/core/presentation/localization/app_localizations_x.dart';
import 'package:paperless_ngx_app/src/features/app_shell/domain/models/recently_opened_document.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/document_detail_page.dart';

class RecentlyOpenedPage extends ConsumerWidget {
  const RecentlyOpenedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(recentlyOpenedDocumentsProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recentlyOpenedTitle),
        actions: [
          IconButton(
            tooltip: l10n.clearHistoryTooltip,
            onPressed: documents.isEmpty
                ? null
                : () => _confirmClearHistory(context, ref),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: documents.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.recentlyOpenedEmpty,
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
          title: Text(context.l10n.clearRecentlyOpenedTitle),
          content: Text(context.l10n.clearRecentlyOpenedDescription),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.l10n.cancelAction),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.l10n.clearAction),
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
      ..showSnackBar(
        SnackBar(content: Text(context.l10n.recentlyOpenedCleared)),
      );
  }
}

class _RecentDocumentTile extends StatelessWidget {
  const _RecentDocumentTile({required this.document});

  final RecentlyOpenedDocument document;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localizedSubtitle =
        document.added != null ||
            document.created != null ||
            document.pageCount != null ||
            document.archiveSerialNumber != null
        ? formatDocumentSubtitle(
            l10n: l10n,
            localeName: context.localeName,
            id: document.id,
            added: document.added,
            created: document.created,
            pageCount: document.pageCount,
            archiveSerialNumber: document.archiveSerialNumber,
          )
        : document.legacySubtitle ?? '';

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
          '${_formatOpenedAt(context, document.openedAt)} · $localizedSubtitle',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  String _formatOpenedAt(BuildContext context, DateTime value) {
    final hours = value.hour.toString().padLeft(2, '0');
    final minutes = value.minute.toString().padLeft(2, '0');
    return context.l10n.openedAtLabel('$hours:$minutes');
  }
}
