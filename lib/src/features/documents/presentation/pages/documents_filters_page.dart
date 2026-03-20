import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_filter_option.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/models/documents_filter_state.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/models/documents_sort_option.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';

class DocumentsFiltersResult {
  const DocumentsFiltersResult({
    required this.filterState,
    required this.ordering,
  });

  final DocumentsFilterState filterState;
  final String ordering;
}

class DocumentsFiltersPage extends ConsumerStatefulWidget {
  const DocumentsFiltersPage({
    required this.initialFilterState,
    required this.initialOrdering,
    super.key,
  });

  final DocumentsFilterState initialFilterState;
  final String initialOrdering;

  @override
  ConsumerState<DocumentsFiltersPage> createState() =>
      _DocumentsFiltersPageState();
}

class _DocumentsFiltersPageState extends ConsumerState<DocumentsFiltersPage> {
  late DocumentsFilterState _filterState;
  late String _ordering;

  @override
  void initState() {
    super.initState();
    _filterState = widget.initialFilterState;
    _ordering = widget.initialOrdering;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filters'),
        actions: [TextButton(onPressed: _reset, child: const Text('Reset'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SortDropdown(
            selectedOrdering: _ordering,
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _ordering = value;
              });
            },
          ),
          const SizedBox(height: 16),
          _FilterDropdown(
            label: 'Tag',
            selectedId: _filterState.tagId,
            options: ref.watch(tagOptionsProvider),
            onChanged: (value) {
              setState(() {
                _filterState = _filterState.copyWith(
                  tagId: value,
                  clearTag: value == null,
                );
              });
            },
          ),
          const SizedBox(height: 16),
          _FilterDropdown(
            label: 'Correspondent',
            selectedId: _filterState.correspondentId,
            options: ref.watch(correspondentOptionsProvider),
            onChanged: (value) {
              setState(() {
                _filterState = _filterState.copyWith(
                  correspondentId: value,
                  clearCorrespondent: value == null,
                );
              });
            },
          ),
          const SizedBox(height: 16),
          _FilterDropdown(
            label: 'Document type',
            selectedId: _filterState.documentTypeId,
            options: ref.watch(documentTypeOptionsProvider),
            onChanged: (value) {
              setState(() {
                _filterState = _filterState.copyWith(
                  documentTypeId: value,
                  clearDocumentType: value == null,
                );
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FilledButton.icon(
          onPressed: _apply,
          icon: const Icon(Icons.check),
          label: const Text('Apply filters'),
        ),
      ),
    );
  }

  void _reset() {
    setState(() {
      _filterState = const DocumentsFilterState();
      _ordering = documentsSortOptions.first.ordering;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      DocumentsFiltersResult(filterState: _filterState, ordering: _ordering),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({
    required this.selectedOrdering,
    required this.onChanged,
  });

  final String selectedOrdering;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedOrdering,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Sort by',
        prefixIcon: Icon(Icons.sort),
      ),
      items: documentsSortOptions
          .map(
            (option) => DropdownMenuItem<String>(
              value: option.ordering,
              child: Text(option.label),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.selectedId,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final int? selectedId;
  final AsyncValue<List<PaperlessFilterOption>> options;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return options.when(
      data: (items) {
        return DropdownButtonFormField<int?>(
          initialValue: selectedId,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('Any')),
            ...items.map(
              (item) => DropdownMenuItem<int?>(
                value: item.id,
                child: Text(item.name),
              ),
            ),
          ],
          onChanged: onChanged,
        );
      },
      error: (error, stackTrace) {
        return TextFormField(
          enabled: false,
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Could not load',
          ),
        );
      },
      loading: () {
        return TextFormField(
          enabled: false,
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Loading...',
            suffixIcon: const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        );
      },
    );
  }
}
