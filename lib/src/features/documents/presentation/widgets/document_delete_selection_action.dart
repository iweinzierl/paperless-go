import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/presentation/localization/app_localizations_x.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_delete_controller.dart';

Future<void> confirmAndDeleteSelectedDocuments({
  required BuildContext context,
  required WidgetRef ref,
  required List<PaperlessDocument> documents,
  required VoidCallback onDeleted,
}) async {
  if (documents.isEmpty) {
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        documents.length == 1
            ? dialogContext.l10n.deleteDocumentAction
            : dialogContext.l10n.deleteDocumentsAction,
      ),
      content: Text(
        documents.length == 1
            ? dialogContext.l10n.deleteDocumentConfirmationMessage(
                documents.single.title,
              )
            : dialogContext.l10n.deleteDocumentsConfirmationMessage(
                documents.length,
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(dialogContext.l10n.cancelAction),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(dialogContext.l10n.deleteAction),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) {
    return;
  }

  final messenger = ScaffoldMessenger.of(context);

  try {
    await ref
        .read(documentDeleteControllerProvider.notifier)
        .deleteDocuments(documents);

    if (!context.mounted) {
      return;
    }

    onDeleted();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            documents.length == 1
                ? context.l10n.documentDeleted
                : context.l10n.documentsDeleted(documents.length),
          ),
        ),
      );
  } catch (error) {
    if (!context.mounted) {
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error.toString())));
  }
}
