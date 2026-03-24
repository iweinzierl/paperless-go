import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/presentation/formatters/timestamp_text.dart';
import 'package:paperless_ngx_app/src/core/presentation/localization/app_localizations_x.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_filter_option.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';

class PaperlessDocumentCard extends ConsumerWidget {
  const PaperlessDocumentCard({
    required this.document,
    this.footer,
    this.onTap,
    this.trailingLabel,
    super.key,
  });

  final PaperlessDocument document;
  final Widget? footer;
  final VoidCallback? onTap;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final repository = ref.watch(documentsRepositoryProvider);
    final thumbnailWidget = repository.buildDocumentThumbnailWidget(document);
    final thumbnailImageProvider = repository
        .buildDocumentThumbnailImageProvider(document.id);
    final correspondentName = _resolveOptionName(
      ref.watch(correspondentOptionsProvider),
      document.correspondentId,
    );
    final documentTypeName = _resolveOptionName(
      ref.watch(documentTypeOptionsProvider),
      document.documentTypeId,
    );
    final tagNames = _resolveTagNames(
      ref.watch(tagOptionsProvider),
      document.tags,
    );
    final createdLabel = _formatTimestamp(context, document.created);
    final addedLabel = _formatTimestamp(context, document.added);
    final metadataLabels = <Widget>[
      if (createdLabel != null)
        _MetadataPill(
          icon: Icons.event_outlined,
          label: l10n.createdLabel,
          value: createdLabel,
        ),
      if (document.pageCount != null)
        _MetadataPill(
          icon: Icons.layers_outlined,
          label: l10n.documentPages(document.pageCount!),
        ),
      if (document.archiveSerialNumber != null)
        _MetadataPill(
          icon: Icons.confirmation_number_outlined,
          label: l10n.archiveSerialNumberLabel,
          value: document.archiveSerialNumber.toString(),
        ),
      if (createdLabel == null && addedLabel != null)
        _MetadataPill(
          icon: Icons.schedule_outlined,
          label: l10n.addedLabel,
          value: addedLabel,
        ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(
            alpha: isDark ? 0.35 : 0.12,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.16)
                : const Color(0x0D0F172A),
            blurRadius: isDark ? 10 : 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        width: 88,
                        height: 116,
                        child:
                            thumbnailWidget ??
                            (thumbnailImageProvider != null
                                ? Image(
                                    image: thumbnailImageProvider,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    repository
                                        .buildDocumentThumbnailUri(document.id)
                                        .toString(),
                                    headers: repository
                                        .buildAuthenticatedHeaders(),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _ThumbnailFallback(
                                        document: document,
                                      );
                                    },
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }

                                          return ColoredBox(
                                            color: theme
                                                .colorScheme
                                                .surfaceContainerHigh,
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        },
                                  )),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  document.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurface,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              if (trailingLabel != null) ...[
                                const SizedBox(width: 12),
                                _StatusChip(label: trailingLabel!),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (correspondentName != null)
                                _EntityChip(
                                  icon: Icons.person_outline,
                                  label: correspondentName,
                                ),
                              if (documentTypeName != null)
                                _EntityChip(
                                  icon: Icons.category_outlined,
                                  label: documentTypeName,
                                ),
                            ],
                          ),
                          if (metadataLabels.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: metadataLabels,
                            ),
                          ],
                          if (tagNames.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final tagName in tagNames.take(3))
                                  _TagChip(label: tagName),
                                if (tagNames.length > 3)
                                  _TagChip(
                                    label:
                                        '+${tagNames.length - 3} ${l10n.tagsLabel.toLowerCase()}',
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (footer != null) ...[
                  const SizedBox(height: 14),
                  Align(alignment: Alignment.centerRight, child: footer),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String? _resolveOptionName(
  AsyncValue<List<PaperlessFilterOption>> options,
  int? id,
) {
  if (id == null) {
    return null;
  }

  return options.maybeWhen(
    data: (items) {
      for (final item in items) {
        if (item.id == id) {
          return item.name;
        }
      }
      return null;
    },
    orElse: () => null,
  );
}

List<String> _resolveTagNames(
  AsyncValue<List<PaperlessFilterOption>> options,
  List<int> ids,
) {
  if (ids.isEmpty) {
    return const <String>[];
  }

  return options.maybeWhen(
    data: (items) {
      final namesById = <int, String>{
        for (final item in items) item.id: item.name,
      };
      return ids
          .map((id) => namesById[id])
          .whereType<String>()
          .toList(growable: false);
    },
    orElse: () => const <String>[],
  );
}

String? _formatTimestamp(BuildContext context, String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  return formatAbsoluteDate(parsed, localeName: context.localeName);
}

class _ThumbnailFallback extends StatelessWidget {
  const _ThumbnailFallback({required this.document});

  final PaperlessDocument document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.description_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            const Spacer(),
            Text(
              '#${document.id}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              document.preferredFileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EntityChip extends StatelessWidget {
  const _EntityChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetadataPill extends StatelessWidget {
  const _MetadataPill({required this.icon, required this.label, this.value});

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = value == null ? label : '$label: $value';
    return Tooltip(
      message: text,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.16),
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
