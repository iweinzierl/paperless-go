import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/presentation/localization/app_localizations_x.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/help_feedback_providers.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/login_controller.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/formatters/auth_text.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  late final TextEditingController _serverUrlController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _serverUrlController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
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
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final formState = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);

    _syncController(_serverUrlController, formState.serverUrl);
    _syncController(_usernameController, formState.username);
    _syncController(_passwordController, formState.password);

    return Scaffold(
      body: ColoredBox(
        color: theme.colorScheme.surface,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompactHeight = constraints.maxHeight < 820;
              final horizontalPadding = isCompactHeight ? 20.0 : 24.0;
              final topPadding = isCompactHeight ? 16.0 : 28.0;
              final cardRadius = 12.0;
              final cardPadding = isCompactHeight
                  ? const EdgeInsets.fromLTRB(20, 20, 20, 22)
                  : const EdgeInsets.fromLTRB(24, 24, 24, 26);

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    topPadding,
                    horizontalPadding,
                    16,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      children: [
                        _LogoMark(
                          title: l10n.appTitle,
                          compact: isCompactHeight,
                        ),
                        SizedBox(height: isCompactHeight ? 10 : 18),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(cardRadius),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Padding(
                            padding: cardPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (formState.loginStatus.hasError) ...[
                                  _LoginStatusBanner(
                                    message: localizeAuthFailure(
                                      l10n,
                                      formState.loginStatus.error!,
                                      genericFallback: l10n.loginFailedGeneric,
                                    ),
                                    isError: true,
                                  ),
                                  SizedBox(height: isCompactHeight ? 14 : 20),
                                ],
                                Text(
                                  l10n.loginConnectTitle,
                                  style:
                                      (isCompactHeight
                                              ? theme.textTheme.headlineSmall
                                              : theme.textTheme.headlineMedium)
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                ),
                                SizedBox(height: isCompactHeight ? 10 : 14),
                                Text(
                                  l10n.loginConnectDescription,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(height: isCompactHeight ? 22 : 30),
                                _LoginTextField(
                                  controller: _serverUrlController,
                                  label: l10n.serverUrlLabel,
                                  hintText: l10n.serverUrlHint,
                                  keyboardType: TextInputType.url,
                                  prefixIcon: Icons.link,
                                  errorText: formState.serverUrlError(
                                    l10n.loginValidationServerUrlRequired,
                                    l10n.loginValidationFullUrl,
                                  ),
                                  onChanged: controller.updateServerUrl,
                                  compact: isCompactHeight,
                                ),
                                SizedBox(height: isCompactHeight ? 14 : 18),
                                _LoginTextField(
                                  controller: _usernameController,
                                  label: l10n.usernameLabel,
                                  hintText: l10n.usernameHint,
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icons.person_outline,
                                  errorText: formState.usernameError(
                                    l10n.loginValidationUsernameRequired,
                                  ),
                                  onChanged: controller.updateUsername,
                                  compact: isCompactHeight,
                                ),
                                SizedBox(height: isCompactHeight ? 14 : 18),
                                _LoginTextField(
                                  controller: _passwordController,
                                  label: l10n.passwordLabel,
                                  hintText: l10n.passwordHint,
                                  keyboardType: TextInputType.visiblePassword,
                                  obscureText: formState.obscurePassword,
                                  prefixIcon: Icons.lock_outline,
                                  errorText: formState.passwordError(
                                    l10n.loginValidationPasswordRequired,
                                  ),
                                  onChanged: controller.updatePassword,
                                  compact: isCompactHeight,
                                  suffixIcon: IconButton(
                                    onPressed:
                                        controller.togglePasswordVisibility,
                                    icon: Icon(
                                      formState.obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                SizedBox(height: isCompactHeight ? 20 : 28),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: formState.isSubmitting
                                        ? null
                                        : controller.submit,
                                    icon: formState.isSubmitting
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.arrow_forward),
                                    iconAlignment: IconAlignment.end,
                                    label: Text(l10n.loginButton),
                                  ),
                                ),
                                if (formState.connectedDisplayName != null) ...[
                                  SizedBox(height: isCompactHeight ? 12 : 16),
                                  Center(
                                    child: Text(
                                      l10n.connectedAs(
                                        formState.connectedDisplayName!,
                                      ),
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: isCompactHeight ? 14 : 20),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            TextButton(
                              onPressed: _openSupport,
                              child: Text(l10n.helpFeedbackTitle),
                            ),
                            Text(
                              '•',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            TextButton(
                              onPressed: _openDocumentation,
                              child: Text(l10n.documentationTitle),
                            ),
                          ],
                        ),
                        SizedBox(height: isCompactHeight ? 12 : 18),
                        Text(
                          'Powered by Paperless-ngx',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openDocumentation() async {
    await _openExternal(
      Uri.parse('https://github.com/iweinzierl/paperless-go/wiki'),
    );
  }

  Future<void> _openSupport() async {
    await _openExternal(
      Uri.parse('https://github.com/iweinzierl/paperless-go/issues'),
    );
  }

  Future<void> _openExternal(Uri uri) async {
    try {
      await ref.read(helpLinkLauncherProvider).open(uri);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _syncController(TextEditingController controller, String nextValue) {
    if (controller.text == nextValue) {
      return;
    }

    controller.value = TextEditingValue(
      text: nextValue,
      selection: TextSelection.collapsed(offset: nextValue.length),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.title, required this.compact});

  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      textAlign: TextAlign.center,
      style:
          (compact
                  ? theme.textTheme.headlineLarge
                  : theme.textTheme.displayMedium)
              ?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
                letterSpacing: compact ? -1.0 : -1.6,
              ),
    );
  }
}

class _LoginTextField extends StatelessWidget {
  const _LoginTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.keyboardType,
    required this.prefixIcon,
    required this.onChanged,
    this.obscureText = false,
    this.errorText,
    this.suffixIcon,
    this.compact = false,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final TextInputType keyboardType;
  final IconData prefixIcon;
  final ValueChanged<String> onChanged;
  final bool obscureText;
  final String? errorText;
  final Widget? suffixIcon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: compact ? 8 : 10),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            errorText: errorText,
            hintText: hintText,
            prefixIcon: Icon(prefixIcon),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

class _LoginStatusBanner extends StatelessWidget {
  const _LoginStatusBanner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = isError
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.tertiaryContainer;
    final foregroundColor = isError
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onTertiaryContainer;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: foregroundColor.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
