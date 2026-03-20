import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_filter_option.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_detail_provider.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_open_controller.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';

class DocumentDetailPage extends ConsumerWidget {
  const DocumentDetailPage({required this.documentId, super.key});

  final int documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentAsync = ref.watch(documentDetailProvider(documentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Document details')),
      body: documentAsync.when(
        data: (document) => _DocumentDetailBody(document: document),
        error: (error, stackTrace) => _DocumentDetailError(
          onRetry: () => ref.invalidate(documentDetailProvider(documentId)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _DocumentDetailBody extends ConsumerWidget {
  const _DocumentDetailBody({required this.document});

  final PaperlessDocument document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openingIds = ref.watch(documentOpenControllerProvider);
    final isOpening = openingIds.contains(document.id);
    final theme = Theme.of(context);
    final session = ref.watch(authSessionProvider);
    final repository = ref.watch(documentsRepositoryProvider);
    final correspondentOptions = ref.watch(correspondentOptionsProvider);
    final documentTypeOptions = ref.watch(documentTypeOptionsProvider);
    final tagOptions = ref.watch(tagOptionsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primaryContainer,
                theme.colorScheme.surfaceContainerHighest,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            document.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            document.subtitle,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: isOpening
                          ? null
                          : () => _openDocument(context, ref, document),
                      icon: Icon(
                        isOpening ? Icons.hourglass_top : Icons.open_in_new,
                      ),
                      label: Text(isOpening ? 'Opening...' : 'Open document'),
                    ),
                    OutlinedButton.icon(
                      onPressed: isOpening
                          ? null
                          : () => _openDocument(
                              context,
                              ref,
                              document,
                              original: true,
                            ),
                      icon: const Icon(Icons.file_download_outlined),
                      label: const Text('Open original'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _DetailSection(
          title: 'Thumbnail preview',
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.network(
                  repository.buildDocumentThumbnailUri(document.id).toString(),
                  headers: repository.buildAuthenticatedHeaders(),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }

                    return const ColoredBox(
                      color: Color(0xFFF2F4F7),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.image_not_supported_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 12),
                              const Text('No thumbnail preview available.'),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Authenticated thumbnail request for ${session.serverUrl}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _DetailSection(
          title: 'Metadata',
          children: [
            _DetailRow(label: 'File name', value: document.preferredFileName),
            _DetailRow(label: 'Mime type', value: document.mimeType),
            _DetailRow(label: 'Created', value: document.created),
            _DetailRow(label: 'Added', value: document.added),
            _DetailRow(label: 'Pages', value: document.pageCount?.toString()),
            _DetailRow(
              label: 'Archive serial number',
              value: document.archiveSerialNumber?.toString(),
            ),
            _ResolvedOptionRow(
              label: 'Correspondent',
              optionId: document.correspondentId,
              options: correspondentOptions,
              fallbackValue: document.correspondentId?.toString(),
            ),
            _ResolvedOptionRow(
              label: 'Document type',
              optionId: document.documentTypeId,
              options: documentTypeOptions,
              fallbackValue: document.documentTypeId?.toString(),
            ),
            _ResolvedTagsRow(document: document, options: tagOptions),
          ],
        ),
        if (document.content != null &&
            document.content!.trim().isNotEmpty) ...[
          const SizedBox(height: 20),
          _DetailSection(
            title: 'Content preview',
            children: [
              Text(document.content!.trim(), style: theme.textTheme.bodyMedium),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _openDocument(
    BuildContext context,
    WidgetRef ref,
    PaperlessDocument document, {
    bool original = false,
    DocumentOpenVariant variant = DocumentOpenVariant.download,
  }) async {
    try {
      await ref
          .read(documentOpenControllerProvider.notifier)
          .openDocument(document, original: original, variant: variant);
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _ResolvedOptionRow extends StatelessWidget {
  const _ResolvedOptionRow({
    required this.label,
    required this.optionId,
    required this.options,
    this.fallbackValue,
  });

  final String label;
  final int? optionId;
  final AsyncValue<List<PaperlessFilterOption>> options;
  final String? fallbackValue;

  @override
  Widget build(BuildContext context) {
    if (optionId == null) {
      return const SizedBox.shrink();
    }

    return options.when(
      data: (items) {
        final match = items.where((item) => item.id == optionId).firstOrNull;
        return _DetailRow(
          label: label,
          value: match?.name ?? fallbackValue ?? optionId.toString(),
        );
      },
      error: (error, stackTrace) =>
          _DetailRow(label: label, value: fallbackValue ?? optionId.toString()),
      loading: () => _DetailRow(label: label, value: 'Loading...'),
    );
  }
}

class _ResolvedTagsRow extends StatelessWidget {
  const _ResolvedTagsRow({required this.document, required this.options});

  final PaperlessDocument document;
  final AsyncValue<List<PaperlessFilterOption>> options;

  @override
  Widget build(BuildContext context) {
    if (document.tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return options.when(
      data: (items) {
        final names = document.tags
            .map(
              (tagId) =>
                  items.where((item) => item.id == tagId).firstOrNull?.name ??
                  '#$tagId',
            )
            .toList();
        return _DetailRow(label: 'Tags', value: names.join(', '));
      },
      error: (error, stackTrace) =>
          _DetailRow(label: 'Tags', value: document.tags.join(', ')),
      loading: () => const _DetailRow(label: 'Tags', value: 'Loading...'),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value!)),
        ],
      ),
    );
  }
}

class _DocumentDetailError extends StatelessWidget {
  const _DocumentDetailError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Could not load the document details.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
