import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/controllers/settings_controller.dart';

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
    _syncControllers(state);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _InfoCard(
            title: 'Connection profile',
            description: state.connectedDisplayName == null
                ? 'Update your paperless-ngx connection and verify it before saving.'
                : 'Connected as ${state.connectedDisplayName}. Saving will verify the credentials again.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _serverUrlController,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: 'Server URL',
              hintText: 'https://paperless.example.com/',
              errorText: state.serverUrlError,
            ),
            onChanged: ref
                .read(settingsControllerProvider.notifier)
                .updateServerUrl,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              errorText: state.usernameError,
            ),
            onChanged: ref
                .read(settingsControllerProvider.notifier)
                .updateUsername,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: state.passwordError,
            ),
            onChanged: ref
                .read(settingsControllerProvider.notifier)
                .updatePassword,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: state.isSaving
                ? null
                : () => ref.read(settingsControllerProvider.notifier).submit(),
            icon: state.isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(state.isSaving ? 'Saving...' : 'Save settings'),
          ),
          const SizedBox(height: 12),
          const _InfoCard(
            title: 'Next settings',
            description:
                'Cache controls, scan defaults, and review preferences can be added here later without changing the navigation model.',
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
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(title: Text(title), subtitle: Text(description)),
    );
  }
}
