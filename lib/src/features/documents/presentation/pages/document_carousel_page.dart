import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/presentation/localization/app_localizations_x.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/providers/current_user_capabilities_provider.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/document_carousel_source.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document_page.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/document_detail_page.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_delete_controller.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_detail_provider.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_open_controller.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';

enum _CarouselAction { openOriginal, delete }

class DocumentCarouselPage extends ConsumerStatefulWidget {
  const DocumentCarouselPage({
    required this.documentIds,
    required this.initialIndex,
    required this.source,
    super.key,
  });

  final List<int> documentIds;
  final int initialIndex;
  final DocumentCarouselSource source;

  @override
  ConsumerState<DocumentCarouselPage> createState() =>
      _DocumentCarouselPageState();
}

class _DocumentCarouselPageState extends ConsumerState<DocumentCarouselPage> {
  late final PageController _pageController;
  late List<int> _documentIds;
  late int _currentIndex;

  /// Lowest server-page number currently loaded (1-based).
  late int _loadedServerPageMin;

  /// Highest server-page number currently loaded (1-based).
  late int _loadedServerPageMax;

  bool _loadingPrev = false;
  bool _loadingNext = false;

  static const int _prefetchThreshold = 2;

  @override
  void initState() {
    super.initState();
    _documentIds = List<int>.from(widget.documentIds);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    if (widget.source case final DocumentListSource source) {
      _loadedServerPageMin = source.currentServerPage;
      _loadedServerPageMax = source.currentServerPage;
    } else {
      _loadedServerPageMin = 1;
      _loadedServerPageMax = 1;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Navigation helpers
  // ---------------------------------------------------------------------------

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _prefetchIfNeeded(index);
  }

  void _navigatePrev() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateNext() {
    if (_currentIndex < _documentIds.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool get _canNavigatePrev {
    if (_currentIndex > 0) return true;
    // At first item — can go prev only if there is a loadable previous page
    if (widget.source is DocumentListSource) {
      return !_loadingPrev && _loadedServerPageMin > 1;
    }
    return false;
  }

  bool get _canNavigateNext {
    if (_currentIndex < _documentIds.length - 1) return true;
    // At last item — can go next only if there are more server pages
    if (widget.source case final DocumentListSource listSource) {
      final loadedCount = _loadedServerPageMax * 20;
      return !_loadingNext && loadedCount < listSource.totalCount;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Prefetch logic
  // ---------------------------------------------------------------------------

  void _prefetchIfNeeded(int index) {
    if (widget.source case final DocumentListSource listSource) {
      final loadedCount = _loadedServerPageMax * 20;
      if (!_loadingNext &&
          index >= _documentIds.length - _prefetchThreshold &&
          loadedCount < listSource.totalCount) {
        _fetchNextPage(listSource);
      }

      if (!_loadingPrev &&
          index <= _prefetchThreshold &&
          _loadedServerPageMin > 1) {
        _fetchPrevPage(listSource);
      }
    }
  }

  Future<void> _fetchNextPage(DocumentListSource source) async {
    setState(() => _loadingNext = true);

    try {
      final repository = ref.read(documentsRepositoryProvider);
      final nextPage = _loadedServerPageMax + 1;
      final PaperlessDocumentPage result;

      if (source.activeSavedView != null) {
        result = await repository.fetchDocumentsForSavedView(
          savedView: source.activeSavedView!,
          page: nextPage,
        );
      } else {
        result = await repository.fetchDocuments(
          page: nextPage,
          ordering: source.ordering,
          titleFilter: source.searchQuery,
          tagIds: source.filters.tagIds,
          correspondentId: source.filters.correspondentId,
          documentTypeId: source.filters.documentTypeId,
          createdFrom: source.filters.createdFrom,
          createdTo: source.filters.createdTo,
        );
      }

      if (!mounted) return;

      setState(() {
        _loadedServerPageMax = nextPage;
        _documentIds.addAll(result.results.map((d) => d.id));
        _loadingNext = false;
      });
    } catch (error) {
      log('DocumentCarouselPage: error fetching next page: $error');
      if (!mounted) return;
      setState(() => _loadingNext = false);
    }
  }

  Future<void> _fetchPrevPage(DocumentListSource source) async {
    setState(() => _loadingPrev = true);

    try {
      final repository = ref.read(documentsRepositoryProvider);
      final prevPage = _loadedServerPageMin - 1;
      final PaperlessDocumentPage result;

      if (source.activeSavedView != null) {
        result = await repository.fetchDocumentsForSavedView(
          savedView: source.activeSavedView!,
          page: prevPage,
        );
      } else {
        result = await repository.fetchDocuments(
          page: prevPage,
          ordering: source.ordering,
          titleFilter: source.searchQuery,
          tagIds: source.filters.tagIds,
          correspondentId: source.filters.correspondentId,
          documentTypeId: source.filters.documentTypeId,
          createdFrom: source.filters.createdFrom,
          createdTo: source.filters.createdTo,
        );
      }

      if (!mounted) return;

      final newIds = result.results.map((d) => d.id).toList();
      final insertCount = newIds.length;

      setState(() {
        _loadedServerPageMin = prevPage;
        _documentIds.insertAll(0, newIds);
        _currentIndex += insertCount;
        _loadingPrev = false;
      });

      // Jump forward by the number of prepended items so the current document
      // stays on screen without a visible page shift.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentIndex);
        }
      });
    } catch (error) {
      log('DocumentCarouselPage: error fetching previous page: $error');
      if (!mounted) return;
      setState(() => _loadingPrev = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Document actions
  // ---------------------------------------------------------------------------

  Future<void> _openOriginalDocument(BuildContext context) async {
    final docId = _documentIds[_currentIndex];
    final document = ref.read(documentDetailProvider(docId)).valueOrNull;
    if (document == null) return;

    try {
      ref.read(recentlyOpenedDocumentsProvider.notifier).record(document);
      await ref
          .read(documentOpenControllerProvider.notifier)
          .openDocument(document, original: true);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _deleteCurrentDocument(BuildContext context) async {
    final docId = _documentIds[_currentIndex];
    final document = ref.read(documentDetailProvider(docId)).valueOrNull;
    if (document == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.deleteDocumentAction),
        content: Text(
          dialogContext.l10n.deleteDocumentConfirmationMessage(document.title),
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

    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await ref
          .read(documentDeleteControllerProvider.notifier)
          .deleteDocument(document);

      if (!context.mounted) return;

      final removedIndex = _documentIds.indexOf(docId);

      setState(() {
        _documentIds.remove(docId);
        if (_documentIds.isEmpty) {
          return;
        }
        if (_currentIndex >= _documentIds.length) {
          _currentIndex = _documentIds.length - 1;
        }
      });

      if (_documentIds.isEmpty) {
        navigator.pop();
        return;
      }

      // If we deleted before or at the current position, the PageController
      // page index may now be out of sync — jump to the updated current index.
      if (removedIndex <= _currentIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(_currentIndex);
          }
        });
      }

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.l10n.documentDeleted)));
    } catch (error) {
      if (!context.mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final currentDocId = _documentIds.isNotEmpty
        ? _documentIds[_currentIndex]
        : null;

    final documentAsync = currentDocId != null
        ? ref.watch(documentDetailProvider(currentDocId))
        : null;

    final document = documentAsync?.valueOrNull;
    final capabilities = ref.watch(currentUserCapabilitiesProvider).valueOrNull;
    final deletingIds = ref.watch(documentDeleteControllerProvider);
    final isDeleting =
        currentDocId != null && deletingIds.contains(currentDocId);

    final canSeeDeleteAction =
        document != null &&
        capabilities != null &&
        capabilities.hasPermission('delete_document');

    final canDeleteDocument =
        document != null &&
        capabilities != null &&
        document.canBeDeletedBy(capabilities);

    final List<Widget> appBarActions = [
      if (_loadingPrev || _loadingNext)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      IconButton(
        icon: const Icon(Icons.chevron_left),
        tooltip: context.l10n.previousDocumentTooltip,
        onPressed: _canNavigatePrev ? _navigatePrev : null,
      ),
      IconButton(
        icon: const Icon(Icons.chevron_right),
        tooltip: context.l10n.nextDocumentTooltip,
        onPressed: _canNavigateNext ? _navigateNext : null,
      ),
      if (isDeleting)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        )
      else if (document != null)
        PopupMenuButton<_CarouselAction>(
          onSelected: (action) {
            switch (action) {
              case _CarouselAction.openOriginal:
                _openOriginalDocument(context);
              case _CarouselAction.delete:
                _deleteCurrentDocument(context);
            }
          },
          itemBuilder: (context) {
            final items = <PopupMenuEntry<_CarouselAction>>[
              PopupMenuItem<_CarouselAction>(
                value: _CarouselAction.openOriginal,
                child: Text(context.l10n.openOriginalAction),
              ),
            ];

            if (canSeeDeleteAction) {
              items.add(
                PopupMenuItem<_CarouselAction>(
                  value: _CarouselAction.delete,
                  enabled: canDeleteDocument,
                  child: Text(context.l10n.deleteDocumentAction),
                ),
              );
            }

            return items;
          },
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          document?.title ?? context.l10n.documentDetailsTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: appBarActions,
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: _documentIds.length,
        itemBuilder: (context, index) {
          return DocumentDetailPage(
            key: ValueKey(_documentIds[index]),
            documentId: _documentIds[index],
            embedded: true,
          );
        },
      ),
    );
  }
}
