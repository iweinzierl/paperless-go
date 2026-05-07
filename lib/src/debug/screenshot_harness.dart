import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/l10n/generated/app_localizations.dart';
import 'package:paperless_ngx_app/src/core/providers/shared_preferences_provider.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_behavior_providers.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/controllers/settings_controller.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/pages/app_shell_page.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/providers/app_shell_providers.dart';
import 'package:paperless_ngx_app/src/core/presentation/layout/adaptive_layout.dart';
import 'package:paperless_ngx_app/src/features/app_shell/presentation/pages/settings_page.dart';
import 'package:paperless_ngx_app/src/core/theme/app_theme.dart';
import 'package:paperless_ngx_app/src/features/auth/data/local/auth_preferences.dart';
import 'package:paperless_ngx_app/src/features/auth/data/repositories/auth_repository.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_auth_session.dart';
import 'package:paperless_ngx_app/src/features/auth/domain/models/paperless_user_capabilities.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/providers/current_user_capabilities_provider.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/pages/login_page.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document_page.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_filter_option.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/document_detail_page.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/documents_filters_page.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/pages/documents_page.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/document_detail_provider.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/selected_document_provider.dart';
import 'package:paperless_ngx_app/src/features/documents/data/repositories/documents_repository.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/models/documents_filter_state.dart';

const screenshotScenarioPreferenceKey = 'debug.screenshot_scenario';
const screenshotDataSourcePreferenceKey = 'debug.screenshot_data_source';
const screenshotStatePreferenceKey = 'debug.screenshot_state';

enum ScreenshotRuntimeState { loading, ready, error }

enum ScreenshotDataSource { mock, live }

ScreenshotDataSource maybeParseScreenshotDataSource(String? value) {
  return switch (value?.trim().toLowerCase()) {
    'live' => ScreenshotDataSource.live,
    _ => ScreenshotDataSource.mock,
  };
}

enum ScreenshotScenario {
  login,
  documents,
  documentsList,
  documentsFilters,
  documentsDrawer,
  documentDetail,
  documentMetadataEdit,
  settings,
}

const SettingsFormState _redactedScreenshotSettingsState = SettingsFormState(
  serverUrl: '',
  username: '',
  password: '',
  hasSubmitted: false,
  saveStatus: AsyncData<void>(null),
  connectedDisplayName: 'Demo',
);

ScreenshotScenario? maybeParseScreenshotScenario(String? value) {
  return switch (value?.trim()) {
    'login' => ScreenshotScenario.login,
    'documents' => ScreenshotScenario.documents,
    'documents_list' => ScreenshotScenario.documentsList,
    'documents_filters' => ScreenshotScenario.documentsFilters,
    'documents_drawer' => ScreenshotScenario.documentsDrawer,
    'document_detail' => ScreenshotScenario.documentDetail,
    'document_metadata_edit' => ScreenshotScenario.documentMetadataEdit,
    'settings' => ScreenshotScenario.settings,
    _ => null,
  };
}

class ScreenshotHarnessApp extends ConsumerWidget {
  const ScreenshotHarnessApp({
    required this.scenario,
    this.dataSource = ScreenshotDataSource.mock,
    super.key,
  });

  final ScreenshotScenario scenario;
  final ScreenshotDataSource dataSource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLanguageLocale = ref
        .watch(appBehaviorSettingsProvider)
        .appLanguage
        .locale;
    final child = switch (dataSource) {
      ScreenshotDataSource.mock => _ScreenshotStateSync(
        state: ScreenshotRuntimeState.ready,
        child: _buildMockScenarioChild(),
      ),
      ScreenshotDataSource.live => _LiveScreenshotBootstrap(scenario: scenario),
    };

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: appLanguageLocale,
      theme: buildAppTheme(),
      darkTheme: buildAppTheme(brightness: Brightness.dark),
      themeMode: ThemeMode.light,
      home: child,
    );
  }

  Widget _buildMockScenarioChild() {
    return switch (scenario) {
      ScreenshotScenario.login => const LoginPage(),
      ScreenshotScenario.documents => const _ScreenshotShellPage(
        initialTab: 0,
        selectedDocumentId: ScreenshotDocumentsRepository.primaryDocumentId,
      ),
      ScreenshotScenario.documentsList => const _ScreenshotShellPage(
        initialTab: 0,
        selectedDocumentId: ScreenshotDocumentsRepository.primaryDocumentId,
      ),
      ScreenshotScenario.documentsFilters => const DocumentsFiltersPage(
        initialFilterState: DocumentsFilterState(
          tagIds: <int>[1],
          correspondentId: 1,
          documentTypeId: 1,
        ),
        initialOrdering: '-added',
      ),
      ScreenshotScenario.documentsDrawer =>
        const _ScreenshotDocumentsDrawerPage(
          selectedDocumentId: ScreenshotDocumentsRepository.primaryDocumentId,
        ),
      ScreenshotScenario.documentDetail => const DocumentDetailPage(
        documentId: ScreenshotDocumentsRepository.primaryDocumentId,
      ),
      ScreenshotScenario.documentMetadataEdit => const DocumentDetailPage(
        documentId: ScreenshotDocumentsRepository.primaryDocumentId,
        openEditMetadataOnLoad: true,
      ),
      ScreenshotScenario.settings => const SettingsPage(),
    };
  }
}

