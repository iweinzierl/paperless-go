import 'package:flutter/material.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';

class PaperlessDocumentCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.picture_as_pdf_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            document.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            document.subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (trailingLabel != null) ...[
                      const SizedBox(width: 12),
                      Chip(label: Text(trailingLabel!)),
                    ],
                  ],
                ),
                if (footer != null) ...[
                  const SizedBox(height: 16),
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
