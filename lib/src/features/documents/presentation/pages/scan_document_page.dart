import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/presentation/localization/app_localizations_x.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_scan_controller.dart';

class ScanDocumentPage extends ConsumerWidget {
  const ScanDocumentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(documentScanControllerProvider);
    final controller = ref.read(documentScanControllerProvider.notifier);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanDocumentTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.scanDocumentDescription),
              const SizedBox(height: 16),
              if (state.isBusy) const LinearProgressIndicator(),
              if (state.isBusy) const SizedBox(height: 16),
              if (state.hasPages) ...[
                TextField(
                  enabled: !state.isBusy,
                  onChanged: controller.updateTitle,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: l10n.scanDocumentTitleFieldLabel,
                    hintText: l10n.scanDocumentTitleFieldHint,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.scanDocumentPages(state.pagePaths.length),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: state.pagePaths.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _ScannedPageCard(
                        index: index,
                        path: state.pagePaths[index],
                        onRemove: state.isBusy
                            ? null
                            : () => controller.removePageAt(index),
                      );
                    },
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.document_scanner_outlined,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.scanDocumentEmptyTitle,
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.scanDocumentEmptyDescription,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.isBusy
                          ? null
                          : () => _scanPages(
                              context,
                              ref,
                              replaceExisting: false,
                            ),
                      icon: const Icon(Icons.document_scanner_outlined),
                      label: Text(
                        state.hasPages
                            ? l10n.scanDocumentAddPagesAction
                            : l10n.scanDocumentAction,
                      ),
                    ),
                  ),
                  if (state.hasPages) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: state.isBusy
                            ? null
                            : () => _scanPages(
                                context,
                                ref,
                                replaceExisting: true,
                              ),
                        icon: const Icon(Icons.restart_alt),
                        label: Text(l10n.scanDocumentReplacePagesAction),
                      ),
                    ),
                  ],
                ],
              ),
              if (state.hasPages) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: state.isBusy
                        ? null
                        : () => _upload(context, ref),
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: Text(
                      state.isUploading
                          ? l10n.scanDocumentUploadingAction
                          : l10n.scanDocumentUploadAction,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scanPages(
    BuildContext context,
    WidgetRef ref, {
    required bool replaceExisting,
  }) async {
    try {
      await ref
          .read(documentScanControllerProvider.notifier)
          .scanPages(replaceExisting: replaceExisting);
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.scanDocumentScanFailed)),
        );
    }
  }

  Future<void> _upload(BuildContext context, WidgetRef ref) async {
    try {
      final taskId = await ref
          .read(documentScanControllerProvider.notifier)
          .upload();
      if (!context.mounted) {
        return;
      }

      Navigator.of(context).pop(taskId);
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      final message =
          error is DocumentsFailure && error.message.trim().isNotEmpty
          ? error.message
          : context.l10n.scanDocumentUploadFailed;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _ScannedPageCard extends StatelessWidget {
  const _ScannedPageCard({
    required this.index,
    required this.path,
    required this.onRemove,
  });

  final int index;
  final String path;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const ColoredBox(
                  color: Color(0x11000000),
                  child: Center(
                    child: Icon(Icons.broken_image_outlined, size: 48),
                  ),
                );
              },
            ),
          ),
          ListTile(
            title: Text(l10n.scannedPageLabel(index + 1)),
            subtitle: Text(
              Uri.file(path).pathSegments.last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              tooltip: l10n.removeScannedPageTooltip,
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        ],
      ),
    );
  }
}