class _LiveScreenshotBootstrap extends ConsumerStatefulWidget {
  const _LiveScreenshotBootstrap({required this.scenario});

  final ScreenshotScenario scenario;

  @override
  ConsumerState<_LiveScreenshotBootstrap> createState() =>
      _LiveScreenshotBootstrapState();
}

class _LiveScreenshotBootstrapState
    extends ConsumerState<_LiveScreenshotBootstrap> {
  AsyncValue<void> _bootstrapState = const AsyncLoading<void>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapLiveSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _bootstrapState.when(
      data: (_) => _LiveScreenshotScenarioPage(scenario: widget.scenario),
      error: (error, stackTrace) => _ScreenshotStatusPage(
        state: ScreenshotRuntimeState.error,
        icon: Icons.error_outline,
        message: error.toString(),
      ),
      loading: () => const _ScreenshotStatusPage(
        state: ScreenshotRuntimeState.loading,
        icon: Icons.cloud_sync_outlined,
        message: 'Signing in to screenshot server...',
        loading: true,
      ),
    );
  }

  Future<void> _bootstrapLiveSession() async {
    if (widget.scenario == ScreenshotScenario.login) {
      setState(() {
        _bootstrapState = const AsyncData<void>(null);
      });
      return;
    }

    final existingSession = ref.read(authSessionProvider);
    if (existingSession.isAuthenticated) {
      setState(() {
        _bootstrapState = const AsyncData<void>(null);
      });
      return;
    }

    final launchSession = _resolveLiveScreenshotLaunchSession(existingSession);
    final serverUrl = launchSession.serverUrl.trim();
    final username = launchSession.username.trim();
    final password = launchSession.password;
    if (serverUrl.isEmpty || username.isEmpty || password.isEmpty) {
      setState(() {
        _bootstrapState = AsyncError<void>(
          StateError(
            'Missing screenshot server credentials. Configure server URL, username, and password before running live screenshots.',
          ),
          StackTrace.current,
        );
      });
      return;
    }

    try {
      final session = await ref
          .read(authRepositoryProvider)
          .signIn(serverUrl: serverUrl, username: username, password: password);
      await AuthPreferences(
        ref.read(sharedPreferencesProvider),
      ).saveSession(session);
      ref.read(authSessionProvider.notifier).setSession(session);
      if (!mounted) {
        return;
      }

      setState(() {
        _bootstrapState = const AsyncData<void>(null);
      });
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }

      setState(() {
        _bootstrapState = AsyncError<void>(error, stackTrace);
      });
    }
  }
}

PaperlessAuthSession _resolveLiveScreenshotLaunchSession(
  PaperlessAuthSession session,
) {
  String readEnvironmentValue(String key) {
    return Platform.environment[key]?.trim() ?? '';
  }

  final serverUrl = session.serverUrl.trim().isNotEmpty
      ? session.serverUrl
      : readEnvironmentValue('PAPERLESS_SCREENSHOT_SERVER_URL');
  final username = session.username.trim().isNotEmpty
      ? session.username
      : readEnvironmentValue('PAPERLESS_SCREENSHOT_USERNAME');
  final password = session.password.isNotEmpty
      ? session.password
      : readEnvironmentValue('PAPERLESS_SCREENSHOT_PASSWORD');
  final existingDisplayName = session.displayName?.trim();
  final displayName =
      existingDisplayName != null && existingDisplayName.isNotEmpty
      ? existingDisplayName
      : readEnvironmentValue('PAPERLESS_SCREENSHOT_DISPLAY_NAME');

  return session.copyWith(
    serverUrl: serverUrl,
    username: username,
    password: password,
    displayName: displayName.isEmpty ? null : displayName,
  );
}

