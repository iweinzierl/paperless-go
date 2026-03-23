import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/presentation/localization/app_localizations_x.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_filter_option.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/models/documents_filter_state.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';

enum ManageFilterOptionType { correspondents, documentTypes, tags }

enum _OptionMenuAction { rename, delete }

class ManageFilterOptionsPage extends ConsumerStatefulWidget {
  const ManageFilterOptionsPage({required this.type, super.key});

  final ManageFilterOptionType type;

  @override
  ConsumerState<ManageFilterOptionsPage> createState() =>
      _ManageFilterOptionsPageState();
}

class _ManageFilterOptionsPageState
    extends ConsumerState<ManageFilterOptionsPage> {
  bool _isSubmitting = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = _optionsForType();
    final selectedOptionId = _selectedOptionId(
      ref.watch(documentsFilterStateProvider),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForType(context)),
        actions: [
          IconButton(
            tooltip: _newActionForType(context),
            onPressed: _isSubmitting ? null : _createOption,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
          ),
        ],
      ),
      body: options.when(
        data: (items) {
          if (items.isEmpty) {
            return _EmptyOptionsState(title: _titleForType(context));
          }

          final sortedItems = items.toList(growable: false)
            ..sort((left, right) => left.name.compareTo(right.name));
          final normalizedQuery = _searchQuery.trim().toLowerCase();
          final filteredItems = normalizedQuery.isEmpty
              ? sortedItems
              : sortedItems
                    .where(
                      (item) =>
                          item.name.toLowerCase().contains(normalizedQuery),
                    )
                    .toList(growable: false);

          return CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedSearchHeaderDelegate(
                  minExtent: 84,
                  maxExtent: 84,
                  child: ColoredBox(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: context.l10n.managementSearchHint,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.trim().isEmpty
                              ? null
                              : IconButton(
                                  tooltip: context.l10n.clearSearchTooltip,
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
              if (filteredItems.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                    child: Center(
                      child: Text(
                        context.l10n.noManagementOptionsMatchSearch,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return ListTile(
                        selected: selectedOptionId == item.id,
                        tileColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        selectedTileColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(item.name),
                        trailing: PopupMenuButton<_OptionMenuAction>(
                          enabled: !_isSubmitting,
                          onSelected: (action) =>
                              _handleOptionMenuAction(item, action),
                          itemBuilder: (context) => [
                            PopupMenuItem<_OptionMenuAction>(
                              value: _OptionMenuAction.rename,
                              child: Text(context.l10n.renameAction),
                            ),
                            PopupMenuItem<_OptionMenuAction>(
                              value: _OptionMenuAction.delete,
                              child: Text(
                                context.l10n.deleteAction,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _applyFilterSelection(item),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                  ),
                ),
            ],
          );
        },
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.couldNotLoadStatus,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _refreshOptions,
                  child: Text(context.l10n.retryAction),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  AsyncValue<List<PaperlessFilterOption>> _optionsForType() {
    return switch (widget.type) {
      ManageFilterOptionType.correspondents => ref.watch(
        correspondentOptionsProvider,
      ),
      ManageFilterOptionType.documentTypes => ref.watch(
        documentTypeOptionsProvider,
      ),
      ManageFilterOptionType.tags => ref.watch(tagOptionsProvider),
    };
  }

  String _titleForType(BuildContext context) {
    final l10n = context.l10n;
    return switch (widget.type) {
      ManageFilterOptionType.correspondents => l10n.drawerCorrespondents,
      ManageFilterOptionType.documentTypes => l10n.drawerDocumentTypes,
      ManageFilterOptionType.tags => l10n.drawerTags,
    };
  }

  String _newActionForType(BuildContext context) {
    final l10n = context.l10n;
    return switch (widget.type) {
      ManageFilterOptionType.correspondents => l10n.newCorrespondentAction,
      ManageFilterOptionType.documentTypes => l10n.newDocumentTypeAction,
      ManageFilterOptionType.tags => l10n.newTagAction,
    };
  }

  String _fieldLabelForType(BuildContext context) {
    final l10n = context.l10n;
    return switch (widget.type) {
      ManageFilterOptionType.correspondents => l10n.correspondentNameLabel,
      ManageFilterOptionType.documentTypes => l10n.documentTypeNameLabel,
      ManageFilterOptionType.tags => l10n.tagNameLabel,
    };
  }

  String _createdMessageForType(BuildContext context) {
    final l10n = context.l10n;
    return switch (widget.type) {
      ManageFilterOptionType.correspondents => l10n.correspondentCreated,
      ManageFilterOptionType.documentTypes => l10n.documentTypeCreated,
      ManageFilterOptionType.tags => l10n.tagCreated,
    };
  }

  String _renameActionForType(BuildContext context) {
    final l10n = context.l10n;
    return switch (widget.type) {
      ManageFilterOptionType.correspondents => l10n.renameCorrespondentAction,
      ManageFilterOptionType.documentTypes => l10n.renameDocumentTypeAction,
      ManageFilterOptionType.tags => l10n.renameTagAction,
    };
  }

  String _renamedMessageForType(BuildContext context) {
    final l10n = context.l10n;
    return switch (widget.type) {
      ManageFilterOptionType.correspondents => l10n.correspondentRenamed,
      ManageFilterOptionType.documentTypes => l10n.documentTypeRenamed,
      ManageFilterOptionType.tags => l10n.tagRenamed,
    };
  }

  String _deleteActionForType(BuildContext context) {
    final l10n = context.l10n;
    return switch (widget.type) {
      ManageFilterOptionType.correspondents => l10n.deleteCorrespondentAction,
      ManageFilterOptionType.documentTypes => l10n.deleteDocumentTypeAction,
      ManageFilterOptionType.tags => l10n.deleteTagAction,
    };
  }

  String _deleteConfirmationMessageForType(
    BuildContext context,
    PaperlessFilterOption option,
  ) {
    final l10n = context.l10n;
    return switch (widget.type) {
      ManageFilterOptionType.correspondents =>
        l10n.deleteCorrespondentConfirmationMessage(option.name),
      ManageFilterOptionType.documentTypes =>
        l10n.deleteDocumentTypeConfirmationMessage(option.name),
      ManageFilterOptionType.tags => l10n.deleteTagConfirmationMessage(
        option.name,
      ),
    };
  }

  String _deletedMessageForType(BuildContext context) {
    final l10n = context.l10n;
    return switch (widget.type) {
      ManageFilterOptionType.correspondents => l10n.correspondentDeleted,
      ManageFilterOptionType.documentTypes => l10n.documentTypeDeleted,
      ManageFilterOptionType.tags => l10n.tagDeleted,
    };
  }

  int? _selectedOptionId(DocumentsFilterState filterState) {
    return switch (widget.type) {
      ManageFilterOptionType.correspondents => filterState.correspondentId,
      ManageFilterOptionType.documentTypes => filterState.documentTypeId,
      ManageFilterOptionType.tags => filterState.tagId,
    };
  }

  Future<void> _applyFilterSelection(PaperlessFilterOption option) async {
    final currentState = ref.read(documentsFilterStateProvider);
    final nextState = switch (widget.type) {
      ManageFilterOptionType.correspondents => currentState.copyWith(
        correspondentId: option.id,
      ),
      ManageFilterOptionType.documentTypes => currentState.copyWith(
        documentTypeId: option.id,
      ),
      ManageFilterOptionType.tags => currentState.copyWith(tagId: option.id),
    };

    ref.read(documentsFilterStateProvider.notifier).state = nextState;
    ref.read(documentsCurrentPageProvider.notifier).state = 1;
    ref.read(appShellTabProvider.notifier).state = 0;

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  Future<void> _createOption() async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (dialogContext) => _FilterOptionSheet(
        title: _newActionForType(context),
        fieldLabel: _fieldLabelForType(context),
        submitLabel: context.l10n.createAction,
      ),
    );
    if (name == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = ref.read(documentsRepositoryProvider);
      switch (widget.type) {
        case ManageFilterOptionType.correspondents:
          await repository.createCorrespondent(name: name);
          ref.invalidate(correspondentOptionsProvider);
        case ManageFilterOptionType.documentTypes:
          await repository.createDocumentType(name: name);
          ref.invalidate(documentTypeOptionsProvider);
        case ManageFilterOptionType.tags:
          await repository.createTag(name: name);
          ref.invalidate(tagOptionsProvider);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(_createdMessageForType(context))),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _renameOption(PaperlessFilterOption option) async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (dialogContext) => _FilterOptionSheet(
        title: _renameActionForType(context),
        fieldLabel: _fieldLabelForType(context),
        submitLabel: context.l10n.saveAction,
        initialValue: option.name,
      ),
    );
    if (name == null || name == option.name) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = ref.read(documentsRepositoryProvider);
      switch (widget.type) {
        case ManageFilterOptionType.correspondents:
          await repository.updateCorrespondent(
            correspondentId: option.id,
            name: name,
          );
          ref.invalidate(correspondentOptionsProvider);
        case ManageFilterOptionType.documentTypes:
          await repository.updateDocumentType(
            documentTypeId: option.id,
            name: name,
          );
          ref.invalidate(documentTypeOptionsProvider);
        case ManageFilterOptionType.tags:
          await repository.updateTag(tagId: option.id, name: name);
          ref.invalidate(tagOptionsProvider);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(_renamedMessageForType(context))),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _deleteOption(PaperlessFilterOption option) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_deleteActionForType(dialogContext)),
        content: Text(_deleteConfirmationMessageForType(dialogContext, option)),
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

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = ref.read(documentsRepositoryProvider);
      switch (widget.type) {
        case ManageFilterOptionType.correspondents:
          await repository.deleteCorrespondent(correspondentId: option.id);
          ref.invalidate(correspondentOptionsProvider);
        case ManageFilterOptionType.documentTypes:
          await repository.deleteDocumentType(documentTypeId: option.id);
          ref.invalidate(documentTypeOptionsProvider);
        case ManageFilterOptionType.tags:
          await repository.deleteTag(tagId: option.id);
          ref.invalidate(tagOptionsProvider);
      }

      _clearSelectedFilterIfNeeded(option.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(_deletedMessageForType(context))),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _clearSelectedFilterIfNeeded(int deletedOptionId) {
    final currentState = ref.read(documentsFilterStateProvider);
    final nextState = switch (widget.type) {
      ManageFilterOptionType.correspondents
          when currentState.correspondentId == deletedOptionId =>
        currentState.copyWith(clearCorrespondent: true),
      ManageFilterOptionType.documentTypes
          when currentState.documentTypeId == deletedOptionId =>
        currentState.copyWith(clearDocumentType: true),
      ManageFilterOptionType.tags when currentState.tagId == deletedOptionId =>
        currentState.copyWith(clearTag: true),
      _ => currentState,
    };

    if (identical(nextState, currentState)) {
      return;
    }

    ref.read(documentsFilterStateProvider.notifier).state = nextState;
    ref.read(documentsCurrentPageProvider.notifier).state = 1;
  }

  Future<void> _handleOptionMenuAction(
    PaperlessFilterOption option,
    _OptionMenuAction action,
  ) async {
    switch (action) {
      case _OptionMenuAction.rename:
        await _renameOption(option);
      case _OptionMenuAction.delete:
        await _deleteOption(option);
    }
  }

  void _refreshOptions() {
    switch (widget.type) {
      case ManageFilterOptionType.correspondents:
        ref.invalidate(correspondentOptionsProvider);
      case ManageFilterOptionType.documentTypes:
        ref.invalidate(documentTypeOptionsProvider);
      case ManageFilterOptionType.tags:
        ref.invalidate(tagOptionsProvider);
    }
  }
}

class _EmptyOptionsState extends StatelessWidget {
  const _EmptyOptionsState({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              context.l10n.managementOptionsEmpty,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PinnedSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _PinnedSearchHeaderDelegate({
    required this.minExtent,
    required this.maxExtent,
    required this.child,
  });

  @override
  final double minExtent;

  @override
  final double maxExtent;

  final Widget child;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _PinnedSearchHeaderDelegate oldDelegate) {
    return minExtent != oldDelegate.minExtent ||
        maxExtent != oldDelegate.maxExtent ||
        child != oldDelegate.child;
  }
}

class _FilterOptionSheet extends StatefulWidget {
  const _FilterOptionSheet({
    required this.title,
    required this.fieldLabel,
    required this.submitLabel,
    this.initialValue = '',
  });

  final String title;
  final String fieldLabel;
  final String submitLabel;
  final String initialValue;

  @override
  State<_FilterOptionSheet> createState() => _FilterOptionSheetState();
}

class _FilterOptionSheetState extends State<_FilterOptionSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, bottomInset + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(labelText: widget.fieldLabel),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.l10n.cancelAction),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _submit,
                  child: Text(widget.submitLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      return;
    }

    Navigator.of(context).pop(value);
  }
}
