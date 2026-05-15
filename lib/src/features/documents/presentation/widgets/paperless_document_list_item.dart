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
    this.onLongPress,
    this.onLeadingIconPressed,
    this.trailingLabel,
    this.showPreview = true,
    this.isSelected = false,
    super.key,
  });

  final PaperlessDocument document;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onLeadingIconPressed;
  final String? trailingLabel;
  final bool showPreview;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final documentIcon = _documentTypeIcon(document);
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
    final createdLabel = _formatTimestamp(context, document.created);
    final labelChips = <String>[
      if (correspondentName != null) correspondentName,
      if (documentTypeName != null) documentTypeName,
    ];

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: isSelected
          ? colorScheme.secondaryContainer
          : colorScheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? colorScheme.secondary
              : colorScheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: showPreview ? 12 : 10,
          ),
          child: Row(
            children: [
              if (showPreview) ...[
                InkWell(
                  onTap: onLeadingIconPressed,
                  borderRadius: BorderRadius.circular(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
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
                                          color:
                                              colorScheme.surfaceContainerHigh,
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
                ),
                const SizedBox(width: 12),
              ],
              if (!showPreview) ...[
                IconButton(
                  onPressed: onLeadingIconPressed,
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    backgroundColor: isSelected
                        ? colorScheme.secondary
                        : colorScheme.surfaceContainerHigh,
                    foregroundColor: isSelected
                        ? colorScheme.onSecondary
                        : colorScheme.onSurfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(
                    isSelected ? Icons.check_circle_rounded : documentIcon,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      document.title,
                      maxLines: showPreview ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    if (createdLabel != null || labelChips.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (createdLabel != null)
                            Text(
                              createdLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          for (final label in labelChips.take(2))
                            _CompactChip(label: label),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingLabel != null) ...[
                SizedBox(width: showPreview ? 12 : 8),
                Text(
                  trailingLabel!,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 100),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
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
        color: theme.colorScheme.surfaceContainerHigh,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Center(
        child: Icon(
          _documentTypeIcon(document),
          size: 34,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

IconData _documentTypeIcon(PaperlessDocument document) {
  final mimeType = document.mimeType?.trim().toLowerCase();
  if (mimeType != null && mimeType.startsWith('image/')) {
    return Icons.image_outlined;
  }

  final fileName = document.preferredFileName.toLowerCase();
  if (_hasImageExtension(fileName)) {
    return Icons.image_outlined;
  }

  return Icons.description_outlined;
}

bool _hasImageExtension(String fileName) {
  const imageExtensions = <String>{
    '.png',
    '.jpg',
    '.jpeg',
    '.gif',
    '.bmp',
    '.webp',
    '.tif',
    '.tiff',
    '.heic',
    '.heif',
  };

  for (final extension in imageExtensions) {
    if (fileName.endsWith(extension)) {
      return true;
    }
  }

  return false;
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