final _liveScreenshotScenarioContextProvider =
    FutureProvider.family<_LiveScreenshotScenarioContext, ScreenshotScenario>((
      ref,
      scenario,
    ) async {
      const query = '';
      const page = 1;
      const ordering = '-added';
      final repository = ref.read(documentsRepositoryProvider);

      if (scenario == ScreenshotScenario.login ||
          scenario == ScreenshotScenario.settings) {
        return const _LiveScreenshotScenarioContext(primaryDocumentId: null);
      }

      var filterState = const DocumentsFilterState();
      List<PaperlessFilterOption>? tagOptions;
      List<PaperlessFilterOption>? correspondentOptions;
      List<PaperlessFilterOption>? documentTypeOptions;
      if (scenario == ScreenshotScenario.documentsFilters) {
        tagOptions = await repository.fetchTagOptions();
        correspondentOptions = await repository.fetchCorrespondentOptions();
        documentTypeOptions = await repository.fetchDocumentTypeOptions();

        filterState = DocumentsFilterState(
          tagIds: tagOptions.isEmpty
              ? const <int>[]
              : <int>[tagOptions.first.id],
          correspondentId: correspondentOptions.isEmpty
              ? null
              : correspondentOptions.first.id,
          documentTypeId: documentTypeOptions.isEmpty
              ? null
              : documentTypeOptions.first.id,
        );
      }

      final firstPage = await repository.fetchDocuments(
        page: page,
        ordering: ordering,
        titleFilter: query,
        tagIds: filterState.tagIds,
        correspondentId: filterState.correspondentId,
        documentTypeId: filterState.documentTypeId,
      );
      final primaryDocumentId = firstPage.results.isEmpty
          ? null
          : firstPage.results.first.id;

      PaperlessDocument? primaryDocument;
      PaperlessUserCapabilities? currentUserCapabilities;
      final requiresPrimaryDocument = switch (scenario) {
        ScreenshotScenario.documents ||
        ScreenshotScenario.documentsList ||
        ScreenshotScenario.documentsDrawer ||
        ScreenshotScenario.documentDetail ||
        ScreenshotScenario.documentMetadataEdit => true,
        ScreenshotScenario.login ||
        ScreenshotScenario.documentsFilters ||
        ScreenshotScenario.settings => false,
      };
      final requiresMetadataOptions = switch (scenario) {
        ScreenshotScenario.documentMetadataEdit => true,
        _ => false,
      };

      if (primaryDocumentId != null && requiresPrimaryDocument) {
        primaryDocument = await repository.fetchDocument(primaryDocumentId);
      }

      if (requiresMetadataOptions) {
        correspondentOptions ??= await repository.fetchCorrespondentOptions();
        documentTypeOptions ??= await repository.fetchDocumentTypeOptions();
        tagOptions ??= await repository.fetchTagOptions();
      }

      switch (scenario) {
        case ScreenshotScenario.documentDetail:
        case ScreenshotScenario.documentMetadataEdit:
          if (primaryDocumentId != null) {
            currentUserCapabilities = await ref.read(
              currentUserCapabilitiesProvider.future,
            );
          }
        case ScreenshotScenario.documents:
        case ScreenshotScenario.documentsList:
        case ScreenshotScenario.documentsFilters:
        case ScreenshotScenario.documentsDrawer:
        case ScreenshotScenario.settings:
        case ScreenshotScenario.login:
          break;
      }

      return _LiveScreenshotScenarioContext(
        primaryDocumentId: primaryDocumentId,
        filterState: filterState,
        documentsPage: firstPage,
        tagOptions: tagOptions,
        correspondentOptions: correspondentOptions,
        documentTypeOptions: documentTypeOptions,
        primaryDocument: primaryDocument,
        currentUserCapabilities: currentUserCapabilities,
        searchQuery: query,
        currentPage: page,
        ordering: ordering,
      );
    });

class _LiveScreenshotScenarioPage extends ConsumerWidget {
  const _LiveScreenshotScenarioPage({required this.scenario});

  final ScreenshotScenario scenario;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (scenario == ScreenshotScenario.login) {
      return const _ScreenshotStateSync(
        state: ScreenshotRuntimeState.ready,
        child: LoginPage(),
      );
    }

    final scenarioContext = ref.watch(
      _liveScreenshotScenarioContextProvider(scenario),
    );

