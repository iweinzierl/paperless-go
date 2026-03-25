import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Paperless Go'**
  String get appTitle;

  /// No description provided for @navigationHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navigationHome;

  /// No description provided for @navigationDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get navigationDocuments;

  /// No description provided for @navigationRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get navigationRecent;

  /// No description provided for @navigationInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get navigationInbox;

  /// No description provided for @navigationReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get navigationReview;

  /// No description provided for @serverUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrlLabel;

  /// No description provided for @serverUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://paperless.example.com'**
  String get serverUrlHint;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'john.doe'**
  String get usernameHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @clearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearAction;

  /// No description provided for @applyAction.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyAction;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryAction;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @renameAction.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameAction;

  /// No description provided for @saveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveAction;

  /// No description provided for @savingAction.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingAction;

  /// No description provided for @createAction.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createAction;

  /// No description provided for @addingAction.
  ///
  /// In en, this message translates to:
  /// **'Adding...'**
  String get addingAction;

  /// No description provided for @loadingStatus.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingStatus;

  /// No description provided for @couldNotLoadStatus.
  ///
  /// In en, this message translates to:
  /// **'Could not load'**
  String get couldNotLoadStatus;

  /// No description provided for @loginConnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to your server'**
  String get loginConnectTitle;

  /// No description provided for @loginConnectDescription.
  ///
  /// In en, this message translates to:
  /// **'Use your paperless-ngx URL and account credentials to access your documents.'**
  String get loginConnectDescription;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @connectedAs.
  ///
  /// In en, this message translates to:
  /// **'Connected as {displayName}'**
  String connectedAs(Object displayName);

  /// No description provided for @loginValidationServerUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your paperless-ngx server URL.'**
  String get loginValidationServerUrlRequired;

  /// No description provided for @loginValidationFullUrl.
  ///
  /// In en, this message translates to:
  /// **'Use a full URL like https://paperless.example.com.'**
  String get loginValidationFullUrl;

  /// No description provided for @loginValidationUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your username.'**
  String get loginValidationUsernameRequired;

  /// No description provided for @loginValidationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get loginValidationPasswordRequired;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connected successfully.'**
  String get loginSuccess;

  /// No description provided for @loginFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get loginFailedGeneric;

  /// No description provided for @authUnexpectedResponse.
  ///
  /// In en, this message translates to:
  /// **'The server returned an unexpected response.'**
  String get authUnexpectedResponse;

  /// No description provided for @authWrongPageInsteadOfApi.
  ///
  /// In en, this message translates to:
  /// **'The request reached the wrong paperless page instead of the API. Check the base URL, especially if the server is hosted below a subpath.'**
  String get authWrongPageInsteadOfApi;

  /// No description provided for @authAuthenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Check your URL, username, and password.'**
  String get authAuthenticationFailed;

  /// No description provided for @authServerRejectedLogin.
  ///
  /// In en, this message translates to:
  /// **'The server rejected the login request. Check the base URL, especially if paperless-ngx is hosted below a subpath.'**
  String get authServerRejectedLogin;

  /// No description provided for @authUnableToReachServer.
  ///
  /// In en, this message translates to:
  /// **'Unable to reach the paperless-ngx server.'**
  String get authUnableToReachServer;

  /// No description provided for @authInvalidServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid server URL including http:// or https://.'**
  String get authInvalidServerUrl;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsConnectionSection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get settingsConnectionSection;

  /// No description provided for @settingsAppearanceBehaviorSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance & Behavior'**
  String get settingsAppearanceBehaviorSection;

  /// No description provided for @settingsSecuritySection.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecuritySection;

  /// No description provided for @settingsServerUrlSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paperless-ngx endpoint used for login, sync, and downloads.'**
  String get settingsServerUrlSubtitle;

  /// No description provided for @settingsUsernameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Account used to authenticate against the server.'**
  String get settingsUsernameSubtitle;

  /// No description provided for @settingsPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stored locally and verified again when you save.'**
  String get settingsPasswordSubtitle;

  /// No description provided for @saveSettingsAction.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get saveSettingsAction;

  /// No description provided for @settingsSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Settings saved and connection verified.'**
  String get settingsSaveSuccess;

  /// No description provided for @settingsSaveFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not save settings. Please try again.'**
  String get settingsSaveFailedGeneric;

  /// No description provided for @appLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguageTitle;

  /// No description provided for @appLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose whether the app follows the system language or always uses a specific translation.'**
  String get appLanguageSubtitle;

  /// No description provided for @appLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get appLanguageSystem;

  /// No description provided for @appLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get appLanguageEnglish;

  /// No description provided for @appLanguageGerman.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get appLanguageGerman;

  /// No description provided for @appLanguageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get appLanguageFrench;

  /// No description provided for @appLanguageItalian.
  ///
  /// In en, this message translates to:
  /// **'Italiano'**
  String get appLanguageItalian;

  /// No description provided for @appLanguageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get appLanguageSpanish;

  /// No description provided for @themeModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get themeModeTitle;

  /// No description provided for @themeModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose whether the app uses the light or dark color palette.'**
  String get themeModeSubtitle;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @cachePreviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Cache thumbnails and previews'**
  String get cachePreviewsTitle;

  /// No description provided for @cachePreviewsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Persist the preference for faster browsing as local caching expands.'**
  String get cachePreviewsSubtitle;

  /// No description provided for @biometricLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID or fingerprint'**
  String get biometricLockTitle;

  /// No description provided for @biometricLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require biometric or device credential verification when returning to the app after it has been in the background.'**
  String get biometricLockSubtitle;

  /// No description provided for @appLockTimeoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Lock when reopening after'**
  String get appLockTimeoutTitle;

  /// No description provided for @appLockTimeoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how long the app can stay in the background before it asks to unlock again.'**
  String get appLockTimeoutSubtitle;

  /// No description provided for @appLockTimeoutImmediate.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get appLockTimeoutImmediate;

  /// No description provided for @appLockTimeout30Seconds.
  ///
  /// In en, this message translates to:
  /// **'30 seconds'**
  String get appLockTimeout30Seconds;

  /// No description provided for @appLockTimeout1Minute.
  ///
  /// In en, this message translates to:
  /// **'1 minute'**
  String get appLockTimeout1Minute;

  /// No description provided for @appLockTimeout5Minutes.
  ///
  /// In en, this message translates to:
  /// **'5 minutes'**
  String get appLockTimeout5Minutes;

  /// No description provided for @biometricLockUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication is not available on this device right now.'**
  String get biometricLockUnavailable;

  /// No description provided for @biometricLockEnableFailed.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication was not confirmed, so app lock stays disabled.'**
  String get biometricLockEnableFailed;

  /// No description provided for @biometricEnableReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm your identity to enable app lock for Paperless Go.'**
  String get biometricEnableReason;

  /// No description provided for @biometricPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Protect Paperless Go?'**
  String get biometricPromptTitle;

  /// No description provided for @biometricPromptMessage.
  ///
  /// In en, this message translates to:
  /// **'Enable Face ID or fingerprint now to protect your documents when returning to the app.'**
  String get biometricPromptMessage;

  /// No description provided for @biometricPromptNotNowAction.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get biometricPromptNotNowAction;

  /// No description provided for @biometricPromptEnableAction.
  ///
  /// In en, this message translates to:
  /// **'Enable now'**
  String get biometricPromptEnableAction;

  /// No description provided for @biometricUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Paperless Go'**
  String get biometricUnlockTitle;

  /// No description provided for @biometricUnlockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID, Touch ID, or your device credentials to continue.'**
  String get biometricUnlockSubtitle;

  /// No description provided for @biometricUnlockAction.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get biometricUnlockAction;

  /// No description provided for @biometricUnlockingStatus.
  ///
  /// In en, this message translates to:
  /// **'Unlocking...'**
  String get biometricUnlockingStatus;

  /// No description provided for @biometricUnlockReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm your identity to unlock Paperless Go.'**
  String get biometricUnlockReason;

  /// No description provided for @biometricUnlockFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication was canceled or failed. Try again to continue.'**
  String get biometricUnlockFailed;

  /// No description provided for @signOutAction.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutAction;

  /// No description provided for @retryTagLoadingAction.
  ///
  /// In en, this message translates to:
  /// **'Retry tag loading'**
  String get retryTagLoadingAction;

  /// No description provided for @noTagsAvailableOnServer.
  ///
  /// In en, this message translates to:
  /// **'No tags are available on the server.'**
  String get noTagsAvailableOnServer;

  /// No description provided for @homeRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh home'**
  String get homeRefreshTooltip;

  /// No description provided for @logoutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logoutTooltip;

  /// No description provided for @recentUploadsTab.
  ///
  /// In en, this message translates to:
  /// **'Recent uploads'**
  String get recentUploadsTab;

  /// No description provided for @todosTab.
  ///
  /// In en, this message translates to:
  /// **'Todos'**
  String get todosTab;

  /// No description provided for @scanLaterAction.
  ///
  /// In en, this message translates to:
  /// **'Scan later'**
  String get scanLaterAction;

  /// No description provided for @scanDocumentAction.
  ///
  /// In en, this message translates to:
  /// **'Scan document'**
  String get scanDocumentAction;

  /// No description provided for @scanDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan document'**
  String get scanDocumentTitle;

  /// No description provided for @scanDocumentDescription.
  ///
  /// In en, this message translates to:
  /// **'Capture one or more pages, review them, and upload the resulting PDF to paperless-ngx.'**
  String get scanDocumentDescription;

  /// No description provided for @scanDocumentEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a new scan'**
  String get scanDocumentEmptyTitle;

  /// No description provided for @scanDocumentEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Use your device camera to capture a paper document. Each scan is combined into one PDF before upload.'**
  String get scanDocumentEmptyDescription;

  /// No description provided for @scanDocumentTitleFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Document title'**
  String get scanDocumentTitleFieldLabel;

  /// No description provided for @scanDocumentTitleFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Optional title override'**
  String get scanDocumentTitleFieldHint;

  /// No description provided for @scanDocumentPages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {1 scanned page} other {{count} scanned pages}}'**
  String scanDocumentPages(int count);

  /// No description provided for @scanDocumentAddPagesAction.
  ///
  /// In en, this message translates to:
  /// **'Scan more pages'**
  String get scanDocumentAddPagesAction;

  /// No description provided for @scanDocumentReplacePagesAction.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get scanDocumentReplacePagesAction;

  /// No description provided for @scanDocumentUploadAction.
  ///
  /// In en, this message translates to:
  /// **'Upload scan'**
  String get scanDocumentUploadAction;

  /// No description provided for @scanDocumentUploadingAction.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get scanDocumentUploadingAction;

  /// No description provided for @scanDocumentQueued.
  ///
  /// In en, this message translates to:
  /// **'Scan queued for processing.'**
  String get scanDocumentQueued;

  /// No description provided for @scanDocumentScanFailed.
  ///
  /// In en, this message translates to:
  /// **'The scanner could not start on this device.'**
  String get scanDocumentScanFailed;

  /// No description provided for @scanDocumentUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'The scan could not be uploaded.'**
  String get scanDocumentUploadFailed;

  /// No description provided for @removeScannedPageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove scanned page'**
  String get removeScannedPageTooltip;

  /// No description provided for @scannedPageLabel.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String scannedPageLabel(int page);

  /// No description provided for @homeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Home updated.'**
  String get homeUpdated;

  /// No description provided for @homeRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Home refresh failed.'**
  String get homeRefreshFailed;

  /// No description provided for @noUploadsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No uploads yet'**
  String get noUploadsYetTitle;

  /// No description provided for @noUploadsYetDescription.
  ///
  /// In en, this message translates to:
  /// **'Recent documents will appear here once your server has processed uploads.'**
  String get noUploadsYetDescription;

  /// No description provided for @couldNotLoadRecentUploadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load recent uploads'**
  String get couldNotLoadRecentUploadsTitle;

  /// No description provided for @couldNotLoadRecentUploadsDescription.
  ///
  /// In en, this message translates to:
  /// **'The home page reached your server, but document loading failed. Pull to refresh later.'**
  String get couldNotLoadRecentUploadsDescription;

  /// No description provided for @nothingToReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to review'**
  String get nothingToReviewTitle;

  /// No description provided for @nothingToReviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Documents currently in your inbox appear here for manual verification.'**
  String get nothingToReviewDescription;

  /// No description provided for @verificationQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification queue'**
  String get verificationQueueTitle;

  /// No description provided for @verificationQueueDescription.
  ///
  /// In en, this message translates to:
  /// **'Documents currently in your inbox are listed here for manual review.'**
  String get verificationQueueDescription;

  /// No description provided for @couldNotLoadReviewQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load review queue'**
  String get couldNotLoadReviewQueueTitle;

  /// No description provided for @couldNotLoadReviewQueueDescription.
  ///
  /// In en, this message translates to:
  /// **'The app could not load inbox documents requiring manual review right now.'**
  String get couldNotLoadReviewQueueDescription;

  /// No description provided for @drawerRecentlyOpened.
  ///
  /// In en, this message translates to:
  /// **'Recently opened'**
  String get drawerRecentlyOpened;

  /// No description provided for @drawerSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get drawerSettings;

  /// No description provided for @drawerHelpFeedback.
  ///
  /// In en, this message translates to:
  /// **'Help & Feedback'**
  String get drawerHelpFeedback;

  /// No description provided for @drawerStatisticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get drawerStatisticsTitle;

  /// No description provided for @drawerDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get drawerDocuments;

  /// No description provided for @drawerCorrespondents.
  ///
  /// In en, this message translates to:
  /// **'Correspondents'**
  String get drawerCorrespondents;

  /// No description provided for @drawerTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get drawerTags;

  /// No description provided for @drawerDocumentTypes.
  ///
  /// In en, this message translates to:
  /// **'Document types'**
  String get drawerDocumentTypes;

  /// No description provided for @drawerStatisticsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Statistics are unavailable right now.'**
  String get drawerStatisticsUnavailable;

  /// No description provided for @managementOptionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items available yet. Use the create action to add one.'**
  String get managementOptionsEmpty;

  /// No description provided for @managementSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search types'**
  String get managementSearchHint;

  /// No description provided for @noManagementOptionsMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No entries match the current search.'**
  String get noManagementOptionsMatchSearch;

  /// No description provided for @renameCorrespondentAction.
  ///
  /// In en, this message translates to:
  /// **'Rename correspondent'**
  String get renameCorrespondentAction;

  /// No description provided for @renameDocumentTypeAction.
  ///
  /// In en, this message translates to:
  /// **'Rename document type'**
  String get renameDocumentTypeAction;

  /// No description provided for @renameTagAction.
  ///
  /// In en, this message translates to:
  /// **'Rename tag'**
  String get renameTagAction;

  /// No description provided for @deleteCorrespondentAction.
  ///
  /// In en, this message translates to:
  /// **'Delete correspondent'**
  String get deleteCorrespondentAction;

  /// No description provided for @deleteDocumentAction.
  ///
  /// In en, this message translates to:
  /// **'Delete document'**
  String get deleteDocumentAction;

  /// No description provided for @deleteDocumentTypeAction.
  ///
  /// In en, this message translates to:
  /// **'Delete document type'**
  String get deleteDocumentTypeAction;

  /// No description provided for @deleteTagAction.
  ///
  /// In en, this message translates to:
  /// **'Delete tag'**
  String get deleteTagAction;

  /// No description provided for @deleteCorrespondentConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This action cannot be undone.'**
  String deleteCorrespondentConfirmationMessage(Object name);

  /// No description provided for @deleteDocumentConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This action cannot be undone.'**
  String deleteDocumentConfirmationMessage(Object name);

  /// No description provided for @deleteDocumentTypeConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This action cannot be undone.'**
  String deleteDocumentTypeConfirmationMessage(Object name);

  /// No description provided for @deleteTagConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This action cannot be undone.'**
  String deleteTagConfirmationMessage(Object name);

  /// No description provided for @refreshFailedLabel.
  ///
  /// In en, this message translates to:
  /// **'Refresh failed {timestamp}'**
  String refreshFailedLabel(Object timestamp);

  /// No description provided for @refreshingLabel.
  ///
  /// In en, this message translates to:
  /// **'Refreshing...'**
  String get refreshingLabel;

  /// No description provided for @waitingForFirstSyncLabel.
  ///
  /// In en, this message translates to:
  /// **'Waiting for first sync'**
  String get waitingForFirstSyncLabel;

  /// No description provided for @refreshingLastUpdatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Refreshing... last updated {timestamp}'**
  String refreshingLastUpdatedLabel(Object timestamp);

  /// No description provided for @updatedJustNowLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated just now'**
  String get updatedJustNowLabel;

  /// No description provided for @updatedMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'Updated {minutes, plural, one {1 min ago} other {{minutes} min ago}}'**
  String updatedMinutesAgo(int minutes);

  /// No description provided for @updatedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated {timestamp}'**
  String updatedAtLabel(Object timestamp);

  /// No description provided for @todayAtLabel.
  ///
  /// In en, this message translates to:
  /// **'today at {time}'**
  String todayAtLabel(Object time);

  /// No description provided for @yesterdayAtLabel.
  ///
  /// In en, this message translates to:
  /// **'yesterday at {time}'**
  String yesterdayAtLabel(Object time);

  /// No description provided for @documentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documentsTitle;

  /// No description provided for @refreshDocumentsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh documents'**
  String get refreshDocumentsTooltip;

  /// No description provided for @searchByTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Search by title'**
  String get searchByTitleHint;

  /// No description provided for @clearSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearchTooltip;

  /// No description provided for @filtersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersTooltip;

  /// No description provided for @connectedToServer.
  ///
  /// In en, this message translates to:
  /// **'Connected to {serverUrl}'**
  String connectedToServer(Object serverUrl);

  /// No description provided for @documentsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Documents updated.'**
  String get documentsUpdated;

  /// No description provided for @documentRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Document refresh failed.'**
  String get documentRefreshFailed;

  /// No description provided for @filtersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersTitle;

  /// No description provided for @resetAction.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetAction;

  /// No description provided for @sortByLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortByLabel;

  /// No description provided for @filterTagLabel.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get filterTagLabel;

  /// No description provided for @filterCorrespondentLabel.
  ///
  /// In en, this message translates to:
  /// **'Correspondent'**
  String get filterCorrespondentLabel;

  /// No description provided for @filterDocumentTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Document type'**
  String get filterDocumentTypeLabel;

  /// No description provided for @anyOption.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get anyOption;

  /// No description provided for @applyFiltersAction.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get applyFiltersAction;

  /// No description provided for @sortCreatedNewest.
  ///
  /// In en, this message translates to:
  /// **'Created date (newest first)'**
  String get sortCreatedNewest;

  /// No description provided for @sortCreatedOldest.
  ///
  /// In en, this message translates to:
  /// **'Created date (oldest first)'**
  String get sortCreatedOldest;

  /// No description provided for @sortAddedNewest.
  ///
  /// In en, this message translates to:
  /// **'Added date (newest first)'**
  String get sortAddedNewest;

  /// No description provided for @sortAddedOldest.
  ///
  /// In en, this message translates to:
  /// **'Added date (oldest first)'**
  String get sortAddedOldest;

  /// No description provided for @sortTitleAz.
  ///
  /// In en, this message translates to:
  /// **'Title (A-Z)'**
  String get sortTitleAz;

  /// No description provided for @sortTitleZa.
  ///
  /// In en, this message translates to:
  /// **'Title (Z-A)'**
  String get sortTitleZa;

  /// No description provided for @documentCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {1 document} other {{count} documents}}'**
  String documentCount(int count);

  /// No description provided for @noDocumentsMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No documents match the current search.'**
  String get noDocumentsMatchSearch;

  /// No description provided for @detailsAction.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsAction;

  /// No description provided for @openAction.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openAction;

  /// No description provided for @openingAction.
  ///
  /// In en, this message translates to:
  /// **'Opening...'**
  String get openingAction;

  /// No description provided for @previousAction.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousAction;

  /// No description provided for @pageIndicator.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String pageIndicator(int page);

  /// No description provided for @nextAction.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextAction;

  /// No description provided for @couldNotLoadDocuments.
  ///
  /// In en, this message translates to:
  /// **'Could not load documents.'**
  String get couldNotLoadDocuments;

  /// No description provided for @recentlyOpenedTitle.
  ///
  /// In en, this message translates to:
  /// **'Recently opened'**
  String get recentlyOpenedTitle;

  /// No description provided for @clearHistoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get clearHistoryTooltip;

  /// No description provided for @recentlyOpenedEmpty.
  ///
  /// In en, this message translates to:
  /// **'Documents you open or inspect will appear here.'**
  String get recentlyOpenedEmpty;

  /// No description provided for @clearRecentlyOpenedTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear recently opened?'**
  String get clearRecentlyOpenedTitle;

  /// No description provided for @clearRecentlyOpenedDescription.
  ///
  /// In en, this message translates to:
  /// **'This removes the local history of documents you opened from the drawer.'**
  String get clearRecentlyOpenedDescription;

  /// No description provided for @recentlyOpenedCleared.
  ///
  /// In en, this message translates to:
  /// **'Recently opened cleared.'**
  String get recentlyOpenedCleared;

  /// No description provided for @openedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Opened {time}'**
  String openedAtLabel(Object time);

  /// No description provided for @helpFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Feedback'**
  String get helpFeedbackTitle;

  /// No description provided for @documentationTitle.
  ///
  /// In en, this message translates to:
  /// **'Documentation'**
  String get documentationTitle;

  /// No description provided for @documentationDescription.
  ///
  /// In en, this message translates to:
  /// **'Open the paperless-ngx documentation for setup, usage, and API guidance.'**
  String get documentationDescription;

  /// No description provided for @reportIssueTitle.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get reportIssueTitle;

  /// No description provided for @reportIssueDescription.
  ///
  /// In en, this message translates to:
  /// **'Open the upstream issue tracker to report bugs or request improvements.'**
  String get reportIssueDescription;

  /// No description provided for @donateTitle.
  ///
  /// In en, this message translates to:
  /// **'Donate'**
  String get donateTitle;

  /// No description provided for @donateDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose an amount and continue in your browser to support development.'**
  String get donateDescription;

  /// No description provided for @donateDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Support development'**
  String get donateDialogTitle;

  /// No description provided for @donateAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get donateAmountLabel;

  /// No description provided for @donateAmountHint.
  ///
  /// In en, this message translates to:
  /// **'5.00'**
  String get donateAmountHint;

  /// No description provided for @donateContinueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue to donate'**
  String get donateContinueAction;

  /// No description provided for @donateInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than 0.'**
  String get donateInvalidAmount;

  /// No description provided for @copySupportSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy support summary'**
  String get copySupportSummaryTitle;

  /// No description provided for @copySupportSummaryDescription.
  ///
  /// In en, this message translates to:
  /// **'Copy app version and server details to the clipboard before filing feedback.'**
  String get copySupportSummaryDescription;

  /// No description provided for @supportSummaryCopied.
  ///
  /// In en, this message translates to:
  /// **'Support summary copied.'**
  String get supportSummaryCopied;

  /// No description provided for @unknownLabel.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get unknownLabel;

  /// No description provided for @documentDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Document details'**
  String get documentDetailsTitle;

  /// No description provided for @editMetadataAction.
  ///
  /// In en, this message translates to:
  /// **'Edit metadata'**
  String get editMetadataAction;

  /// No description provided for @openDocumentAction.
  ///
  /// In en, this message translates to:
  /// **'Open document'**
  String get openDocumentAction;

  /// No description provided for @openOriginalAction.
  ///
  /// In en, this message translates to:
  /// **'Open original'**
  String get openOriginalAction;

  /// No description provided for @thumbnailPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail preview'**
  String get thumbnailPreviewTitle;

  /// No description provided for @noThumbnailPreviewAvailable.
  ///
  /// In en, this message translates to:
  /// **'No thumbnail preview available.'**
  String get noThumbnailPreviewAvailable;

  /// No description provided for @authenticatedThumbnailRequest.
  ///
  /// In en, this message translates to:
  /// **'Authenticated thumbnail request for {serverUrl}'**
  String authenticatedThumbnailRequest(Object serverUrl);

  /// No description provided for @metadataTitle.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get metadataTitle;

  /// No description provided for @fileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get fileNameLabel;

  /// No description provided for @mimeTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Mime type'**
  String get mimeTypeLabel;

  /// No description provided for @createdLabel.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get createdLabel;

  /// No description provided for @addedLabel.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get addedLabel;

  /// No description provided for @pagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pagesLabel;

  /// No description provided for @archiveSerialNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Archive serial number'**
  String get archiveSerialNumberLabel;

  /// No description provided for @correspondentLabel.
  ///
  /// In en, this message translates to:
  /// **'Correspondent'**
  String get correspondentLabel;

  /// No description provided for @documentTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Document type'**
  String get documentTypeLabel;

  /// No description provided for @tagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsLabel;

  /// No description provided for @contentPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Content preview'**
  String get contentPreviewTitle;

  /// No description provided for @metadataUpdated.
  ///
  /// In en, this message translates to:
  /// **'Metadata updated.'**
  String get metadataUpdated;

  /// No description provided for @editMetadataTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit metadata'**
  String get editMetadataTitle;

  /// No description provided for @editableFieldsTitle.
  ///
  /// In en, this message translates to:
  /// **'Editable fields'**
  String get editableFieldsTitle;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @createdDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Created date'**
  String get createdDateLabel;

  /// No description provided for @createdDateHint.
  ///
  /// In en, this message translates to:
  /// **'YYYY-MM-DD'**
  String get createdDateHint;

  /// No description provided for @newCorrespondentAction.
  ///
  /// In en, this message translates to:
  /// **'New correspondent'**
  String get newCorrespondentAction;

  /// No description provided for @correspondentNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Correspondent name'**
  String get correspondentNameLabel;

  /// No description provided for @chooseCorrespondentHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a correspondent'**
  String get chooseCorrespondentHint;

  /// No description provided for @noCorrespondentOption.
  ///
  /// In en, this message translates to:
  /// **'No correspondent'**
  String get noCorrespondentOption;

  /// No description provided for @couldNotLoadCorrespondents.
  ///
  /// In en, this message translates to:
  /// **'Could not load correspondents.'**
  String get couldNotLoadCorrespondents;

  /// No description provided for @selectCorrespondentDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Select correspondent'**
  String get selectCorrespondentDialogTitle;

  /// No description provided for @searchCorrespondentsHint.
  ///
  /// In en, this message translates to:
  /// **'Search correspondents'**
  String get searchCorrespondentsHint;

  /// No description provided for @noCorrespondentsMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No correspondents match the current search.'**
  String get noCorrespondentsMatchSearch;

  /// No description provided for @newDocumentTypeAction.
  ///
  /// In en, this message translates to:
  /// **'New document type'**
  String get newDocumentTypeAction;

  /// No description provided for @documentTypeNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Document type name'**
  String get documentTypeNameLabel;

  /// No description provided for @chooseDocumentTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a document type'**
  String get chooseDocumentTypeHint;

  /// No description provided for @noDocumentTypeOption.
  ///
  /// In en, this message translates to:
  /// **'No document type'**
  String get noDocumentTypeOption;

  /// No description provided for @couldNotLoadDocumentTypes.
  ///
  /// In en, this message translates to:
  /// **'Could not load document types.'**
  String get couldNotLoadDocumentTypes;

  /// No description provided for @selectDocumentTypeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Select document type'**
  String get selectDocumentTypeDialogTitle;

  /// No description provided for @searchDocumentTypesHint.
  ///
  /// In en, this message translates to:
  /// **'Search document types'**
  String get searchDocumentTypesHint;

  /// No description provided for @noDocumentTypesMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No document types match the current search.'**
  String get noDocumentTypesMatchSearch;

  /// No description provided for @newTagAction.
  ///
  /// In en, this message translates to:
  /// **'New tag'**
  String get newTagAction;

  /// No description provided for @tagNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Tag name'**
  String get tagNameLabel;

  /// No description provided for @noTagsSelected.
  ///
  /// In en, this message translates to:
  /// **'No tags selected.'**
  String get noTagsSelected;

  /// No description provided for @editTagsAction.
  ///
  /// In en, this message translates to:
  /// **'Edit tags'**
  String get editTagsAction;

  /// No description provided for @selectTagsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Select tags'**
  String get selectTagsDialogTitle;

  /// No description provided for @searchTagsHint.
  ///
  /// In en, this message translates to:
  /// **'Search tags'**
  String get searchTagsHint;

  /// No description provided for @selectedTagsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Selected tags'**
  String get selectedTagsSectionTitle;

  /// No description provided for @availableTagsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'All tags'**
  String get availableTagsSectionTitle;

  /// No description provided for @noTagsMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No tags match the current search.'**
  String get noTagsMatchSearch;

  /// No description provided for @createTagConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Create \"{name}\" and add it to this document?'**
  String createTagConfirmationMessage(Object name);

  /// No description provided for @enterNameValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get enterNameValidation;

  /// No description provided for @invalidDateValidation.
  ///
  /// In en, this message translates to:
  /// **'Use a valid date like 2026-03-20.'**
  String get invalidDateValidation;

  /// No description provided for @correspondentCreated.
  ///
  /// In en, this message translates to:
  /// **'Correspondent created.'**
  String get correspondentCreated;

  /// No description provided for @correspondentRenamed.
  ///
  /// In en, this message translates to:
  /// **'Correspondent renamed.'**
  String get correspondentRenamed;

  /// No description provided for @correspondentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Correspondent deleted.'**
  String get correspondentDeleted;

  /// No description provided for @documentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Document deleted.'**
  String get documentDeleted;

  /// No description provided for @documentTypeCreated.
  ///
  /// In en, this message translates to:
  /// **'Document type created.'**
  String get documentTypeCreated;

  /// No description provided for @documentTypeRenamed.
  ///
  /// In en, this message translates to:
  /// **'Document type renamed.'**
  String get documentTypeRenamed;

  /// No description provided for @documentTypeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Document type deleted.'**
  String get documentTypeDeleted;

  /// No description provided for @tagCreated.
  ///
  /// In en, this message translates to:
  /// **'Tag created.'**
  String get tagCreated;

  /// No description provided for @tagRenamed.
  ///
  /// In en, this message translates to:
  /// **'Tag renamed.'**
  String get tagRenamed;

  /// No description provided for @tagDeleted.
  ///
  /// In en, this message translates to:
  /// **'Tag deleted.'**
  String get tagDeleted;

  /// No description provided for @couldNotLoadDocumentDetails.
  ///
  /// In en, this message translates to:
  /// **'Could not load the document details.'**
  String get couldNotLoadDocumentDetails;

  /// No description provided for @documentSubtitleUploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded {timestamp}'**
  String documentSubtitleUploaded(Object timestamp);

  /// No description provided for @documentSubtitleDated.
  ///
  /// In en, this message translates to:
  /// **'Dated {timestamp}'**
  String documentSubtitleDated(Object timestamp);

  /// No description provided for @documentPages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {1 page} other {{count} pages}}'**
  String documentPages(int count);

  /// No description provided for @documentAsn.
  ///
  /// In en, this message translates to:
  /// **'ASN {value}'**
  String documentAsn(int value);

  /// No description provided for @documentFallback.
  ///
  /// In en, this message translates to:
  /// **'Document #{id}'**
  String documentFallback(int id);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
