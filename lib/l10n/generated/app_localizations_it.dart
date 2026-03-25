// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Paperless Go';

  @override
  String get navigationHome => 'Home';

  @override
  String get navigationDocuments => 'Documenti';

  @override
  String get navigationRecent => 'Recenti';

  @override
  String get navigationInbox => 'Posta in arrivo';

  @override
  String get navigationReview => 'Verifica';

  @override
  String get serverUrlLabel => 'URL del server';

  @override
  String get serverUrlHint => 'https://paperless.example.com';

  @override
  String get usernameLabel => 'Nome utente';

  @override
  String get usernameHint => 'john.doe';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Inserisci la password';

  @override
  String get cancelAction => 'Annulla';

  @override
  String get clearAction => 'Cancella';

  @override
  String get applyAction => 'Applica';

  @override
  String get retryAction => 'Riprova';

  @override
  String get deleteAction => 'Elimina';

  @override
  String get renameAction => 'Rinomina';

  @override
  String get saveAction => 'Salva';

  @override
  String get savingAction => 'Salvataggio...';

  @override
  String get createAction => 'Crea';

  @override
  String get addingAction => 'Aggiunta...';

  @override
  String get loadingStatus => 'Caricamento...';

  @override
  String get couldNotLoadStatus => 'Impossibile caricare';

  @override
  String get loginConnectTitle => 'Connettiti al tuo server';

  @override
  String get loginConnectDescription =>
      'Usa l\'URL della tua istanza paperless-ngx e le credenziali del tuo account per accedere ai documenti.';

  @override
  String get loginButton => 'Accedi';

  @override
  String connectedAs(Object displayName) {
    return 'Connesso come $displayName';
  }

  @override
  String get loginValidationServerUrlRequired =>
      'Inserisci l\'URL del tuo server paperless-ngx.';

  @override
  String get loginValidationFullUrl =>
      'Usa un URL completo come https://paperless.example.com.';

  @override
  String get loginValidationUsernameRequired => 'Inserisci il nome utente.';

  @override
  String get loginValidationPasswordRequired => 'Inserisci la password.';

  @override
  String get loginSuccess => 'Connessione riuscita.';

  @override
  String get loginFailedGeneric => 'Accesso non riuscito. Riprova.';

  @override
  String get authUnexpectedResponse =>
      'Il server ha restituito una risposta inattesa.';

  @override
  String get authWrongPageInsteadOfApi =>
      'La richiesta ha raggiunto la pagina paperless sbagliata invece dell\'API. Controlla l\'URL di base, soprattutto se il server è ospitato sotto un sottopercorso.';

  @override
  String get authAuthenticationFailed =>
      'Autenticazione non riuscita. Controlla URL, nome utente e password.';

  @override
  String get authServerRejectedLogin =>
      'Il server ha rifiutato la richiesta di accesso. Controlla l\'URL di base, soprattutto se paperless-ngx è ospitato sotto un sottopercorso.';

  @override
  String get authUnableToReachServer =>
      'Impossibile raggiungere il server paperless-ngx.';

  @override
  String get authInvalidServerUrl =>
      'Inserisci un URL del server valido che includa http:// o https://.';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsConnectionSection => 'Connessione';

  @override
  String get settingsAppearanceBehaviorSection => 'Aspetto e comportamento';

  @override
  String get settingsSecuritySection => 'Sicurezza';

  @override
  String get settingsServerUrlSubtitle =>
      'Endpoint paperless-ngx usato per accesso, sincronizzazione e download.';

  @override
  String get settingsUsernameSubtitle =>
      'Account usato per autenticarsi sul server.';

  @override
  String get settingsPasswordSubtitle =>
      'Salvata localmente e verificata di nuovo al salvataggio.';

  @override
  String get saveSettingsAction => 'Salva impostazioni';

  @override
  String get settingsSaveSuccess =>
      'Impostazioni salvate e connessione verificata.';

  @override
  String get settingsSaveFailedGeneric =>
      'Impossibile salvare le impostazioni. Riprova.';

  @override
  String get appLanguageTitle => 'Lingua dell\'app';

  @override
  String get appLanguageSubtitle =>
      'Scegli se l\'app deve seguire la lingua del sistema o usare sempre una traduzione specifica.';

  @override
  String get appLanguageSystem => 'Predefinita del sistema';

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
  String get themeModeTitle => 'Tema';

  @override
  String get themeModeSubtitle =>
      'Scegli se l\'app usa la palette chiara o scura.';

  @override
  String get themeModeLight => 'Chiaro';

  @override
  String get themeModeDark => 'Scuro';

  @override
  String get cachePreviewsTitle => 'Memorizza miniature e anteprime';

  @override
  String get cachePreviewsSubtitle =>
      'Mantiene la preferenza per una navigazione più rapida mentre cresce la cache locale.';

  @override
  String get biometricLockTitle => 'Usa Face ID o impronta digitale';

  @override
  String get biometricLockSubtitle =>
      'Richiede una verifica biometrica o delle credenziali del dispositivo quando torni all\'app dopo essere stata in background.';

  @override
  String get appLockTimeoutTitle => 'Blocca alla riapertura dopo';

  @override
  String get appLockTimeoutSubtitle =>
      'Scegli per quanto tempo l\'app può restare in background prima di richiedere di nuovo lo sblocco.';

  @override
  String get appLockTimeoutImmediate => 'Subito';

  @override
  String get appLockTimeout30Seconds => '30 secondi';

  @override
  String get appLockTimeout1Minute => '1 minuto';

  @override
  String get appLockTimeout5Minutes => '5 minuti';

  @override
  String get biometricLockUnavailable =>
      'L\'autenticazione biometrica non è disponibile su questo dispositivo in questo momento.';

  @override
  String get biometricLockEnableFailed =>
      'L\'autenticazione biometrica non è stata confermata, quindi il blocco dell\'app resta disattivato.';

  @override
  String get biometricEnableReason =>
      'Conferma la tua identità per abilitare il blocco di Paperless Go.';

  @override
  String get biometricPromptTitle => 'Proteggere Paperless Go?';

  @override
  String get biometricPromptMessage =>
      'Abilita ora Face ID o l\'impronta digitale per proteggere i tuoi documenti quando torni nell\'app.';

  @override
  String get biometricPromptNotNowAction => 'Non ora';

  @override
  String get biometricPromptEnableAction => 'Abilita ora';

  @override
  String get biometricUnlockTitle => 'Sblocca Paperless Go';

  @override
  String get biometricUnlockSubtitle =>
      'Usa Face ID, Touch ID o le credenziali del dispositivo per continuare.';

  @override
  String get biometricUnlockAction => 'Sblocca';

  @override
  String get biometricUnlockingStatus => 'Sblocco in corso...';

  @override
  String get biometricUnlockReason =>
      'Conferma la tua identità per sbloccare Paperless Go.';

  @override
  String get biometricUnlockFailed =>
      'L\'autenticazione è stata annullata o non è riuscita. Riprova per continuare.';

  @override
  String get signOutAction => 'Esci';

  @override
  String get retryTagLoadingAction => 'Ricarica tag';

  @override
  String get noTagsAvailableOnServer => 'Nessun tag disponibile sul server.';

  @override
  String get homeRefreshTooltip => 'Aggiorna home';

  @override
  String get logoutTooltip => 'Disconnetti';

  @override
  String get recentUploadsTab => 'Caricamenti recenti';

  @override
  String get todosTab => 'Todos';

  @override
  String get scanLaterAction => 'Scansiona più tardi';

  @override
  String get scanDocumentAction => 'Scansiona documento';

  @override
  String get scanDocumentTitle => 'Scansiona documento';

  @override
  String get scanDocumentDescription =>
      'Acquisisci una o più pagine, controllale e carica il PDF risultante su paperless-ngx.';

  @override
  String get scanDocumentEmptyTitle => 'Avvia una nuova scansione';

  @override
  String get scanDocumentEmptyDescription =>
      'Usa la fotocamera del dispositivo per acquisire un documento cartaceo. Tutte le pagine scansionate vengono unite in un unico PDF prima del caricamento.';

  @override
  String get scanDocumentTitleFieldLabel => 'Titolo del documento';

  @override
  String get scanDocumentTitleFieldHint => 'Titolo facoltativo da usare';

  @override
  String scanDocumentPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pagine scansionate',
      one: '1 pagina scansionata',
    );
    return '$_temp0';
  }

  @override
  String get scanDocumentAddPagesAction => 'Scansiona altre pagine';

  @override
  String get scanDocumentReplacePagesAction => 'Scansiona di nuovo';

  @override
  String get scanDocumentUploadAction => 'Carica scansione';

  @override
  String get scanDocumentUploadingAction => 'Caricamento...';

  @override
  String get scanDocumentQueued => 'Scansione accodata per l\'elaborazione.';

  @override
  String get scanDocumentScanFailed =>
      'Impossibile avviare lo scanner su questo dispositivo.';

  @override
  String get scanDocumentUploadFailed => 'Impossibile caricare la scansione.';

  @override
  String get removeScannedPageTooltip => 'Rimuovi pagina scansionata';

  @override
  String scannedPageLabel(int page) {
    return 'Pagina $page';
  }

  @override
  String get homeUpdated => 'Home aggiornata.';

  @override
  String get homeRefreshFailed => 'Aggiornamento della home non riuscito.';

  @override
  String get noUploadsYetTitle => 'Nessun caricamento ancora';

  @override
  String get noUploadsYetDescription =>
      'I documenti recenti appariranno qui una volta che il server avrà elaborato i caricamenti.';

  @override
  String get couldNotLoadRecentUploadsTitle =>
      'Impossibile caricare i caricamenti recenti';

  @override
  String get couldNotLoadRecentUploadsDescription =>
      'La home ha raggiunto il server, ma il caricamento dei documenti non è riuscito. Trascina per aggiornare più tardi.';

  @override
  String get nothingToReviewTitle => 'Nulla da verificare';

  @override
  String get nothingToReviewDescription =>
      'I documenti attualmente nella tua inbox compaiono qui per la verifica manuale.';

  @override
  String get verificationQueueTitle => 'Coda di verifica';

  @override
  String get verificationQueueDescription =>
      'I documenti attualmente nella tua inbox sono elencati qui per la revisione manuale.';

  @override
  String get couldNotLoadReviewQueueTitle =>
      'Impossibile caricare la coda di verifica';

  @override
  String get couldNotLoadReviewQueueDescription =>
      'L\'app non riesce a caricare in questo momento i documenti della inbox da verificare.';

  @override
  String get drawerRecentlyOpened => 'Aperti di recente';

  @override
  String get drawerSettings => 'Impostazioni';

  @override
  String get drawerHelpFeedback => 'Aiuto e feedback';

  @override
  String get drawerStatisticsTitle => 'Statistiche';

  @override
  String get drawerDocuments => 'Documenti';

  @override
  String get drawerCorrespondents => 'Corrispondenti';

  @override
  String get drawerTags => 'Tag';

  @override
  String get drawerDocumentTypes => 'Tipi di documento';

  @override
  String get drawerStatisticsUnavailable =>
      'Le statistiche non sono disponibili al momento.';

  @override
  String get managementOptionsEmpty =>
      'Nessun elemento disponibile al momento. Usa l\'azione di creazione per aggiungerne uno.';

  @override
  String get managementSearchHint => 'Cerca tipi';

  @override
  String get noManagementOptionsMatchSearch =>
      'Nessuna voce corrisponde alla ricerca corrente.';

  @override
  String get renameCorrespondentAction => 'Rinomina corrispondente';

  @override
  String get renameDocumentTypeAction => 'Rinomina tipo di documento';

  @override
  String get renameTagAction => 'Rinomina tag';

  @override
  String get deleteCorrespondentAction => 'Elimina corrispondente';

  @override
  String get deleteDocumentAction => 'Elimina documento';

  @override
  String get deleteDocumentTypeAction => 'Elimina tipo di documento';

  @override
  String get deleteTagAction => 'Elimina tag';

  @override
  String deleteCorrespondentConfirmationMessage(Object name) {
    return 'Eliminare \"$name\"? Questa azione non può essere annullata.';
  }

  @override
  String deleteDocumentConfirmationMessage(Object name) {
    return 'Eliminare \"$name\"? Questa azione non può essere annullata.';
  }

  @override
  String deleteDocumentTypeConfirmationMessage(Object name) {
    return 'Eliminare \"$name\"? Questa azione non può essere annullata.';
  }

  @override
  String deleteTagConfirmationMessage(Object name) {
    return 'Eliminare \"$name\"? Questa azione non può essere annullata.';
  }

  @override
  String refreshFailedLabel(Object timestamp) {
    return 'Aggiornamento non riuscito $timestamp';
  }

  @override
  String get refreshingLabel => 'Aggiornamento...';

  @override
  String get waitingForFirstSyncLabel =>
      'In attesa della prima sincronizzazione';

  @override
  String refreshingLastUpdatedLabel(Object timestamp) {
    return 'Aggiornamento... ultimo aggiornamento $timestamp';
  }

  @override
  String get updatedJustNowLabel => 'Aggiornato ora';

  @override
  String updatedMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min fa',
      one: '1 min fa',
    );
    return 'Aggiornato $_temp0';
  }

  @override
  String updatedAtLabel(Object timestamp) {
    return 'Aggiornato $timestamp';
  }

  @override
  String todayAtLabel(Object time) {
    return 'oggi alle $time';
  }

  @override
  String yesterdayAtLabel(Object time) {
    return 'ieri alle $time';
  }

  @override
  String get documentsTitle => 'Documenti';

  @override
  String get refreshDocumentsTooltip => 'Aggiorna documenti';

  @override
  String get searchByTitleHint => 'Cerca per titolo';

  @override
  String get clearSearchTooltip => 'Cancella ricerca';

  @override
  String get filtersTooltip => 'Filtri';

  @override
  String connectedToServer(Object serverUrl) {
    return 'Connesso a $serverUrl';
  }

  @override
  String get documentsUpdated => 'Documenti aggiornati.';

  @override
  String get documentRefreshFailed =>
      'Aggiornamento dei documenti non riuscito.';

  @override
  String get filtersTitle => 'Filtri';

  @override
  String get resetAction => 'Reimposta';

  @override
  String get sortByLabel => 'Ordina per';

  @override
  String get filterTagLabel => 'Tag';

  @override
  String get filterCorrespondentLabel => 'Corrispondente';

  @override
  String get filterDocumentTypeLabel => 'Tipo di documento';

  @override
  String get anyOption => 'Qualsiasi';

  @override
  String get applyFiltersAction => 'Applica filtri';

  @override
  String get sortCreatedNewest => 'Data di creazione (più recenti prima)';

  @override
  String get sortCreatedOldest => 'Data di creazione (più vecchi prima)';

  @override
  String get sortAddedNewest => 'Data di aggiunta (più recenti prima)';

  @override
  String get sortAddedOldest => 'Data di aggiunta (più vecchi prima)';

  @override
  String get sortTitleAz => 'Titolo (A-Z)';

  @override
  String get sortTitleZa => 'Titolo (Z-A)';

  @override
  String documentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documenti',
      one: '1 documento',
    );
    return '$_temp0';
  }

  @override
  String get noDocumentsMatchSearch =>
      'Nessun documento corrisponde alla ricerca corrente.';

  @override
  String get detailsAction => 'Dettagli';

  @override
  String get openAction => 'Apri';

  @override
  String get openingAction => 'Apertura...';

  @override
  String get previousAction => 'Precedente';

  @override
  String pageIndicator(int page) {
    return 'Pagina $page';
  }

  @override
  String get nextAction => 'Successiva';

  @override
  String get couldNotLoadDocuments => 'Impossibile caricare i documenti.';

  @override
  String get recentlyOpenedTitle => 'Aperti di recente';

  @override
  String get clearHistoryTooltip => 'Cancella cronologia';

  @override
  String get recentlyOpenedEmpty =>
      'I documenti che apri o controlli appariranno qui.';

  @override
  String get clearRecentlyOpenedTitle =>
      'Cancellare gli elementi aperti di recente?';

  @override
  String get clearRecentlyOpenedDescription =>
      'Questo rimuove la cronologia locale dei documenti aperti dal menu.';

  @override
  String get recentlyOpenedCleared => 'Elementi aperti di recente cancellati.';

  @override
  String openedAtLabel(Object time) {
    return 'Aperto alle $time';
  }

  @override
  String get helpFeedbackTitle => 'Aiuto e feedback';

  @override
  String get documentationTitle => 'Documentazione';

  @override
  String get documentationDescription =>
      'Apre la documentazione di paperless-ngx per configurazione, utilizzo e API.';

  @override
  String get reportIssueTitle => 'Segnala un problema';

  @override
  String get reportIssueDescription =>
      'Apre il tracker upstream per segnalare bug o richiedere miglioramenti.';

  @override
  String get donateTitle => 'Fai una donazione';

  @override
  String get donateDescription =>
      'Scegli un importo e continua nel browser per sostenere lo sviluppo.';

  @override
  String get donateDialogTitle => 'Sostieni lo sviluppo';

  @override
  String get donateAmountLabel => 'Importo';

  @override
  String get donateAmountHint => '5,00';

  @override
  String get donateContinueAction => 'Continua con la donazione';

  @override
  String get donateInvalidAmount => 'Inserisci un importo maggiore di 0.';

  @override
  String get copySupportSummaryTitle => 'Copia riepilogo supporto';

  @override
  String get copySupportSummaryDescription =>
      'Copia versione dell\'app e dettagli del server negli appunti prima di inviare feedback.';

  @override
  String get supportSummaryCopied => 'Riepilogo supporto copiato.';

  @override
  String get unknownLabel => 'sconosciuto';

  @override
  String get documentDetailsTitle => 'Dettagli documento';

  @override
  String get editMetadataAction => 'Modifica metadati';

  @override
  String get openDocumentAction => 'Apri documento';

  @override
  String get openOriginalAction => 'Apri originale';

  @override
  String get thumbnailPreviewTitle => 'Anteprima miniatura';

  @override
  String get noThumbnailPreviewAvailable =>
      'Nessuna anteprima miniatura disponibile.';

  @override
  String authenticatedThumbnailRequest(Object serverUrl) {
    return 'Richiesta miniatura autenticata per $serverUrl';
  }

  @override
  String get metadataTitle => 'Metadati';

  @override
  String get fileNameLabel => 'Nome file';

  @override
  String get mimeTypeLabel => 'Tipo MIME';

  @override
  String get createdLabel => 'Creato';

  @override
  String get addedLabel => 'Aggiunto';

  @override
  String get pagesLabel => 'Pagine';

  @override
  String get archiveSerialNumberLabel => 'Numero di serie archivio';

  @override
  String get correspondentLabel => 'Corrispondente';

  @override
  String get documentTypeLabel => 'Tipo di documento';

  @override
  String get tagsLabel => 'Tag';

  @override
  String get contentPreviewTitle => 'Anteprima contenuto';

  @override
  String get metadataUpdated => 'Metadati aggiornati.';

  @override
  String get editMetadataTitle => 'Modifica metadati';

  @override
  String get editableFieldsTitle => 'Campi modificabili';

  @override
  String get titleLabel => 'Titolo';

  @override
  String get createdDateLabel => 'Data di creazione';

  @override
  String get createdDateHint => 'AAAA-MM-GG';

  @override
  String get newCorrespondentAction => 'Nuovo corrispondente';

  @override
  String get correspondentNameLabel => 'Nome del corrispondente';

  @override
  String get chooseCorrespondentHint => 'Scegli un corrispondente';

  @override
  String get noCorrespondentOption => 'Nessun corrispondente';

  @override
  String get couldNotLoadCorrespondents =>
      'Impossibile caricare i corrispondenti.';

  @override
  String get selectCorrespondentDialogTitle => 'Seleziona corrispondente';

  @override
  String get searchCorrespondentsHint => 'Cerca corrispondenti';

  @override
  String get noCorrespondentsMatchSearch =>
      'Nessun corrispondente corrisponde alla ricerca corrente.';

  @override
  String get newDocumentTypeAction => 'Nuovo tipo di documento';

  @override
  String get documentTypeNameLabel => 'Nome del tipo di documento';

  @override
  String get chooseDocumentTypeHint => 'Scegli un tipo di documento';

  @override
  String get noDocumentTypeOption => 'Nessun tipo di documento';

  @override
  String get couldNotLoadDocumentTypes =>
      'Impossibile caricare i tipi di documento.';

  @override
  String get selectDocumentTypeDialogTitle => 'Seleziona tipo di documento';

  @override
  String get searchDocumentTypesHint => 'Cerca tipi di documento';

  @override
  String get noDocumentTypesMatchSearch =>
      'Nessun tipo di documento corrisponde alla ricerca corrente.';

  @override
  String get newTagAction => 'Nuovo tag';

  @override
  String get tagNameLabel => 'Nome del tag';

  @override
  String get noTagsSelected => 'Nessun tag selezionato.';

  @override
  String get editTagsAction => 'Modifica tag';

  @override
  String get selectTagsDialogTitle => 'Seleziona tag';

  @override
  String get searchTagsHint => 'Cerca tag';

  @override
  String get selectedTagsSectionTitle => 'Tag selezionati';

  @override
  String get availableTagsSectionTitle => 'Tutti i tag';

  @override
  String get noTagsMatchSearch =>
      'Nessun tag corrisponde alla ricerca corrente.';

  @override
  String createTagConfirmationMessage(Object name) {
    return 'Creare \"$name\" e aggiungerlo a questo documento?';
  }

  @override
  String get enterNameValidation => 'Inserisci un nome.';

  @override
  String get invalidDateValidation => 'Usa una data valida come 2026-03-20.';

  @override
  String get correspondentCreated => 'Corrispondente creato.';

  @override
  String get correspondentRenamed => 'Corrispondente rinominato.';

  @override
  String get correspondentDeleted => 'Corrispondente eliminato.';

  @override
  String get documentDeleted => 'Documento eliminato.';

  @override
  String get documentTypeCreated => 'Tipo di documento creato.';

  @override
  String get documentTypeRenamed => 'Tipo di documento rinominato.';

  @override
  String get documentTypeDeleted => 'Tipo di documento eliminato.';

  @override
  String get tagCreated => 'Tag creato.';

  @override
  String get tagRenamed => 'Tag rinominato.';

  @override
  String get tagDeleted => 'Tag eliminato.';

  @override
  String get couldNotLoadDocumentDetails =>
      'Impossibile caricare i dettagli del documento.';

  @override
  String documentSubtitleUploaded(Object timestamp) {
    return 'Caricato $timestamp';
  }

  @override
  String documentSubtitleDated(Object timestamp) {
    return 'Datato $timestamp';
  }

  @override
  String documentPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pagine',
      one: '1 pagina',
    );
    return '$_temp0';
  }

  @override
  String documentAsn(int value) {
    return 'ASN $value';
  }

  @override
  String documentFallback(int id) {
    return 'Documento #$id';
  }
}