    return scenarioContext.when(
      data: (value) => _ScreenshotStateSync(
        state: ScreenshotRuntimeState.ready,
        readyDelay: _readyDelayForScenario(scenario),
        beforeReady: _beforeReadyForScenario(value),
        child: _buildScenarioPage(value),
      ),
      error: (error, stackTrace) => _ScreenshotStatusPage(
        state: ScreenshotRuntimeState.error,
        icon: Icons.error_outline,
        message: error.toString(),
      ),
      loading: () => const _ScreenshotStatusPage(
        state: ScreenshotRuntimeState.loading,
        icon: Icons.hourglass_top_outlined,
        message: 'Loading demo server data...',
        loading: true,
      ),
    );
  }

  Widget _buildScenarioPage(_LiveScreenshotScenarioContext context) {
    return switch (scenario) {
      ScreenshotScenario.login => const LoginPage(),
      ScreenshotScenario.documents => _ScreenshotShellPage(
        initialTab: 0,
        selectedDocumentId: context.primaryDocumentId,
        documentsContext: context,
      ),
      ScreenshotScenario.documentsList => _ScreenshotShellPage(
        initialTab: 0,
        selectedDocumentId: context.primaryDocumentId,
        documentsContext: context,
      ),
      ScreenshotScenario.documentsFilters => ProviderScope(
        overrides: context.providerOverrides,
        child: DocumentsFiltersPage(
          initialFilterState: context.filterState,
          initialOrdering: context.ordering,
        ),
      ),
      ScreenshotScenario.documentsDrawer => _ScreenshotDocumentsDrawerPage(
        selectedDocumentId: context.primaryDocumentId,
        documentsContext: context,
        userCardSubtitleOverride: '',
      ),
      ScreenshotScenario.documentDetail => _buildDocumentDetailScenario(
        context,
        openEditMetadataOnLoad: false,
      ),
      ScreenshotScenario.documentMetadataEdit => _buildDocumentDetailScenario(
        context,
        openEditMetadataOnLoad: true,
      ),
      ScreenshotScenario.settings => const SettingsPage(
        stateOverride: _redactedScreenshotSettingsState,
      ),
    };
  }

  Widget _buildDocumentDetailScenario(
    _LiveScreenshotScenarioContext context, {
    required bool openEditMetadataOnLoad,
  }) {
    final documentId = context.primaryDocumentId;
    if (documentId == null) {
      return const _ScreenshotStatusPage(
        state: ScreenshotRuntimeState.error,
        icon: Icons.description_outlined,
        message: 'No documents available on the screenshot server.',
      );
    }

    return DocumentDetailPage(
      documentId: documentId,
      openEditMetadataOnLoad: openEditMetadataOnLoad,
    );
  }

  Duration _readyDelayForScenario(ScreenshotScenario scenario) {
    return switch (scenario) {
      ScreenshotScenario.documents ||
      ScreenshotScenario.documentsList ||
      ScreenshotScenario.documentsDrawer ||
      ScreenshotScenario.documentDetail ||
      ScreenshotScenario.documentMetadataEdit => const Duration(seconds: 3),
      ScreenshotScenario.login ||
      ScreenshotScenario.documentsFilters ||
      ScreenshotScenario.settings => Duration.zero,
    };
  }

  Future<void> Function(BuildContext, WidgetRef)? _beforeReadyForScenario(
    _LiveScreenshotScenarioContext context,
  ) {
    final documentId = context.primaryDocumentId;
    if (documentId == null) {
      return null;
    }

    return switch (scenario) {
      ScreenshotScenario.documents ||
      ScreenshotScenario.documentsList ||
      ScreenshotScenario.documentsDrawer ||
      ScreenshotScenario.documentDetail ||
      ScreenshotScenario.documentMetadataEdit => (buildContext, ref) async {
        final repository = ref.read(documentsRepositoryProvider);
        final imageProvider = NetworkImage(
          repository.buildDocumentThumbnailUri(documentId).toString(),
          headers: repository.buildAuthenticatedHeaders(),
        );
        await precacheImage(imageProvider, buildContext);
      },
      ScreenshotScenario.login ||
      ScreenshotScenario.documentsFilters ||
      ScreenshotScenario.settings => null,
    };
  }
}

class _LiveScreenshotScenarioContext {
  const _LiveScreenshotScenarioContext({
    required this.primaryDocumentId,
    this.filterState = const DocumentsFilterState(),
    this.documentsPage,
    this.tagOptions,
    this.correspondentOptions,
    this.documentTypeOptions,
    this.primaryDocument,
    this.currentUserCapabilities,
    this.searchQuery = '',
    this.currentPage = 1,
    this.ordering = '-added',
  });

  final int? primaryDocumentId;
  final DocumentsFilterState filterState;
  final PaperlessDocumentPage? documentsPage;
  final List<PaperlessFilterOption>? tagOptions;
  final List<PaperlessFilterOption>? correspondentOptions;
  final List<PaperlessFilterOption>? documentTypeOptions;
  final PaperlessDocument? primaryDocument;
  final PaperlessUserCapabilities? currentUserCapabilities;
  final String searchQuery;
  final int currentPage;
  final String ordering;

