import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/presentation/formatters/timestamp_text.dart';
import 'package:paperless_ngx_app/src/core/presentation/localization/app_localizations_x.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_filter_option.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';

class PaperlessDocumentListItem extends ConsumerWidget {
  const PaperlessDocumentListItem({
    required this.document,
    this.onTap,
    this.onOpen,
    this.trailingLabel,
    this.isOpening = false,
    super.key,
  });

  final PaperlessDocument document;
  final VoidCallback? onTap;
  final VoidCallback? onOpen;
  final String? trailingLabel;
  final bool isOpening;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
    final detailParts = <String>[
      if (createdLabel != null) createdLabel,
      if (document.pageCount != null) l10n.documentPages(document.pageCount!),
    ];
    final labelChips = <String>[
      if (correspondentName != null) correspondentName,
      if (documentTypeName != null) documentTypeName,
      if (tagNames.isNotEmpty) tagNames.first,
    ];

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 92,
                  height: 92,
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
                              headers: repository.buildAuthenticatedHeaders(),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _ThumbnailFallback(document: document);
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) {
                                      return child;
                                    }

                                    return ColoredBox(
                                      color: colorScheme.surfaceContainerHigh,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                        ),
                                      ),
                                    );
                                  },
                            )),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      document.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        height: 1.1,
                      ),
                    ),
                    if (labelChips.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final label in labelChips.take(2))
                            _CompactChip(label: label),
                        ],
                      ),
                    ],
                    if (detailParts.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        detailParts.join('  •  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (onOpen != null || isOpening)
                IconButton.filledTonal(
                  onPressed: isOpening ? null : onOpen,
                  tooltip: isOpening ? l10n.openingAction : l10n.openAction,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(46, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: isOpening
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        )
                      : const Icon(Icons.open_in_new_rounded),
                )
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (trailingLabel != null)
                      Text(
                        trailingLabel!,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 28,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactChip extends StatelessWidget {
  const _CompactChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
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
            theme.colorScheme.primary.withValues(alpha: 0.85),
            theme.colorScheme.primary.withValues(alpha: 0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.description_outlined,
          size: 34,
          color: theme.colorScheme.onPrimary,
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
