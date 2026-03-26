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
    final l10n = context.l10n;
    final colorScheme = theme.colorScheme;
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
    final metadata = <Widget>[
      if (createdLabel != null)
        _MetadataItem(icon: Icons.event_outlined, label: createdLabel),
      if (document.pageCount != null)
        _MetadataItem(
          icon: Icons.description_outlined,
          label: l10n.documentPages(document.pageCount!),
        ),
    ];

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(34)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AspectRatio(
                  aspectRatio: 1.52,
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
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                            )),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                document.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.9,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 16),
              if (correspondentName != null || documentTypeName != null)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (correspondentName != null)
                      _SoftChip(label: correspondentName, emphasized: true),
                    if (documentTypeName != null)
                      _SoftChip(label: documentTypeName),
                  ],
                ),
              if (tagNames.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final tagName in tagNames.take(2))
                      _SoftChip(label: tagName),
                    if (tagNames.length > 2)
                      _SoftChip(label: '+${tagNames.length - 2}'),
                  ],
                ),
              ],
              if (metadata.isNotEmpty) ...[
                const SizedBox(height: 18),
                Wrap(spacing: 20, runSpacing: 10, children: metadata),
              ],
              if (footer != null || trailingLabel != null) ...[
                const SizedBox(height: 18),
                if (footer != null)
                  footer!
                else if (trailingLabel != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: _TrailingLabel(label: trailingLabel!),
                  ),
              ],
            ],
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
            theme.colorScheme.primary.withValues(alpha: 0.85),
            theme.colorScheme.primary.withValues(alpha: 0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Icon(
            Icons.description_outlined,
            size: 52,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({required this.label, this.emphasized = false});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = emphasized
        ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.9)
        : theme.colorScheme.surfaceContainerHigh;
    final foregroundColor = emphasized
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onSurfaceVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Text(
          label.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
          ),
        ),
      ),
    );
  }
}

class _MetadataItem extends StatelessWidget {
  const _MetadataItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TrailingLabel extends StatelessWidget {
  const _TrailingLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }
}