  List<Override> get providerOverrides {
    return [
      documentsSearchQueryProvider.overrideWith((ref) => searchQuery),
      documentsCurrentPageProvider.overrideWith((ref) => currentPage),
      documentsOrderingProvider.overrideWith((ref) => ordering),
      documentsFilterStateProvider.overrideWith((ref) => filterState),
      if (documentsPage != null)
        documentsPageProvider.overrideWith((ref) async => documentsPage!),
      if (tagOptions != null)
        tagOptionsProvider.overrideWith((ref) async => tagOptions!),
      if (correspondentOptions != null)
        correspondentOptionsProvider.overrideWith(
          (ref) async => correspondentOptions!,
        ),
      if (documentTypeOptions != null)
        documentTypeOptionsProvider.overrideWith(
          (ref) async => documentTypeOptions!,
        ),
      if (primaryDocumentId != null && primaryDocument != null)
        documentDetailProvider(
          primaryDocumentId!,
        ).overrideWith((ref) async => primaryDocument!),
      if (currentUserCapabilities != null)
        currentUserCapabilitiesProvider.overrideWith(
          (ref) async => currentUserCapabilities,
        ),
    ];
  }
}

class _ScreenshotStatusPage extends StatelessWidget {
  const _ScreenshotStatusPage({
    required this.state,
    required this.icon,
    required this.message,
    this.loading = false,
  });

  final ScreenshotRuntimeState state;
  final IconData icon;
  final String message;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _ScreenshotStateSync(
        state: state,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (loading)
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(),
                    )
                  else
                    Icon(icon, size: 40),
                  const SizedBox(height: 16),
                  Text(message, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScreenshotStateSync extends ConsumerStatefulWidget {
  const _ScreenshotStateSync({
    required this.state,
    required this.child,
    this.readyDelay = Duration.zero,
    this.beforeReady,
  });

  final ScreenshotRuntimeState state;
  final Widget child;
  final Duration readyDelay;
  final Future<void> Function(BuildContext, WidgetRef)? beforeReady;

  @override
  ConsumerState<_ScreenshotStateSync> createState() =>
      _ScreenshotStateSyncState();
}

class _ScreenshotStateSyncState extends ConsumerState<_ScreenshotStateSync> {
  int _persistRequestId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _schedulePersistState();
    });
  }

  @override
  void didUpdateWidget(covariant _ScreenshotStateSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state ||
        oldWidget.readyDelay != widget.readyDelay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _schedulePersistState();
      });
    }
  }

  Future<void> _schedulePersistState() async {
    final requestId = ++_persistRequestId;
    if (widget.state == ScreenshotRuntimeState.ready &&
        widget.beforeReady != null) {
      await widget.beforeReady!(context, ref);
      if (!mounted || requestId != _persistRequestId) {
        return;
      }
    }

    if (widget.state == ScreenshotRuntimeState.ready &&
        widget.readyDelay > Duration.zero) {
      await Future<void>.delayed(widget.readyDelay);
      if (!mounted || requestId != _persistRequestId) {
        return;
      }
    }

    await _persistState();
  }

  Future<void> _persistState() async {
    final sharedPreferences = ref.read(sharedPreferencesProvider);
    await sharedPreferences.setString(
      screenshotStatePreferenceKey,
      widget.state.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: Opacity(
            opacity: 0,
            alwaysIncludeSemantics: true,
            child: Align(
              alignment: Alignment.topLeft,
              child: Text('paperless-screenshot-state-${widget.state.name}'),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScreenshotShellPage extends StatelessWidget {
  const _ScreenshotShellPage({
    required this.initialTab,
    this.selectedDocumentId,
    this.documentsContext,
    this.drawerUserCardSubtitleOverride,
  });

  final int initialTab;
  final int? selectedDocumentId;
  final _LiveScreenshotScenarioContext? documentsContext;
  final String? drawerUserCardSubtitleOverride;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        appShellTabProvider.overrideWith((ref) => initialTab),
        appDrawerMinimizedProvider.overrideWith((ref) => false),
        if (selectedDocumentId != null)
          selectedDocumentIdProvider.overrideWith((ref) => selectedDocumentId),
        ...?documentsContext?.providerOverrides,
      ],
      child: AppShellPage(
        drawerUserCardSubtitleOverride: drawerUserCardSubtitleOverride,
      ),
    );
  }
}

class _ScreenshotDocumentsDrawerPage extends StatelessWidget {
  const _ScreenshotDocumentsDrawerPage({
    required this.selectedDocumentId,
    this.documentsContext,
    this.userCardSubtitleOverride,
  });

  final int? selectedDocumentId;
  final _LiveScreenshotScenarioContext? documentsContext;
  final String? userCardSubtitleOverride;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideLayout = useWideLayoutForSize(
          Size(constraints.maxWidth, constraints.maxHeight),
        );

        if (isWideLayout) {
          return _ScreenshotShellPage(
            initialTab: 0,
            selectedDocumentId: selectedDocumentId,
            documentsContext: documentsContext,
            drawerUserCardSubtitleOverride: userCardSubtitleOverride,
          );
        }

        return ProviderScope(
          overrides: [...?documentsContext?.providerOverrides],
          child: DocumentsPage(
            openDrawerOnLoad: true,
            drawerUserCardSubtitleOverride: userCardSubtitleOverride,
          ),
        );
      },
    );
  }
}

