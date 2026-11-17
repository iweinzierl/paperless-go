import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/core/presentation/localization/app_localizations_x.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/help_feedback_providers.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_method.dart';
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
  late final TextEditingController _tokenController;
  late final TextEditingController _mfaCodeController;
  late final TextEditingController _customHeadersController;
  late final TextEditingController _certificatePasswordController;

  @override
  void initState() {
    super.initState();
    _serverUrlController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _tokenController = TextEditingController();
    _mfaCodeController = TextEditingController();
    _customHeadersController = TextEditingController();
    _certificatePasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _tokenController.dispose();
    _mfaCodeController.dispose();
    _customHeadersController.dispose();
    _certificatePasswordController.dispose();
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
    _syncController(_tokenController, formState.token);
    _syncController(_mfaCodeController, formState.mfaCode);
    _syncController(_customHeadersController, formState.customHeaders);
    _syncController(
      _certificatePasswordController,
      formState.clientCertificatePassword,
    );

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
                                SizedBox(height: isCompactHeight ? 18 : 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: SegmentedButton<PaperlessAuthMethod>(
                                    segments: [
                                      ButtonSegment<PaperlessAuthMethod>(
                                        value: PaperlessAuthMethod.password,
                                        label: Text(l10n.loginMethodPassword),
                                      ),
                                      ButtonSegment<PaperlessAuthMethod>(
                                        value: PaperlessAuthMethod.token,
                                        label: Text(l10n.loginMethodToken),
                                      ),
                                    ],
                                    selected: {formState.method},
                                    showSelectedIcon: false,
                                    onSelectionChanged: formState.isSubmitting
                                        ? null
                                        : (selection) => controller
                                              .updateMethod(selection.first),
                                  ),
                                ),
                                SizedBox(height: isCompactHeight ? 18 : 24),
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
                                if (formState.isTokenMethod) ...[
                                  SizedBox(height: isCompactHeight ? 14 : 18),
                                  _LoginTextField(
                                    controller: _tokenController,
                                    label: l10n.apiTokenLabel,
                                    hintText: l10n.apiTokenHint,
                                    keyboardType: TextInputType.visiblePassword,
                                    obscureText: formState.obscureToken,
                                    prefixIcon: Icons.key_outlined,
                                    errorText: formState.tokenError(
                                      l10n.loginValidationTokenRequired,
                                    ),
                                    onChanged: controller.updateToken,
                                    compact: isCompactHeight,
                                    suffixIcon: IconButton(
                                      onPressed:
                                          controller.toggleTokenVisibility,
                                      icon: Icon(
                                        formState.obscureToken
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isCompactHeight ? 8 : 10),
                                  Text(
                                    l10n.loginTokenHelp,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ] else ...[
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
                                  SizedBox(height: isCompactHeight ? 14 : 18),
                                  _LoginTextField(
                                    controller: _mfaCodeController,
                                    label: l10n.mfaCodeLabel,
                                    hintText: l10n.mfaCodeHint,
                                    keyboardType: TextInputType.number,
                                    prefixIcon: Icons.pin_outlined,
                                    onChanged: controller.updateMfaCode,
                                    compact: isCompactHeight,
                                  ),
                                  SizedBox(height: isCompactHeight ? 8 : 10),
                                  Text(
                                    l10n.loginMfaCodeHelp,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                SizedBox(height: isCompactHeight ? 6 : 10),
                                _CustomHeadersSection(
                                  controller: _customHeadersController,
                                  savedHeaderNames:
                                      formState.savedCustomHeaderNames,
                                  enabled: !formState.isSubmitting,
                                  onRemoveSaved: () => _confirmRemoval(
                                    title: l10n.loginRemoveCustomHeadersTitle,
                                    message:
                                        l10n.loginRemoveCustomHeadersMessage,
                                    remove: controller.removeSavedCustomHeaders,
                                  ),
                                  title: l10n.loginCustomHeadersLabel,
                                  hintText: l10n.loginCustomHeadersHint,
                                  helpText: l10n.loginCustomHeadersHelp,
                                  errorText: formState.customHeadersError(
                                    l10n.loginValidationCustomHeaders,
                                    l10n.loginValidationCustomHeadersHttps,
                                  ),
                                  onChanged: controller.updateCustomHeaders,
                                ),
                                _ClientCertificateSection(
                                  passwordController:
                                      _certificatePasswordController,
                                  fileName: formState.clientCertificateFileName,
                                  errorText: formState.clientCertificateError(
                                    l10n.loginValidationClientCertificate,
                                    l10n.loginValidationClientCertificateHttps,
                                  ),
                                  enabled: !formState.isSubmitting,
                                  onChoose: controller.pickClientCertificate,
                                  onRemove: () => _confirmRemoval(
                                    title:
                                        l10n.loginRemoveClientCertificateTitle,
                                    message: l10n
                                        .loginRemoveClientCertificateMessage,
                                    remove: controller.removeClientCertificate,
                                  ),
                                  onPasswordChanged: controller
                                      .updateClientCertificatePassword,
                                ),
                                SizedBox(height: isCompactHeight ? 14 : 20),
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

  /// Removing deletes the saved value at once, so the user is asked first.
  Future<void> _confirmRemoval({
    required String title,
    required String message,
    required Future<void> Function() remove,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.l10n.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.l10n.loginRemoveButton),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await remove();
    }
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

class _CustomHeadersSection extends StatelessWidget {
  const _CustomHeadersSection({
    required this.controller,
    required this.savedHeaderNames,
    required this.enabled,
    required this.onRemoveSaved,
    required this.title,
    required this.hintText,
    required this.helpText,
    required this.onChanged,
    this.errorText,
  });

  final TextEditingController controller;
  final List<String> savedHeaderNames;
  final bool enabled;
  final VoidCallback onRemoveSaved;
  final String title;
  final String hintText;
  final String helpText;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return ExpansionTile(
      // Open for saved headers.
      initiallyExpanded: savedHeaderNames.isNotEmpty,
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      children: [
        if (savedHeaderNames.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                // Only the names: a saved value is never shown again.
                child: Text(
                  savedHeaderNames
                      .map(
                        (name) => '$name: \u2022\u2022\u2022\u2022\u2022\u2022',
                      )
                      .join('\n'),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: enabled ? onRemoveSaved : null,
                child: Text(l10n.loginRemoveButton),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.loginCustomHeadersSavedHelp,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.multiline,
          minLines: 2,
          maxLines: 6,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: onChanged,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(errorText: errorText, hintText: hintText),
        ),
        const SizedBox(height: 8),
        Text(
          helpText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ClientCertificateSection extends StatelessWidget {
  const _ClientCertificateSection({
    required this.passwordController,
    required this.fileName,
    required this.enabled,
    required this.onChoose,
    required this.onRemove,
    required this.onPasswordChanged,
    this.errorText,
  });

  final TextEditingController passwordController;
  final String? fileName;
  final bool enabled;
  final VoidCallback onChoose;
  final VoidCallback onRemove;
  final ValueChanged<String> onPasswordChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final fileName = this.fileName;
    final errorText = this.errorText;

    final section = ExpansionTile(
      // Open for a saved certificate.
      initiallyExpanded: fileName != null,
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(
        l10n.loginClientCertificateLabel,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      children: [
        if (fileName != null) ...[
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: enabled ? onRemove : null,
                child: Text(l10n.loginRemoveButton),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: passwordController,
            keyboardType: TextInputType.visiblePassword,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: onPasswordChanged,
            decoration: InputDecoration(
              hintText: l10n.loginClientCertificatePasswordHint,
              prefixIcon: const Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: enabled ? onChoose : null,
          icon: const Icon(Icons.upload_file_outlined),
          label: Text(l10n.loginClientCertificateChoose),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.loginClientCertificateHelp,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        section,
        // Below the section, so it also shows while the section is closed.
        if (errorText != null)
          Text(
            errorText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
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
