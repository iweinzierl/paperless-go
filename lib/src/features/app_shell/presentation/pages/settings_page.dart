import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/features/app_shell/domain/models/app_behavior_settings.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/controllers/settings_controller.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_behavior_providers.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_filter_option.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final TextEditingController _serverUrlController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(settingsControllerProvider);
    _serverUrlController = TextEditingController(text: state.serverUrl);
    _usernameController = TextEditingController(text: state.username);
    _passwordController = TextEditingController(text: state.password);
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SettingsFormState>(settingsControllerProvider, (previous, next) {
      final oldFeedback = previous?.feedbackMessage;
      final newFeedback = next.feedbackMessage;

      if (newFeedback == null ||
          newFeedback == oldFeedback ||
          !context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(newFeedback)));
    });

    final state = ref.watch(settingsControllerProvider);
    final behaviorSettings = ref.watch(appBehaviorSettingsProvider);
    final tagOptions = ref.watch(tagOptionsProvider);
    final selectedTodoTagNames = _resolveSelectedTodoTagNames(
      tagOptions.valueOrNull ?? const <PaperlessFilterOption>[],
      behaviorSettings,
    );
    _syncControllers(state);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          if (state.connectedDisplayName != null) ...[
            _ConnectionStatusBanner(
              displayName: state.connectedDisplayName!,
              serverUrl: state.serverUrl,
            ),
            const SizedBox(height: 16),
          ],
          const _SectionHeader(label: 'Connection'),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.cloud_outlined,
                title: 'Server URL',
                subtitle:
                    'Paperless-ngx endpoint used for login, sync, and downloads.',
                child: TextField(
                  controller: _serverUrlController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    hintText: 'https://paperless.example.com/',
                    errorText: state.serverUrlError,
                  ),
                  onChanged: ref
                      .read(settingsControllerProvider.notifier)
                      .updateServerUrl,
                ),
              ),
              const _SettingsDivider(),
              _SettingsTile(
                icon: Icons.person_outline,
                title: 'Username',
                subtitle: 'Account used to authenticate against the server.',
                child: TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(errorText: state.usernameError),
                  onChanged: ref
                      .read(settingsControllerProvider.notifier)
                      .updateUsername,
                ),
              ),
              const _SettingsDivider(),
              _SettingsTile(
                icon: Icons.lock_outline,
                title: 'Password',
                subtitle: 'Stored locally and verified again when you save.',
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(errorText: state.passwordError),
                  onChanged: ref
                      .read(settingsControllerProvider.notifier)
                      .updatePassword,
                ),
              ),
              const _SettingsDivider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: state.isSaving
                        ? null
                        : () => ref
                              .read(settingsControllerProvider.notifier)
                              .submit(),
                    icon: state.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(state.isSaving ? 'Saving...' : 'Save settings'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionHeader(label: 'Appearance & Behavior'),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: 'Theme mode',
                subtitle:
                    'Choose whether the app uses the light or dark color palette.',
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<AppThemeMode>(
                      value: behaviorSettings.themeMode,
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        ref
                            .read(appBehaviorSettingsProvider.notifier)
                            .setThemeMode(value);
                      },
                      items: const [
                        DropdownMenuItem(
                          value: AppThemeMode.light,
                          child: Text('Light'),
                        ),
                        DropdownMenuItem(
                          value: AppThemeMode.dark,
                          child: Text('Dark'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const _SettingsDivider(),
              _SettingsToggleTile(
                icon: Icons.image_outlined,
                title: 'Cache thumbnails and previews',
                subtitle:
                    'Persist the preference for faster browsing as local caching expands.',
                value: behaviorSettings.cachePreviewsEnabled,
                onChanged: ref
                    .read(appBehaviorSettingsProvider.notifier)
                    .setCachePreviewsEnabled,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionHeader(label: 'Todos'),
          _SettingsGroup(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.sell_outlined,
                        size: 24,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TODO tags',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select which server tags should feed the Todos tab.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 14),
                          _SelectedTodoTags(tagNames: selectedTodoTagNames),
                          const SizedBox(height: 14),
                          tagOptions.when(
                            data: (tags) {
                              return FilledButton.tonalIcon(
                                onPressed: () => _openTodoTagSelection(
                                  context,
                                  tags,
                                  _resolveSelectedTodoTagIds(
                                    tags,
                                    behaviorSettings,
                                  ),
                                ),
                                icon: const Icon(Icons.tune_outlined),
                                label: const Text('Select TODO tags'),
                              );
                            },
                            error: (error, stackTrace) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Could not load available tags.',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        ref.invalidate(tagOptionsProvider),
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retry tag loading'),
                                  ),
                                ],
                              );
                            },
                            loading: () => const Row(
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Loading available tags...'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _syncControllers(SettingsFormState state) {
    if (_serverUrlController.text != state.serverUrl) {
      _serverUrlController.value = TextEditingValue(
        text: state.serverUrl,
        selection: TextSelection.collapsed(offset: state.serverUrl.length),
      );
    }
    if (_usernameController.text != state.username) {
      _usernameController.value = TextEditingValue(
        text: state.username,
        selection: TextSelection.collapsed(offset: state.username.length),
      );
    }
    if (_passwordController.text != state.password) {
      _passwordController.value = TextEditingValue(
        text: state.password,
        selection: TextSelection.collapsed(offset: state.password.length),
      );
    }
  }

  Future<void> _openTodoTagSelection(
    BuildContext context,
    List<PaperlessFilterOption> tags,
    List<int> selectedTagIds,
  ) async {
    final selectedIds = selectedTagIds.toSet();

    final result = await showDialog<_TodoTagSelectionResult>(
      context: context,
      builder: (dialogContext) {
        final localSelection = <int>{...selectedIds};

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select TODO tags'),
              content: SizedBox(
                width: double.maxFinite,
                child: tags.isEmpty
                    ? const Text('No tags are available on the server.')
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          for (final tag in tags)
                            CheckboxListTile(
                              value: localSelection.contains(tag.id),
                              title: Text(tag.name),
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    localSelection.add(tag.id);
                                  } else {
                                    localSelection.remove(tag.id);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(
                    const _TodoTagSelectionResult(
                      tagIds: <int>[],
                      tagNames: <String>[],
                    ),
                  ),
                  child: const Text('Clear'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(
                    _TodoTagSelectionResult(
                      tagIds: tags
                          .where((tag) => localSelection.contains(tag.id))
                          .map((tag) => tag.id)
                          .toList(growable: false),
                      tagNames: tags
                          .where((tag) => localSelection.contains(tag.id))
                          .map((tag) => tag.name)
                          .toList(growable: false),
                    ),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    ref
        .read(appBehaviorSettingsProvider.notifier)
        .setTodoTagSelection(tagIds: result.tagIds, tagNames: result.tagNames);
  }

  List<int> _resolveSelectedTodoTagIds(
    List<PaperlessFilterOption> tags,
    AppBehaviorSettings settings,
  ) {
    final selectedIds = settings.normalizedTodoTagIds;
    if (selectedIds.isNotEmpty) {
      return selectedIds;
    }

    final selectedNames = settings.normalizedTodoTagNames
        .map((name) => name.toLowerCase())
        .toSet();

    return tags
        .where((tag) => selectedNames.contains(tag.name.trim().toLowerCase()))
        .map((tag) => tag.id)
        .toList(growable: false);
  }

  List<String> _resolveSelectedTodoTagNames(
    List<PaperlessFilterOption> tags,
    AppBehaviorSettings settings,
  ) {
    final selectedIds = settings.normalizedTodoTagIds.toSet();
    if (selectedIds.isNotEmpty) {
      final selectedNames = tags
          .where((tag) => selectedIds.contains(tag.id))
          .map((tag) => tag.name.trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList(growable: false);
      if (selectedNames.isNotEmpty) {
        return selectedNames;
      }
    }

    return settings.normalizedTodoTagNames;
  }
}

class _TodoTagSelectionResult {
  const _TodoTagSelectionResult({required this.tagIds, required this.tagNames});

  final List<int> tagIds;
  final List<String> tagNames;
}

class _ConnectionStatusBanner extends StatelessWidget {
  const _ConnectionStatusBanner({
    required this.displayName,
    required this.serverUrl,
  });

  final String displayName;
  final String serverUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connected as $displayName',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  serverUrl,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 60),
      child: Divider(
        height: 1,
        color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              icon,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsToggleTile extends StatelessWidget {
  const _SettingsToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              icon,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SelectedTodoTags extends StatelessWidget {
  const _SelectedTodoTags({required this.tagNames});

  final List<String> tagNames;

  @override
  Widget build(BuildContext context) {
    if (tagNames.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No TODO tags selected yet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Use Select TODO tags below to choose which documents appear in the Todos tab.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tagName in tagNames)
          Chip(label: Text(tagName), visualDensity: VisualDensity.compact),
      ],
    );
  }
}