class ScreenshotDocumentsRepository extends DocumentsRepository {
  ScreenshotDocumentsRepository({String languageCode = 'en'})
    : _fixture = _ScreenshotFixture.forLanguage(languageCode),
      super(dio: _dio, session: _session);

  static const primaryDocumentId = 101;

  static final Dio _dio = Dio();
  static const PaperlessAuthSession _session = PaperlessAuthSession(
    serverUrl: 'https://demo.paperless-ngx.local/',
    username: 'demo.user',
    password: 'not-used',
    authToken: 'demo-token',
    displayName: 'Demo User',
  );

  final _ScreenshotFixture _fixture;

  @override
  Future<PaperlessDocumentPage> fetchDocuments({
    int page = 1,
    int pageSize = 20,
    String ordering = '-created',
    String titleFilter = '',
    List<int> tagIds = const <int>[],
    bool? isInInbox,
    int? correspondentId,
    int? documentTypeId,
  }) async {
    final query = titleFilter.trim().toLowerCase();
    final results = _fixture.documents
        .where((document) {
          final matchesTitle =
              query.isEmpty || document.title.toLowerCase().contains(query);
          final matchesTag =
              tagIds.isEmpty || tagIds.every(document.tags.contains);
          final hasInboxTag = document.tags.any(_fixture.inboxTagIds.contains);
          final matchesInbox = isInInbox == null || hasInboxTag == isInInbox;
          final matchesCorrespondent =
              correspondentId == null ||
              document.correspondentId == correspondentId;
          final matchesDocumentType =
              documentTypeId == null ||
              document.documentTypeId == documentTypeId;
          return matchesTitle &&
              matchesTag &&
              matchesInbox &&
              matchesCorrespondent &&
              matchesDocumentType;
        })
        .toList(growable: false);

    return PaperlessDocumentPage(count: results.length, results: results);
  }

  @override
  Future<List<PaperlessDocument>> fetchRecentUploads() async {
    return _fixture.documents;
  }

  @override
  Future<PaperlessDocument> fetchDocument(int documentId) async {
    return _fixture.documents.firstWhere(
      (document) => document.id == documentId,
    );
  }

  @override
  Future<List<PaperlessFilterOption>> fetchTagOptions() async => _fixture.tags;

  @override
  Future<List<PaperlessFilterOption>> fetchCorrespondentOptions() async {
    return _fixture.correspondents;
  }

  @override
  Future<List<PaperlessFilterOption>> fetchDocumentTypeOptions() async {
    return _fixture.documentTypes;
  }

  @override
  Uri buildDocumentThumbnailUri(int documentId) {
    return Uri.parse('file:///thumbnail-not-available-$documentId.png');
  }

  @override
  Uri buildDocumentPreviewUri({
    required int documentId,
    bool original = false,
  }) {
    return Uri.parse('file:///preview-not-available-$documentId.pdf');
  }

  @override
  ImageProvider<Object>? buildDocumentThumbnailImageProvider(int documentId) {
    return null;
  }

  @override
  Widget? buildDocumentThumbnailWidget(PaperlessDocument document) {
    return _MockBillThumbnail(document: document);
  }

  @override
  Map<String, String> buildAuthenticatedHeaders() => const <String, String>{};
}

class _MockBillThumbnail extends StatelessWidget {
  const _MockBillThumbnail({required this.document});

