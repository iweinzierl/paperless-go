import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/presentation/localization/app_localizations_x.dart';
import 'package:paperless_ngx_app/src/features/app_shell/domain/models/app_behavior_settings.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/controllers/settings_controller.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_behavior_providers.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/formatters/auth_text.dart';

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
    final l10n = context.l10n;

    ref.listen<SettingsFormState>(settingsControllerProvider, (previous, next) {
      if (!context.mounted) {
        return;
      }

      final completedSave = previous?.isSaving == true && !next.isSaving;
      if (!completedSave) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
      if (next.saveStatus.hasError) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              localizeAuthFailure(
                l10n,
                next.saveStatus.error!,
                genericFallback: l10n.settingsSaveFailedGeneric,
              ),
            ),
          ),
        );
        return;
      }

      messenger.showSnackBar(SnackBar(content: Text(l10n.settingsSaveSuccess)));
    });

    final state = ref.watch(settingsControllerProvider);
    final behaviorSettings = ref.watch(appBehaviorSettingsProvider);
    _syncControllers(state);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
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
          _SectionHeader(label: l10n.settingsConnectionSection),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.cloud_outlined,
                title: l10n.serverUrlLabel,
                subtitle: l10n.settingsServerUrlSubtitle,
                child: TextField(
                  controller: _serverUrlController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    hintText: '${l10n.serverUrlHint}/',
                    errorText: state.serverUrlError(
                      l10n.loginValidationServerUrlRequired,
                      l10n.loginValidationFullUrl,
                    ),
                  ),
                  onChanged: ref
                      .read(settingsControllerProvider.notifier)
                      .updateServerUrl,
                ),
              ),
              const _SettingsDivider(),
              _SettingsTile(
                icon: Icons.person_outline,
                title: l10n.usernameLabel,
                subtitle: l10n.settingsUsernameSubtitle,
                child: TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    errorText: state.usernameError(
                      l10n.loginValidationUsernameRequired,
                    ),
                  ),
                  onChanged: ref
                      .read(settingsControllerProvider.notifier)
                      .updateUsername,
                ),
              ),
              const _SettingsDivider(),
              _SettingsTile(
                icon: Icons.lock_outline,
                title: l10n.passwordLabel,
                subtitle: l10n.settingsPasswordSubtitle,
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    errorText: state.passwordError(
                      l10n.loginValidationPasswordRequired,
                    ),
                  ),
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
                    label: Text(
                      state.isSaving
                          ? l10n.savingAction
                          : l10n.saveSettingsAction,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionHeader(label: l10n.settingsAppearanceBehaviorSection),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.language_outlined,
                title: l10n.appLanguageTitle,
                subtitle: l10n.appLanguageSubtitle,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<AppLanguage>(
                      value: behaviorSettings.appLanguage,
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        ref
                            .read(appBehaviorSettingsProvider.notifier)
                            .setAppLanguage(value);
                      },
                      items: AppLanguage.values
                          .map(
                            (value) => DropdownMenuItem<AppLanguage>(
                              value: value,
                              child: Text(_appLanguageLabel(context, value)),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ),
              ),
              const _SettingsDivider(),
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: l10n.themeModeTitle,
                subtitle: l10n.themeModeSubtitle,
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
                      items: [
                        DropdownMenuItem(
                          value: AppThemeMode.light,
                          child: Text(l10n.themeModeLight),
                        ),
                        DropdownMenuItem(
                          value: AppThemeMode.dark,
                          child: Text(l10n.themeModeDark),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const _SettingsDivider(),
              _SettingsToggleTile(
                icon: Icons.image_outlined,
                title: l10n.cachePreviewsTitle,
                subtitle: l10n.cachePreviewsSubtitle,
                value: behaviorSettings.cachePreviewsEnabled,
                onChanged: ref
                    .read(appBehaviorSettingsProvider.notifier)
                    .setCachePreviewsEnabled,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _appLanguageLabel(BuildContext context, AppLanguage value) {
    final l10n = context.l10n;

    switch (value) {
      case AppLanguage.system:
        return l10n.appLanguageSystem;
      case AppLanguage.english:
        return l10n.appLanguageEnglish;
      case AppLanguage.german:
        return l10n.appLanguageGerman;
      case AppLanguage.french:
        return l10n.appLanguageFrench;
      case AppLanguage.italian:
        return l10n.appLanguageItalian;
      case AppLanguage.spanish:
        return l10n.appLanguageSpanish;
    }
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
    final l10n = context.l10n;

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
                  l10n.connectedAs(displayName),
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
