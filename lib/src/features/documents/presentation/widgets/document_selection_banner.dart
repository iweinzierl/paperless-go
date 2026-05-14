import 'package:flutter/material.dart';

class DocumentSelectionBanner extends StatelessWidget {
  const DocumentSelectionBanner({
    required this.count,
    required this.onClear,
    this.onEdit,
    this.onDelete,
    this.isDeleting = false,
    super.key,
  });

  final int count;
  final VoidCallback onClear;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.secondary),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.checklist_rounded,
              size: 20,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count selected',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (onEdit != null)
              IconButton(
                onPressed: isDeleting ? null : onEdit,
                tooltip: 'Batch edit',
                color: theme.colorScheme.onSecondaryContainer,
                icon: const Icon(Icons.edit_outlined),
              ),
            if (onDelete != null)
              IconButton(
                onPressed: isDeleting ? null : onDelete,
                tooltip: 'Delete',
                color: theme.colorScheme.onSecondaryContainer,
                icon: isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline_rounded),
              ),
            TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSecondaryContainer,
              ),
              child: const Text('Clear'),
            ),
          ],
        ),
      ),
    );
  }
}
