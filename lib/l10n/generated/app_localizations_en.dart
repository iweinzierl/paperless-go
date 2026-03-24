// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Paperless Go';

  @override
  String get navigationHome => 'Home';

  @override
  String get navigationDocuments => 'Documents';

  @override
  String get navigationRecent => 'Recent';

  @override
  String get navigationInbox => 'Inbox';

  @override
  String get navigationReview => 'Review';

  @override
  String get serverUrlLabel => 'Server URL';

  @override
  String get serverUrlHint => 'https://paperless.example.com';

  @override
  String get usernameLabel => 'Username';

  @override
  String get usernameHint => 'john.doe';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get clearAction => 'Clear';

  @override
  String get applyAction => 'Apply';

  @override
  String get retryAction => 'Retry';

  @override
  String get deleteAction => 'Delete';

  @override
  String get renameAction => 'Rename';

  @override
  String get saveAction => 'Save';

  @override
  String get savingAction => 'Saving...';

  @override
  String get createAction => 'Create';

  @override
  String get addingAction => 'Adding...';

  @override
  String get loadingStatus => 'Loading...';

  @override
  String get couldNotLoadStatus => 'Could not load';

  @override
  String get loginConnectTitle => 'Connect to your server';

  @override
  String get loginConnectDescription =>
      'Use your paperless-ngx URL and account credentials to access your documents.';

  @override
  String get loginButton => 'Login';

  @override
  String connectedAs(Object displayName) {
    return 'Connected as $displayName';
  }

  @override
  String get loginValidationServerUrlRequired =>
      'Enter your paperless-ngx server URL.';

  @override
  String get loginValidationFullUrl =>
      'Use a full URL like https://paperless.example.com.';

  @override
  String get loginValidationUsernameRequired => 'Enter your username.';

  @override
  String get loginValidationPasswordRequired => 'Enter your password.';

  @override
  String get loginSuccess => 'Connected successfully.';

  @override
  String get loginFailedGeneric => 'Login failed. Please try again.';

  @override
  String get authUnexpectedResponse =>
      'The server returned an unexpected response.';

  @override
  String get authWrongPageInsteadOfApi =>
      'The request reached the wrong paperless page instead of the API. Check the base URL, especially if the server is hosted below a subpath.';

  @override
  String get authAuthenticationFailed =>
      'Authentication failed. Check your URL, username, and password.';

  @override
  String get authServerRejectedLogin =>
      'The server rejected the login request. Check the base URL, especially if paperless-ngx is hosted below a subpath.';

  @override
  String get authUnableToReachServer =>
      'Unable to reach the paperless-ngx server.';

  @override
  String get authInvalidServerUrl =>
      'Enter a valid server URL including http:// or https://.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsConnectionSection => 'Connection';

  @override
  String get settingsAppearanceBehaviorSection => 'Appearance & Behavior';

  @override
  String get settingsTodosSection => 'Todos';

  @override
  String get settingsServerUrlSubtitle =>
      'Paperless-ngx endpoint used for login, sync, and downloads.';

  @override
  String get settingsUsernameSubtitle =>
      'Account used to authenticate against the server.';

  @override
  String get settingsPasswordSubtitle =>
      'Stored locally and verified again when you save.';

  @override
  String get saveSettingsAction => 'Save settings';

  @override
  String get settingsSaveSuccess => 'Settings saved and connection verified.';

  @override
  String get settingsSaveFailedGeneric =>
      'Could not save settings. Please try again.';

  @override
  String get appLanguageTitle => 'App language';

  @override
  String get appLanguageSubtitle =>
      'Choose whether the app follows the system language or always uses a specific translation.';

  @override
  String get appLanguageSystem => 'System default';

  @override
  String get appLanguageEnglish => 'English';

  @override
  String get appLanguageGerman => 'Deutsch';

  @override
  String get appLanguageFrench => 'Français';

  @override
  String get appLanguageItalian => 'Italiano';

  @override
  String get appLanguageSpanish => 'Español';

  @override
  String get themeModeTitle => 'Theme mode';

  @override
  String get themeModeSubtitle =>
      'Choose whether the app uses the light or dark color palette.';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get cachePreviewsTitle => 'Cache thumbnails and previews';

  @override
  String get cachePreviewsSubtitle =>
      'Persist the preference for faster browsing as local caching expands.';

  @override
  String get todoTagsTitle => 'TODO tags';

  @override
  String get todoTagsSubtitle =>
      'Select which server tags should feed the Todos tab.';

  @override
  String get selectTodoTagsAction => 'Select TODO tags';

  @override
  String get couldNotLoadAvailableTags => 'Could not load available tags.';

  @override
  String get retryTagLoadingAction => 'Retry tag loading';

  @override
  String get loadingAvailableTags => 'Loading available tags...';

  @override
  String get selectTodoTagsDialogTitle => 'Select TODO tags';

  @override
  String get noTagsAvailableOnServer => 'No tags are available on the server.';

  @override
  String get homeRefreshTooltip => 'Refresh home';

  @override
  String get logoutTooltip => 'Log out';

  @override
  String get recentUploadsTab => 'Recent uploads';

  @override
  String get todosTab => 'Todos';

  @override
  String get scanLaterAction => 'Scan later';

  @override
  String get scanDocumentAction => 'Scan document';

  @override
  String get scanDocumentTitle => 'Scan document';

  @override
  String get scanDocumentDescription =>
      'Capture one or more pages, review them, and upload the resulting PDF to paperless-ngx.';

  @override
  String get scanDocumentEmptyTitle => 'Start a new scan';

  @override
  String get scanDocumentEmptyDescription =>
      'Use your device camera to capture a paper document. Each scan is combined into one PDF before upload.';

  @override
  String get scanDocumentTitleFieldLabel => 'Document title';

  @override
  String get scanDocumentTitleFieldHint => 'Optional title override';

  @override
  String scanDocumentPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scanned pages',
      one: '1 scanned page',
    );
    return '$_temp0';
  }

  @override
  String get scanDocumentAddPagesAction => 'Scan more pages';

  @override
  String get scanDocumentReplacePagesAction => 'Scan again';

  @override
  String get scanDocumentUploadAction => 'Upload scan';

  @override
  String get scanDocumentUploadingAction => 'Uploading...';

  @override
  String get scanDocumentQueued => 'Scan queued for processing.';

  @override
  String get scanDocumentScanFailed =>
      'The scanner could not start on this device.';

  @override
  String get scanDocumentUploadFailed => 'The scan could not be uploaded.';

  @override
  String get removeScannedPageTooltip => 'Remove scanned page';

  @override
  String scannedPageLabel(int page) {
    return 'Page $page';
  }

  @override
  String get homeUpdated => 'Home updated.';

  @override
  String get homeRefreshFailed => 'Home refresh failed.';

  @override
  String get noUploadsYetTitle => 'No uploads yet';

  @override
  String get noUploadsYetDescription =>
      'Recent documents will appear here once your server has processed uploads.';

  @override
  String get couldNotLoadRecentUploadsTitle => 'Could not load recent uploads';

  @override
  String get couldNotLoadRecentUploadsDescription =>
      'The home page reached your server, but document loading failed. Pull to refresh later.';

  @override
  String get nothingToReviewTitle => 'Nothing to review';

  @override
  String get nothingToReviewDescription =>
      'Documents with your configured TODO tags will appear here once they need manual attention.';

  @override
  String get verificationQueueTitle => 'Verification queue';

  @override
  String get verificationQueueDescription =>
      'Documents matching your configured TODO tags are listed here for manual review. Choose one or more TODO tags in Settings so documents can appear in the review queue.';

  @override
  String get openTodoTagSettingsAction => 'Open TODO tag settings';

  @override
  String get couldNotLoadReviewQueueTitle => 'Could not load review queue';

  @override
  String get couldNotLoadReviewQueueDescription =>
      'The app could not load documents matching your configured TODO tags right now.';

  @override
  String get drawerRecentlyOpened => 'Recently opened';

  @override
  String get drawerSettings => 'Settings';

  @override
  String get drawerHelpFeedback => 'Help & Feedback';

  @override
  String get drawerStatisticsTitle => 'Statistics';

  @override
  String get drawerDocuments => 'Documents';

  @override
  String get drawerCorrespondents => 'Correspondents';

  @override
  String get drawerTags => 'Tags';

  @override
  String get drawerDocumentTypes => 'Document types';

  @override
  String get drawerStatisticsUnavailable =>
      'Statistics are unavailable right now.';

  @override
  String get managementOptionsEmpty =>
      'No items available yet. Use the create action to add one.';

  @override
  String get managementSearchHint => 'Search types';

  @override
  String get noManagementOptionsMatchSearch =>
      'No entries match the current search.';

  @override
  String get renameCorrespondentAction => 'Rename correspondent';

  @override
  String get renameDocumentTypeAction => 'Rename document type';

  @override
  String get renameTagAction => 'Rename tag';

  @override
  String get deleteCorrespondentAction => 'Delete correspondent';

  @override
  String get deleteDocumentTypeAction => 'Delete document type';

  @override
  String get deleteTagAction => 'Delete tag';

  @override
  String deleteCorrespondentConfirmationMessage(Object name) {
    return 'Delete \"$name\"? This action cannot be undone.';
  }

  @override
  String deleteDocumentTypeConfirmationMessage(Object name) {
    return 'Delete \"$name\"? This action cannot be undone.';
  }

  @override
  String deleteTagConfirmationMessage(Object name) {
    return 'Delete \"$name\"? This action cannot be undone.';
  }

  @override
  String refreshFailedLabel(Object timestamp) {
    return 'Refresh failed $timestamp';
  }

  @override
  String get refreshingLabel => 'Refreshing...';

  @override
  String get waitingForFirstSyncLabel => 'Waiting for first sync';

  @override
  String refreshingLastUpdatedLabel(Object timestamp) {
    return 'Refreshing... last updated $timestamp';
  }

  @override
  String get updatedJustNowLabel => 'Updated just now';

  @override
  String updatedMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min ago',
      one: '1 min ago',
    );
    return 'Updated $_temp0';
  }

  @override
  String updatedAtLabel(Object timestamp) {
    return 'Updated $timestamp';
  }

  @override
  String todayAtLabel(Object time) {
    return 'today at $time';
  }

  @override
  String yesterdayAtLabel(Object time) {
    return 'yesterday at $time';
  }

  @override
  String get documentsTitle => 'Documents';

  @override
  String get refreshDocumentsTooltip => 'Refresh documents';

  @override
  String get searchByTitleHint => 'Search by title';

  @override
  String get clearSearchTooltip => 'Clear search';

  @override
  String get filtersTooltip => 'Filters';

  @override
  String connectedToServer(Object serverUrl) {
    return 'Connected to $serverUrl';
  }

  @override
  String get documentsUpdated => 'Documents updated.';

  @override
  String get documentRefreshFailed => 'Document refresh failed.';

  @override
  String get filtersTitle => 'Filters';

  @override
  String get resetAction => 'Reset';

  @override
  String get sortByLabel => 'Sort by';

  @override
  String get filterTagLabel => 'Tag';

  @override
  String get filterCorrespondentLabel => 'Correspondent';

  @override
  String get filterDocumentTypeLabel => 'Document type';

  @override
  String get anyOption => 'Any';

  @override
  String get applyFiltersAction => 'Apply filters';

  @override
  String get sortCreatedNewest => 'Created date (newest first)';

  @override
  String get sortCreatedOldest => 'Created date (oldest first)';

  @override
  String get sortAddedNewest => 'Added date (newest first)';

  @override
  String get sortAddedOldest => 'Added date (oldest first)';

  @override
  String get sortTitleAz => 'Title (A-Z)';

  @override
  String get sortTitleZa => 'Title (Z-A)';

  @override
  String documentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents',
      one: '1 document',
    );
    return '$_temp0';
  }

  @override
  String get noDocumentsMatchSearch => 'No documents match the current search.';

  @override
  String get detailsAction => 'Details';

  @override
  String get openAction => 'Open';

  @override
  String get openingAction => 'Opening...';

  @override
  String get previousAction => 'Previous';

  @override
  String pageIndicator(int page) {
    return 'Page $page';
  }

  @override
  String get nextAction => 'Next';

  @override
  String get couldNotLoadDocuments => 'Could not load documents.';

  @override
  String get recentlyOpenedTitle => 'Recently opened';

  @override
  String get clearHistoryTooltip => 'Clear history';

  @override
  String get recentlyOpenedEmpty =>
      'Documents you open or inspect will appear here.';

  @override
  String get clearRecentlyOpenedTitle => 'Clear recently opened?';

  @override
  String get clearRecentlyOpenedDescription =>
      'This removes the local history of documents you opened from the drawer.';

  @override
  String get recentlyOpenedCleared => 'Recently opened cleared.';

  @override
  String openedAtLabel(Object time) {
    return 'Opened $time';
  }

  @override
  String get helpFeedbackTitle => 'Help & Feedback';

  @override
  String get documentationTitle => 'Documentation';

  @override
  String get documentationDescription =>
      'Open the paperless-ngx documentation for setup, usage, and API guidance.';

  @override
  String get reportIssueTitle => 'Report an issue';

  @override
  String get reportIssueDescription =>
      'Open the upstream issue tracker to report bugs or request improvements.';

  @override
  String get donateTitle => 'Donate';

  @override
  String get donateDescription =>
      'Choose an amount and continue in your browser to support development.';

  @override
  String get donateDialogTitle => 'Support development';

  @override
  String get donateAmountLabel => 'Amount';

  @override
  String get donateAmountHint => '5.00';

  @override
  String get donateContinueAction => 'Continue to donate';

  @override
  String get donateInvalidAmount => 'Enter an amount greater than 0.';

  @override
  String get copySupportSummaryTitle => 'Copy support summary';

  @override
  String get copySupportSummaryDescription =>
      'Copy app version and server details to the clipboard before filing feedback.';

  @override
  String get supportSummaryCopied => 'Support summary copied.';

  @override
  String get unknownLabel => 'unknown';

  @override
  String get documentDetailsTitle => 'Document details';

  @override
  String get editMetadataAction => 'Edit metadata';

  @override
  String get openDocumentAction => 'Open document';

  @override
  String get openOriginalAction => 'Open original';

  @override
  String get thumbnailPreviewTitle => 'Thumbnail preview';

  @override
  String get noThumbnailPreviewAvailable => 'No thumbnail preview available.';

  @override
  String authenticatedThumbnailRequest(Object serverUrl) {
    return 'Authenticated thumbnail request for $serverUrl';
  }

  @override
  String get metadataTitle => 'Metadata';

  @override
  String get fileNameLabel => 'File name';

  @override
  String get mimeTypeLabel => 'Mime type';

  @override
  String get createdLabel => 'Created';

  @override
  String get addedLabel => 'Added';

  @override
  String get pagesLabel => 'Pages';

  @override
  String get archiveSerialNumberLabel => 'Archive serial number';

  @override
  String get correspondentLabel => 'Correspondent';

  @override
  String get documentTypeLabel => 'Document type';

  @override
  String get tagsLabel => 'Tags';

  @override
  String get contentPreviewTitle => 'Content preview';

  @override
  String get metadataUpdated => 'Metadata updated.';

  @override
  String get editMetadataTitle => 'Edit metadata';

  @override
  String get editableFieldsTitle => 'Editable fields';

  @override
  String get titleLabel => 'Title';

  @override
  String get createdDateLabel => 'Created date';

  @override
  String get createdDateHint => 'YYYY-MM-DD';

  @override
  String get newCorrespondentAction => 'New correspondent';

  @override
  String get correspondentNameLabel => 'Correspondent name';

  @override
  String get chooseCorrespondentHint => 'Choose a correspondent';

  @override
  String get noCorrespondentOption => 'No correspondent';

  @override
  String get couldNotLoadCorrespondents => 'Could not load correspondents.';

  @override
  String get newDocumentTypeAction => 'New document type';

  @override
  String get documentTypeNameLabel => 'Document type name';

  @override
  String get chooseDocumentTypeHint => 'Choose a document type';

  @override
  String get noDocumentTypeOption => 'No document type';

  @override
  String get couldNotLoadDocumentTypes => 'Could not load document types.';

  @override
  String get newTagAction => 'New tag';

  @override
  String get tagNameLabel => 'Tag name';

  @override
  String get noTagsSelected => 'No tags selected.';

  @override
  String get noTodoTagsSelectedYet => 'No TODO tags selected yet.';

  @override
  String get noTodoTagsSelectedDescription =>
      'Use Select TODO tags below to choose which documents appear in the Todos tab.';

  @override
  String get editTagsAction => 'Edit tags';

  @override
  String get selectTagsDialogTitle => 'Select tags';

  @override
  String get searchTagsHint => 'Search tags';

  @override
  String get selectedTagsSectionTitle => 'Selected tags';

  @override
  String get availableTagsSectionTitle => 'All tags';

  @override
  String get noTagsMatchSearch => 'No tags match the current search.';

  @override
  String createTagConfirmationMessage(Object name) {
    return 'Create \"$name\" and add it to this document?';
  }

  @override
  String get enterNameValidation => 'Enter a name.';

  @override
  String get invalidDateValidation => 'Use a valid date like 2026-03-20.';

  @override
  String get correspondentCreated => 'Correspondent created.';

  @override
  String get correspondentRenamed => 'Correspondent renamed.';

  @override
  String get correspondentDeleted => 'Correspondent deleted.';

  @override
  String get documentTypeCreated => 'Document type created.';

  @override
  String get documentTypeRenamed => 'Document type renamed.';

  @override
  String get documentTypeDeleted => 'Document type deleted.';

  @override
  String get tagCreated => 'Tag created.';

  @override
  String get tagRenamed => 'Tag renamed.';

  @override
  String get tagDeleted => 'Tag deleted.';

  @override
  String get couldNotLoadDocumentDetails =>
      'Could not load the document details.';

  @override
  String documentSubtitleUploaded(Object timestamp) {
    return 'Uploaded $timestamp';
  }

  @override
  String documentSubtitleDated(Object timestamp) {
    return 'Dated $timestamp';
  }

  @override
  String documentPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String documentAsn(int value) {
    return 'ASN $value';
  }

  @override
  String documentFallback(int id) {
    return 'Document #$id';
  }
}