  final PaperlessDocument document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8F4EB), Color(0xFFF0F4F8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 300,
              height: 160,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        width: 26,
                        height: 26,
                        child: Container(
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.receipt_long,
                            color: accent,
                            size: 15,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 36,
                        right: 0,
                        top: 1,
                        child: Text(
                          document.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: const Color(0xFF1F2937),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 36,
                        top: 22,
                        child: Text(
                          'Utility statement',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 48,
                        child: Container(
                          height: 1,
                          color: const Color(0xFFE5E7EB),
                        ),
                      ),
                      const Positioned(
                        left: 0,
                        top: 60,
                        right: 118,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _BillPlaceholderLine(width: 116),
                            SizedBox(height: 8),
                            _BillPlaceholderLine(width: 136),
                            SizedBox(height: 8),
                            _BillPlaceholderLine(width: 128),
                            SizedBox(height: 8),
                            _BillPlaceholderLine(width: 92),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 60,
                        width: 104,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Amount due',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _amountForDocument(document.id),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: const Color(0xFF111827),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                height: 1,
                                color: const Color(0xFFD7DEE5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Auto debit',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF111827), Color(0xFF374151)],
                            ),
                          ),
                          child: CustomPaint(painter: _BarcodePainter()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _amountForDocument(int documentId) {
    return switch (documentId) {
      ScreenshotDocumentsRepository.primaryDocumentId => 'EUR 86.40',
      _ => 'EUR 214.10',
    };
  }
}

class _BillPlaceholderLine extends StatelessWidget {
  const _BillPlaceholderLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 7,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final whitePaint = Paint()..color = Colors.white;
    final bars = <double>[3, 1, 2, 4, 1, 3, 2, 1, 4, 2, 1, 3, 1, 2, 4, 1, 3];
    var x = 18.0;

    for (final bar in bars) {
      canvas.drawRect(
        Rect.fromLTWH(x, 6, bar * 2, size.height - 12),
        whitePaint,
      );
      x += (bar * 2) + 4;
      if (x >= size.width - 18) {
        break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScreenshotFixture {
  const _ScreenshotFixture({
    required this.documents,
    required this.tags,
    required this.inboxTagIds,
    required this.correspondents,
    required this.documentTypes,
  });

  final List<PaperlessDocument> documents;
  final List<PaperlessFilterOption> tags;
  final Set<int> inboxTagIds;
  final List<PaperlessFilterOption> correspondents;
  final List<PaperlessFilterOption> documentTypes;

  static _ScreenshotFixture forLanguage(String languageCode) {
    return switch (languageCode.toLowerCase()) {
      'de' => _de,
      'es' => _es,
      'fr' => _fr,
      'it' => _it,
      _ => _en,
    };
  }

  static final _en = const _ScreenshotFixture(
    documents: <PaperlessDocument>[
      PaperlessDocument(
        id: ScreenshotDocumentsRepository.primaryDocumentId,
        title: 'March electricity bill.pdf',
        created: '2026-03-14',
        added: '2026-03-15T09:30:00Z',
        pageCount: 2,
        correspondentId: 1,
        documentTypeId: 1,
        archiveSerialNumber: 4127,
        originalFileName: 'march-electricity-bill.pdf',
        mimeType: 'application/pdf',
        tags: <int>[1],
        content:
            'Electricity statement for March 2026. Total due 86.40 EUR. Direct debit on 25 March.',
      ),
      PaperlessDocument(
        id: 102,
        title: 'Insurance renewal notice.pdf',
        created: '2026-03-11',
        added: '2026-03-12T14:05:00Z',
        pageCount: 4,
        correspondentId: 2,
        documentTypeId: 2,
        originalFileName: 'insurance-renewal-notice.pdf',
        mimeType: 'application/pdf',
        tags: <int>[2],
      ),
    ],
    tags: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Inbox'),
      PaperlessFilterOption(id: 2, name: 'Review'),
    ],
    inboxTagIds: <int>{1},
    correspondents: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'City Energy'),
      PaperlessFilterOption(id: 2, name: 'North Shield Insurance'),
    ],
    documentTypes: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Invoice'),
      PaperlessFilterOption(id: 2, name: 'Letter'),
    ],
  );

  static final _de = const _ScreenshotFixture(
    documents: <PaperlessDocument>[
      PaperlessDocument(
        id: ScreenshotDocumentsRepository.primaryDocumentId,
        title: 'Stromrechnung Maerz.pdf',
        created: '2026-03-14',
        added: '2026-03-15T09:30:00Z',
        pageCount: 2,
        correspondentId: 1,
        documentTypeId: 1,
        archiveSerialNumber: 4127,
        originalFileName: 'stromrechnung-maerz.pdf',
        mimeType: 'application/pdf',
        tags: <int>[1],
        content:
            'Stromabrechnung fuer Maerz 2026. Gesamtbetrag 86.40 EUR. Lastschrift am 25. Maerz.',
      ),
      PaperlessDocument(
        id: 102,
        title: 'Versicherungsverlaengerung.pdf',
        created: '2026-03-11',
        added: '2026-03-12T14:05:00Z',
        pageCount: 4,
        correspondentId: 2,
        documentTypeId: 2,
        originalFileName: 'versicherungsverlaengerung.pdf',
        mimeType: 'application/pdf',
        tags: <int>[2],
      ),
    ],
    tags: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Eingang'),
      PaperlessFilterOption(id: 2, name: 'Pruefen'),
    ],
    inboxTagIds: <int>{1},
    correspondents: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Stadtwerke'),
      PaperlessFilterOption(id: 2, name: 'Nordschutz Versicherung'),
    ],
    documentTypes: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Rechnung'),
      PaperlessFilterOption(id: 2, name: 'Brief'),
    ],
  );

  static final _es = const _ScreenshotFixture(
    documents: <PaperlessDocument>[
      PaperlessDocument(
        id: ScreenshotDocumentsRepository.primaryDocumentId,
        title: 'Factura de electricidad marzo.pdf',
        created: '2026-03-14',
        added: '2026-03-15T09:30:00Z',
        pageCount: 2,
        correspondentId: 1,
        documentTypeId: 1,
        archiveSerialNumber: 4127,
        originalFileName: 'factura-electricidad-marzo.pdf',
        mimeType: 'application/pdf',
        tags: <int>[1],
        content:
            'Factura de electricidad de marzo de 2026. Importe total 86.40 EUR. Cargo domiciliado el 25 de marzo.',
      ),
      PaperlessDocument(
        id: 102,
        title: 'Aviso de renovacion del seguro.pdf',
        created: '2026-03-11',
        added: '2026-03-12T14:05:00Z',
        pageCount: 4,
        correspondentId: 2,
        documentTypeId: 2,
        originalFileName: 'renovacion-seguro.pdf',
        mimeType: 'application/pdf',
        tags: <int>[2],
      ),
    ],
    tags: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Entrada'),
      PaperlessFilterOption(id: 2, name: 'Revisar'),
    ],
    inboxTagIds: <int>{1},
    correspondents: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Energia Urbana'),
      PaperlessFilterOption(id: 2, name: 'Seguro Escudo Norte'),
    ],
    documentTypes: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Factura'),
      PaperlessFilterOption(id: 2, name: 'Carta'),
    ],
  );

  static final _fr = const _ScreenshotFixture(
    documents: <PaperlessDocument>[
      PaperlessDocument(
        id: ScreenshotDocumentsRepository.primaryDocumentId,
        title: 'Facture electricite mars.pdf',
        created: '2026-03-14',
        added: '2026-03-15T09:30:00Z',
        pageCount: 2,
        correspondentId: 1,
        documentTypeId: 1,
        archiveSerialNumber: 4127,
        originalFileName: 'facture-electricite-mars.pdf',
        mimeType: 'application/pdf',
        tags: <int>[1],
        content:
            'Facture d electricite de mars 2026. Montant total 86.40 EUR. Prelevement le 25 mars.',
      ),
      PaperlessDocument(
        id: 102,
        title: 'Avis de renouvellement assurance.pdf',
        created: '2026-03-11',
        added: '2026-03-12T14:05:00Z',
        pageCount: 4,
        correspondentId: 2,
        documentTypeId: 2,
        originalFileName: 'renouvellement-assurance.pdf',
        mimeType: 'application/pdf',
        tags: <int>[2],
      ),
    ],
    tags: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Boite de reception'),
      PaperlessFilterOption(id: 2, name: 'A verifier'),
    ],
    inboxTagIds: <int>{1},
    correspondents: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Energie Urbaine'),
      PaperlessFilterOption(id: 2, name: 'North Shield Assurance'),
    ],
    documentTypes: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Facture'),
      PaperlessFilterOption(id: 2, name: 'Lettre'),
    ],
  );

  static final _it = const _ScreenshotFixture(
    documents: <PaperlessDocument>[
      PaperlessDocument(
        id: ScreenshotDocumentsRepository.primaryDocumentId,
        title: 'Bolletta elettrica marzo.pdf',
        created: '2026-03-14',
        added: '2026-03-15T09:30:00Z',
        pageCount: 2,
        correspondentId: 1,
        documentTypeId: 1,
        archiveSerialNumber: 4127,
        originalFileName: 'bolletta-elettrica-marzo.pdf',
        mimeType: 'application/pdf',
        tags: <int>[1],
        content:
            'Bolletta elettrica di marzo 2026. Totale dovuto 86.40 EUR. Addebito il 25 marzo.',
      ),
      PaperlessDocument(
        id: 102,
        title: 'Avviso rinnovo assicurazione.pdf',
        created: '2026-03-11',
        added: '2026-03-12T14:05:00Z',
        pageCount: 4,
        correspondentId: 2,
        documentTypeId: 2,
        originalFileName: 'rinnovo-assicurazione.pdf',
        mimeType: 'application/pdf',
        tags: <int>[2],
      ),
    ],
    tags: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Posta in arrivo'),
      PaperlessFilterOption(id: 2, name: 'Da rivedere'),
    ],
    inboxTagIds: <int>{1},
    correspondents: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Energia Cittadina'),
      PaperlessFilterOption(id: 2, name: 'North Shield Assicurazioni'),
    ],
    documentTypes: <PaperlessFilterOption>[
      PaperlessFilterOption(id: 1, name: 'Fattura'),
      PaperlessFilterOption(id: 2, name: 'Lettera'),
    ],
  );
}
