// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Paperless Go';

  @override
  String get navigationHome => 'Start';

  @override
  String get navigationLibrary => 'Bibliothek';

  @override
  String get navigationDocuments => 'Dokumente';

  @override
  String get navigationRecent => 'Neueste';

  @override
  String get navigationInbox => 'Posteingang';

  @override
  String get navigationProfile => 'Profil';

  @override
  String get navigationReview => 'Prüfen';

  @override
  String get serverUrlLabel => 'Server-URL';

  @override
  String get serverUrlHint => 'https://paperless.example.com';

  @override
  String get usernameLabel => 'Benutzername';

  @override
  String get usernameHint => 'john.doe';

  @override
  String get passwordLabel => 'Passwort';

  @override
  String get passwordHint => 'Passwort eingeben';

  @override
  String get cancelAction => 'Abbrechen';

  @override
  String get clearAction => 'Leeren';

  @override
  String get applyAction => 'Anwenden';

  @override
  String get retryAction => 'Erneut versuchen';

  @override
  String get deleteAction => 'Löschen';

  @override
  String get renameAction => 'Umbenennen';

  @override
  String get saveAction => 'Speichern';

  @override
  String get savingAction => 'Speichert...';

  @override
  String get createAction => 'Erstellen';

  @override
  String get addingAction => 'Wird hinzugefügt...';

  @override
  String get loadingStatus => 'Wird geladen...';

  @override
  String get couldNotLoadStatus => 'Konnte nicht geladen werden';

  @override
  String get loginConnectTitle => 'Mit deinem Server verbinden';

  @override
  String get loginConnectDescription =>
      'Verwende deine paperless-ngx-URL und Zugangsdaten, um auf deine Dokumente zuzugreifen.';

  @override
  String get loginButton => 'Anmelden';

  @override
  String connectedAs(Object displayName) {
    return 'Verbunden als $displayName';
  }

  @override
  String get loginValidationServerUrlRequired =>
      'Gib die URL deines paperless-ngx-Servers ein.';

  @override
  String get loginValidationFullUrl =>
      'Verwende eine vollständige URL wie https://paperless.example.com.';

  @override
  String get loginValidationUsernameRequired => 'Gib deinen Benutzernamen ein.';

  @override
  String get loginValidationPasswordRequired => 'Gib dein Passwort ein.';

  @override
  String get loginSuccess => 'Verbindung erfolgreich hergestellt.';

  @override
  String get loginFailedGeneric =>
      'Anmeldung fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get authUnexpectedResponse =>
      'Der Server hat eine unerwartete Antwort zurückgegeben.';

  @override
  String get authWrongPageInsteadOfApi =>
      'Die Anfrage hat statt der API die falsche paperless-Seite erreicht. Prüfe die Basis-URL, besonders wenn der Server unter einem Unterpfad gehostet wird.';

  @override
  String get authAuthenticationFailed =>
      'Authentifizierung fehlgeschlagen. Prüfe URL, Benutzername und Passwort.';

  @override
  String get authServerRejectedLogin =>
      'Der Server hat die Anmeldung abgelehnt. Prüfe die Basis-URL, besonders wenn paperless-ngx unter einem Unterpfad gehostet wird.';

  @override
  String get authUnableToReachServer =>
      'Der paperless-ngx-Server ist nicht erreichbar.';

  @override
  String get authInvalidServerUrl =>
      'Gib eine gültige Server-URL inklusive http:// oder https:// ein.';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsConnectionSection => 'Verbindung';

  @override
  String get settingsAppearanceBehaviorSection => 'Darstellung und Verhalten';

  @override
  String get settingsSecuritySection => 'Sicherheit';

  @override
  String get settingsServerUrlSubtitle =>
      'Paperless-ngx-Endpunkt für Anmeldung, Synchronisierung und Downloads.';

  @override
  String get settingsUsernameSubtitle =>
      'Konto zur Authentifizierung am Server.';

  @override
  String get settingsPasswordSubtitle =>
      'Wird lokal gespeichert und beim Speichern erneut geprüft.';

  @override
  String get saveSettingsAction => 'Einstellungen speichern';

  @override
  String get settingsSaveSuccess =>
      'Einstellungen gespeichert und Verbindung geprüft.';

  @override
  String get settingsSaveFailedGeneric =>
      'Einstellungen konnten nicht gespeichert werden. Bitte versuche es erneut.';

  @override
  String get appLanguageTitle => 'App-Sprache';

  @override
  String get appLanguageSubtitle =>
      'Wähle, ob die App der Systemsprache folgt oder immer eine bestimmte Übersetzung verwendet.';

  @override
  String get appLanguageSystem => 'Systemstandard';

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
  String get themeModeTitle => 'Designmodus';

  @override
  String get themeModeSubtitle =>
      'Wähle, ob die App das helle oder dunkle Farbschema verwendet.';

  @override
  String get themeModeLight => 'Hell';

  @override
  String get themeModeDark => 'Dunkel';

  @override
  String get cachePreviewsTitle => 'Miniaturansichten und Vorschauen cachen';

  @override
  String get cachePreviewsSubtitle =>
      'Speichert die Einstellung dauerhaft, während die lokale Zwischenspeicherung erweitert wird.';

  @override
  String get biometricLockTitle => 'Face ID oder Fingerabdruck verwenden';

  @override
  String get biometricLockSubtitle =>
      'Fordert eine biometrische oder Geräte-Anmeldung an, wenn du nach einer Hintergrundpause zur App zurückkehrst.';

  @override
  String get appLockTimeoutTitle => 'Beim Wiederöffnen sperren nach';

  @override
  String get appLockTimeoutSubtitle =>
      'Lege fest, wie lange die App im Hintergrund bleiben darf, bevor sie erneut entsperrt werden muss.';

  @override
  String get appLockTimeoutImmediate => 'Sofort';

  @override
  String get appLockTimeout30Seconds => '30 Sekunden';

  @override
  String get appLockTimeout1Minute => '1 Minute';

  @override
  String get appLockTimeout5Minutes => '5 Minuten';

  @override
  String get biometricLockUnavailable =>
      'Biometrische Authentifizierung ist auf diesem Gerät derzeit nicht verfügbar.';

  @override
  String get biometricLockEnableFailed =>
      'Die biometrische Bestätigung ist fehlgeschlagen, daher bleibt die App-Sperre deaktiviert.';

  @override
  String get biometricEnableReason =>
      'Bestätige deine Identität, um die App-Sperre für Paperless Go zu aktivieren.';

  @override
  String get biometricPromptTitle => 'Paperless Go schützen?';

  @override
  String get biometricPromptMessage =>
      'Aktiviere jetzt Face ID oder den Fingerabdruck, um deine Dokumente beim Zurückkehren zur App zu schützen.';

  @override
  String get biometricPromptNotNowAction => 'Jetzt nicht';

  @override
  String get biometricPromptEnableAction => 'Jetzt aktivieren';

  @override
  String get biometricUnlockTitle => 'Paperless Go entsperren';

  @override
  String get biometricUnlockSubtitle =>
      'Verwende Face ID, Touch ID oder deine Geräte-Anmeldedaten, um fortzufahren.';

  @override
  String get biometricUnlockAction => 'Entsperren';

  @override
  String get biometricUnlockingStatus => 'Wird entsperrt...';

  @override
  String get biometricUnlockReason =>
      'Bestätige deine Identität, um Paperless Go zu entsperren.';

  @override
  String get biometricUnlockFailed =>
      'Die Authentifizierung wurde abgebrochen oder ist fehlgeschlagen. Versuche es erneut.';

  @override
  String get signOutAction => 'Abmelden';

  @override
  String get retryTagLoadingAction => 'Tags erneut laden';

  @override
  String get noTagsAvailableOnServer =>
      'Auf dem Server sind keine Tags verfügbar.';

  @override
  String get homeRefreshTooltip => 'Startseite aktualisieren';

  @override
  String get logoutTooltip => 'Abmelden';

  @override
  String get recentUploadsTab => 'Neueste Uploads';

  @override
  String get todosTab => 'Todos';

  @override
  String get scanLaterAction => 'Später scannen';

  @override
  String get scanDocumentAction => 'Dokument scannen';

  @override
  String get scanDocumentTitle => 'Dokument scannen';

  @override
  String get scanDocumentDescription =>
      'Erfasse eine oder mehrere Seiten oder wähle eine vorhandene Datei auf deinem Gerät aus, prüfe sie und lade sie zu paperless-ngx hoch.';

  @override
  String get scanDocumentEmptyTitle => 'Neuen Scan starten';

  @override
  String get scanDocumentEmptyDescription =>
      'Verwende die Kamera deines Geräts, um ein Papierdokument zu erfassen, oder wähle eine vorhandene Datei auf deinem Gerät aus.';

  @override
  String get scanDocumentTitleFieldLabel => 'Dokumenttitel';

  @override
  String get scanDocumentTitleFieldHint => 'Optionaler abweichender Titel';

  @override
  String scanDocumentPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gescannte Seiten',
      one: '1 gescannte Seite',
    );
    return '$_temp0';
  }

  @override
  String get scanDocumentAddPagesAction => 'Weitere Seiten scannen';

  @override
  String get scanDocumentReplacePagesAction => 'Neu scannen';

  @override
  String get scanDocumentUploadAction => 'Scan hochladen';

  @override
  String get scanDocumentUploadingAction => 'Lädt hoch...';

  @override
  String get scanDocumentQueued => 'Scan zur Verarbeitung vorgemerkt.';

  @override
  String get scanDocumentScanFailed =>
      'Der Scanner konnte auf diesem Gerät nicht gestartet werden.';

  @override
  String get scanDocumentUploadFailed =>
      'Der Scan konnte nicht hochgeladen werden.';

  @override
  String get scanDocumentImportAction => 'Vom Gerät auswählen';

  @override
  String get scanDocumentImportFailed =>
      'Auf diesem Gerät konnte kein Dokument ausgewählt werden.';

  @override
  String get removeScannedPageTooltip => 'Gescannte Seite entfernen';

  @override
  String scannedPageLabel(int page) {
    return 'Seite $page';
  }

  @override
  String get homeUpdated => 'Startseite aktualisiert.';

  @override
  String get homeRefreshFailed =>
      'Aktualisierung der Startseite fehlgeschlagen.';

  @override
  String get noUploadsYetTitle => 'Noch keine Uploads';

  @override
  String get noUploadsYetDescription =>
      'Neueste Dokumente erscheinen hier, sobald dein Server Uploads verarbeitet hat.';

  @override
  String get couldNotLoadRecentUploadsTitle =>
      'Neueste Uploads konnten nicht geladen werden';

  @override
  String get couldNotLoadRecentUploadsDescription =>
      'Die Startseite hat deinen Server erreicht, aber das Laden der Dokumente ist fehlgeschlagen. Ziehe später zum Aktualisieren nach unten.';

  @override
  String get nothingToReviewTitle => 'Nichts zu prüfen';

  @override
  String get nothingToReviewDescription =>
      'Dokumente, die sich aktuell im Inbox befinden, erscheinen hier zur manuellen Prüfung.';

  @override
  String get verificationQueueTitle => 'Prüfwarteschlange';

  @override
  String get verificationQueueDescription =>
      'Dokumente, die sich aktuell im Inbox befinden, werden hier zur manuellen Prüfung angezeigt.';

  @override
  String get couldNotLoadReviewQueueTitle =>
      'Prüfwarteschlange konnte nicht geladen werden';

  @override
  String get couldNotLoadReviewQueueDescription =>
      'Die App konnte Inbox-Dokumente zur manuellen Prüfung gerade nicht laden.';

  @override
  String get drawerMainMenu => 'Hauptmenü';

  @override
  String get drawerCategories => 'Kategorien';

  @override
  String get drawerRecentlyOpened => 'Zuletzt geöffnet';

  @override
  String get drawerSettings => 'Einstellungen';

  @override
  String get drawerHelpFeedback => 'Hilfe und Feedback';

  @override
  String get drawerStatisticsTitle => 'Statistiken';

  @override
  String get drawerDocuments => 'Dokumente';

  @override
  String get drawerCorrespondents => 'Korrespondenten';

  @override
  String get drawerTags => 'Tags';

  @override
  String get drawerDocumentTypes => 'Dokumenttypen';

  @override
  String get drawerStatisticsUnavailable =>
      'Statistiken sind derzeit nicht verfügbar.';

  @override
  String get managementOptionsEmpty =>
      'Noch keine Einträge vorhanden. Verwende die Erstellen-Aktion, um einen hinzuzufügen.';

  @override
  String get managementSearchHint => 'Typen suchen';

  @override
  String get noManagementOptionsMatchSearch =>
      'Keine Einträge entsprechen der aktuellen Suche.';

  @override
  String get renameCorrespondentAction => 'Korrespondent umbenennen';

  @override
  String get renameDocumentTypeAction => 'Dokumenttyp umbenennen';

  @override
  String get renameTagAction => 'Tag umbenennen';

  @override
  String get deleteCorrespondentAction => 'Korrespondent löschen';

  @override
  String get deleteDocumentAction => 'Dokument löschen';

  @override
  String get deleteDocumentTypeAction => 'Dokumenttyp löschen';

  @override
  String get deleteTagAction => 'Tag löschen';

  @override
  String deleteCorrespondentConfirmationMessage(Object name) {
    return '\"$name\" löschen? Diese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String deleteDocumentConfirmationMessage(Object name) {
    return '\"$name\" löschen? Diese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String deleteDocumentTypeConfirmationMessage(Object name) {
    return '\"$name\" löschen? Diese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String deleteTagConfirmationMessage(Object name) {
    return '\"$name\" löschen? Diese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String refreshFailedLabel(Object timestamp) {
    return 'Aktualisierung fehlgeschlagen $timestamp';
  }

  @override
  String get refreshingLabel => 'Wird aktualisiert...';

  @override
  String get waitingForFirstSyncLabel => 'Warte auf erste Synchronisierung';

  @override
  String refreshingLastUpdatedLabel(Object timestamp) {
    return 'Wird aktualisiert... zuletzt aktualisiert $timestamp';
  }

  @override
  String get updatedJustNowLabel => 'Gerade eben aktualisiert';

  @override
  String updatedMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Vor $minutes Min. aktualisiert',
      one: 'Vor 1 Min. aktualisiert',
    );
    return '$_temp0';
  }

  @override
  String updatedAtLabel(Object timestamp) {
    return 'Aktualisiert $timestamp';
  }

  @override
  String todayAtLabel(Object time) {
    return 'heute um $time';
  }

  @override
  String yesterdayAtLabel(Object time) {
    return 'gestern um $time';
  }

  @override
  String get documentsTitle => 'Dokumente';

  @override
  String get refreshDocumentsTooltip => 'Dokumente aktualisieren';

  @override
  String get searchByTitleHint => 'Nach Titel suchen';

  @override
  String get clearSearchTooltip => 'Suche leeren';

  @override
  String get filtersTooltip => 'Filter';

  @override
  String connectedToServer(Object serverUrl) {
    return 'Verbunden mit $serverUrl';
  }

  @override
  String get documentsUpdated => 'Dokumente aktualisiert.';

  @override
  String get documentRefreshFailed =>
      'Aktualisierung der Dokumente fehlgeschlagen.';

  @override
  String get filtersTitle => 'Filter';

  @override
  String get resetAction => 'Zurücksetzen';

  @override
  String get sortByLabel => 'Sortieren nach';

  @override
  String get filterTagLabel => 'Tag';

  @override
  String get filterCorrespondentLabel => 'Korrespondent';

  @override
  String get filterDocumentTypeLabel => 'Dokumenttyp';

  @override
  String get anyOption => 'Beliebig';

  @override
  String get applyFiltersAction => 'Filter anwenden';

  @override
  String get sortCreatedNewest => 'Erstellungsdatum (neueste zuerst)';

  @override
  String get sortCreatedOldest => 'Erstellungsdatum (älteste zuerst)';

  @override
  String get sortAddedNewest => 'Hinzugefügt am (neueste zuerst)';

  @override
  String get sortAddedOldest => 'Hinzugefügt am (älteste zuerst)';

  @override
  String get sortTitleAz => 'Titel (A-Z)';

  @override
  String get sortTitleZa => 'Titel (Z-A)';

  @override
  String documentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dokumente',
      one: '1 Dokument',
    );
    return '$_temp0';
  }

  @override
  String get noDocumentsMatchSearch =>
      'Keine Dokumente entsprechen der aktuellen Suche.';

  @override
  String get detailsAction => 'Details';

  @override
  String get openAction => 'Öffnen';

  @override
  String get openingAction => 'Wird geöffnet...';

  @override
  String get previousAction => 'Zurück';

  @override
  String pageIndicator(int page) {
    return 'Seite $page';
  }

  @override
  String get nextAction => 'Weiter';

  @override
  String get couldNotLoadDocuments => 'Dokumente konnten nicht geladen werden.';

  @override
  String get recentlyOpenedTitle => 'Zuletzt geöffnet';

  @override
  String get clearHistoryTooltip => 'Verlauf leeren';

  @override
  String get recentlyOpenedEmpty =>
      'Dokumente, die du öffnest oder ansiehst, erscheinen hier.';

  @override
  String get clearRecentlyOpenedTitle => 'Zuletzt geöffnet leeren?';

  @override
  String get clearRecentlyOpenedDescription =>
      'Dadurch wird der lokale Verlauf der über das Menü geöffneten Dokumente entfernt.';

  @override
  String get recentlyOpenedCleared => 'Zuletzt geöffnet wurde geleert.';

  @override
  String openedAtLabel(Object time) {
    return 'Geöffnet $time';
  }

  @override
  String get helpFeedbackTitle => 'Hilfe und Feedback';

  @override
  String get documentationTitle => 'Dokumentation';

  @override
  String get documentationDescription =>
      'Öffnet die paperless-ngx-Dokumentation für Einrichtung, Nutzung und API-Hinweise.';

  @override
  String get reportIssueTitle => 'Problem melden';

  @override
  String get reportIssueDescription =>
      'Öffnet den Upstream-Issue-Tracker, um Fehler zu melden oder Verbesserungen vorzuschlagen.';

  @override
  String get donateTitle => 'Spenden';

  @override
  String get donateDescription =>
      'Wähle einen Betrag und setze im Browser fort, um die Entwicklung zu unterstützen.';

  @override
  String get donateDialogTitle => 'Entwicklung unterstützen';

  @override
  String get donateAmountLabel => 'Betrag';

  @override
  String get donateAmountHint => '5,00';

  @override
  String get donateContinueAction => 'Weiter zur Spende';

  @override
  String get donateInvalidAmount => 'Gib einen Betrag größer als 0 ein.';

  @override
  String get copySupportSummaryTitle => 'Support-Zusammenfassung kopieren';

  @override
  String get copySupportSummaryDescription =>
      'Kopiert App-Version und Serverdetails in die Zwischenablage, bevor du Feedback meldest.';

  @override
  String get supportSummaryCopied => 'Support-Zusammenfassung kopiert.';

  @override
  String get unknownLabel => 'unbekannt';

  @override
  String get documentDetailsTitle => 'Dokumentdetails';

  @override
  String get editMetadataAction => 'Metadaten bearbeiten';

  @override
  String get openDocumentAction => 'Dokument öffnen';

  @override
  String get openOriginalAction => 'Original öffnen';

  @override
  String get thumbnailPreviewTitle => 'Miniaturvorschau';

  @override
  String get noThumbnailPreviewAvailable => 'Keine Miniaturvorschau verfügbar.';

  @override
  String authenticatedThumbnailRequest(Object serverUrl) {
    return 'Authentifizierte Miniatur-Anfrage für $serverUrl';
  }

  @override
  String get metadataTitle => 'Metadaten';

  @override
  String get fileNameLabel => 'Dateiname';

  @override
  String get mimeTypeLabel => 'MIME-Typ';

  @override
  String get createdLabel => 'Erstellt';

  @override
  String get addedLabel => 'Hinzugefügt';

  @override
  String get pagesLabel => 'Seiten';

  @override
  String get archiveSerialNumberLabel => 'Archiv-Seriennummer';

  @override
  String get correspondentLabel => 'Korrespondent';

  @override
  String get documentTypeLabel => 'Dokumenttyp';

  @override
  String get tagsLabel => 'Tags';

  @override
  String get contentPreviewTitle => 'Inhaltsvorschau';

  @override
  String get metadataUpdated => 'Metadaten aktualisiert.';

  @override
  String get editMetadataTitle => 'Metadaten bearbeiten';

  @override
  String get editableFieldsTitle => 'Bearbeitbare Felder';

  @override
  String get titleLabel => 'Titel';

  @override
  String get createdDateLabel => 'Erstellungsdatum';

  @override
  String get createdDateHint => 'JJJJ-MM-TT';

  @override
  String get newCorrespondentAction => 'Neuen Korrespondenten';

  @override
  String get correspondentNameLabel => 'Name des Korrespondenten';

  @override
  String get chooseCorrespondentHint => 'Korrespondenten wählen';

  @override
  String get noCorrespondentOption => 'Kein Korrespondent';

  @override
  String get couldNotLoadCorrespondents =>
      'Korrespondenten konnten nicht geladen werden.';

  @override
  String get selectCorrespondentDialogTitle => 'Korrespondenten auswählen';

  @override
  String get searchCorrespondentsHint => 'Korrespondenten suchen';

  @override
  String get noCorrespondentsMatchSearch =>
      'Keine Korrespondenten entsprechen der aktuellen Suche.';

  @override
  String get newDocumentTypeAction => 'Neuen Dokumenttyp';

  @override
  String get documentTypeNameLabel => 'Name des Dokumenttyps';

  @override
  String get chooseDocumentTypeHint => 'Dokumenttyp wählen';

  @override
  String get noDocumentTypeOption => 'Kein Dokumenttyp';

  @override
  String get couldNotLoadDocumentTypes =>
      'Dokumenttypen konnten nicht geladen werden.';

  @override
  String get selectDocumentTypeDialogTitle => 'Dokumenttyp auswählen';

  @override
  String get searchDocumentTypesHint => 'Dokumenttypen suchen';

  @override
  String get noDocumentTypesMatchSearch =>
      'Keine Dokumenttypen entsprechen der aktuellen Suche.';

  @override
  String get newTagAction => 'Neues Tag';

  @override
  String get tagNameLabel => 'Tag-Name';

  @override
  String get noTagsSelected => 'Keine Tags ausgewählt.';

  @override
  String get editTagsAction => 'Tags bearbeiten';

  @override
  String get selectTagsDialogTitle => 'Tags auswählen';

  @override
  String get searchTagsHint => 'Tags suchen';

  @override
  String get selectedTagsSectionTitle => 'Ausgewählte Tags';

  @override
  String get availableTagsSectionTitle => 'Alle Tags';

  @override
  String get noTagsMatchSearch => 'Keine Tags entsprechen der aktuellen Suche.';

  @override
  String createTagConfirmationMessage(Object name) {
    return '\"$name\" erstellen und zu diesem Dokument hinzufügen?';
  }

  @override
  String get enterNameValidation => 'Gib einen Namen ein.';

  @override
  String get invalidDateValidation =>
      'Verwende ein gültiges Datum wie 2026-03-20.';

  @override
  String get correspondentCreated => 'Korrespondent erstellt.';

  @override
  String get correspondentRenamed => 'Korrespondent umbenannt.';

  @override
  String get correspondentDeleted => 'Korrespondent gelöscht.';

  @override
  String get documentDeleted => 'Dokument gelöscht.';

  @override
  String get documentTypeCreated => 'Dokumenttyp erstellt.';

  @override
  String get documentTypeRenamed => 'Dokumenttyp umbenannt.';

  @override
  String get documentTypeDeleted => 'Dokumenttyp gelöscht.';

  @override
  String get tagCreated => 'Tag erstellt.';

  @override
  String get tagRenamed => 'Tag umbenannt.';

  @override
  String get tagDeleted => 'Tag gelöscht.';

  @override
  String get couldNotLoadDocumentDetails =>
      'Die Dokumentdetails konnten nicht geladen werden.';

  @override
  String documentSubtitleUploaded(Object timestamp) {
    return 'Hochgeladen $timestamp';
  }

  @override
  String documentSubtitleDated(Object timestamp) {
    return 'Datiert $timestamp';
  }

  @override
  String documentPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Seiten',
      one: '1 Seite',
    );
    return '$_temp0';
  }

  @override
  String documentAsn(int value) {
    return 'ASN $value';
  }

  @override
  String documentFallback(int id) {
    return 'Dokument #$id';
  }
}
