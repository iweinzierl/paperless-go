// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Paperless Go';

  @override
  String get navigationHome => 'Accueil';

  @override
  String get navigationDocuments => 'Documents';

  @override
  String get navigationRecent => 'Récents';

  @override
  String get navigationInbox => 'Boîte de réception';

  @override
  String get navigationReview => 'Vérifier';

  @override
  String get serverUrlLabel => 'URL du serveur';

  @override
  String get serverUrlHint => 'https://paperless.example.com';

  @override
  String get usernameLabel => 'Nom d\'utilisateur';

  @override
  String get usernameHint => 'john.doe';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get passwordHint => 'Saisissez votre mot de passe';

  @override
  String get cancelAction => 'Annuler';

  @override
  String get clearAction => 'Effacer';

  @override
  String get applyAction => 'Appliquer';

  @override
  String get retryAction => 'Réessayer';

  @override
  String get deleteAction => 'Supprimer';

  @override
  String get renameAction => 'Renommer';

  @override
  String get saveAction => 'Enregistrer';

  @override
  String get savingAction => 'Enregistrement...';

  @override
  String get createAction => 'Créer';

  @override
  String get addingAction => 'Ajout...';

  @override
  String get loadingStatus => 'Chargement...';

  @override
  String get couldNotLoadStatus => 'Impossible de charger';

  @override
  String get loginConnectTitle => 'Connectez-vous à votre serveur';

  @override
  String get loginConnectDescription =>
      'Utilisez l\'URL de votre instance paperless-ngx et vos identifiants pour accéder à vos documents.';

  @override
  String get loginButton => 'Connexion';

  @override
  String connectedAs(Object displayName) {
    return 'Connecté en tant que $displayName';
  }

  @override
  String get loginValidationServerUrlRequired =>
      'Saisissez l\'URL de votre serveur paperless-ngx.';

  @override
  String get loginValidationFullUrl =>
      'Utilisez une URL complète comme https://paperless.example.com.';

  @override
  String get loginValidationUsernameRequired =>
      'Saisissez votre nom d\'utilisateur.';

  @override
  String get loginValidationPasswordRequired => 'Saisissez votre mot de passe.';

  @override
  String get loginSuccess => 'Connexion réussie.';

  @override
  String get loginFailedGeneric => 'La connexion a échoué. Veuillez réessayer.';

  @override
  String get authUnexpectedResponse =>
      'Le serveur a renvoyé une réponse inattendue.';

  @override
  String get authWrongPageInsteadOfApi =>
      'La requête a atteint la mauvaise page paperless au lieu de l\'API. Vérifiez l\'URL de base, surtout si le serveur est hébergé sous un sous-chemin.';

  @override
  String get authAuthenticationFailed =>
      'Échec de l\'authentification. Vérifiez l\'URL, le nom d\'utilisateur et le mot de passe.';

  @override
  String get authServerRejectedLogin =>
      'Le serveur a refusé la demande de connexion. Vérifiez l\'URL de base, surtout si paperless-ngx est hébergé sous un sous-chemin.';

  @override
  String get authUnableToReachServer =>
      'Impossible d\'atteindre le serveur paperless-ngx.';

  @override
  String get authInvalidServerUrl =>
      'Saisissez une URL de serveur valide incluant http:// ou https://.';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsConnectionSection => 'Connexion';

  @override
  String get settingsAppearanceBehaviorSection => 'Apparence et comportement';

  @override
  String get settingsSecuritySection => 'Sécurité';

  @override
  String get settingsServerUrlSubtitle =>
      'Point d\'accès paperless-ngx utilisé pour la connexion, la synchronisation et les téléchargements.';

  @override
  String get settingsUsernameSubtitle =>
      'Compte utilisé pour s\'authentifier auprès du serveur.';

  @override
  String get settingsPasswordSubtitle =>
      'Conservé localement et revérifié lorsque vous enregistrez.';

  @override
  String get saveSettingsAction => 'Enregistrer les paramètres';

  @override
  String get settingsSaveSuccess =>
      'Paramètres enregistrés et connexion vérifiée.';

  @override
  String get settingsSaveFailedGeneric =>
      'Impossible d\'enregistrer les paramètres. Veuillez réessayer.';

  @override
  String get appLanguageTitle => 'Langue de l\'application';

  @override
  String get appLanguageSubtitle =>
      'Choisissez si l\'application suit la langue du système ou utilise toujours une traduction précise.';

  @override
  String get appLanguageSystem => 'Langue du système';

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
  String get themeModeTitle => 'Thème';

  @override
  String get themeModeSubtitle =>
      'Choisissez si l\'application utilise la palette claire ou sombre.';

  @override
  String get themeModeLight => 'Clair';

  @override
  String get themeModeDark => 'Sombre';

  @override
  String get cachePreviewsTitle => 'Mettre en cache les miniatures et aperçus';

  @override
  String get cachePreviewsSubtitle =>
      'Conserve la préférence pour accélérer la navigation à mesure que le cache local s\'étend.';

  @override
  String get biometricLockTitle => 'Utiliser Face ID ou l\'empreinte';

  @override
  String get biometricLockSubtitle =>
      'Demande une vérification biométrique ou des identifiants de l\'appareil au retour dans l\'application après un passage en arrière-plan.';

  @override
  String get appLockTimeoutTitle => 'Verrouiller à la réouverture après';

  @override
  String get appLockTimeoutSubtitle =>
      'Choisissez combien de temps l\'application peut rester en arrière-plan avant de redemander un déverrouillage.';

  @override
  String get appLockTimeoutImmediate => 'Immédiatement';

  @override
  String get appLockTimeout30Seconds => '30 secondes';

  @override
  String get appLockTimeout1Minute => '1 minute';

  @override
  String get appLockTimeout5Minutes => '5 minutes';

  @override
  String get biometricLockUnavailable =>
      'L\'authentification biométrique n\'est pas disponible sur cet appareil pour le moment.';

  @override
  String get biometricLockEnableFailed =>
      'La vérification biométrique n\'a pas été confirmée, le verrouillage de l\'application reste donc désactivé.';

  @override
  String get biometricEnableReason =>
      'Confirmez votre identité pour activer le verrouillage de Paperless Go.';

  @override
  String get biometricPromptTitle => 'Protéger Paperless Go ?';

  @override
  String get biometricPromptMessage =>
      'Activez maintenant Face ID ou l\'empreinte pour protéger vos documents lorsque vous revenez dans l\'application.';

  @override
  String get biometricPromptNotNowAction => 'Pas maintenant';

  @override
  String get biometricPromptEnableAction => 'Activer maintenant';

  @override
  String get biometricUnlockTitle => 'Déverrouiller Paperless Go';

  @override
  String get biometricUnlockSubtitle =>
      'Utilisez Face ID, Touch ID ou les identifiants de votre appareil pour continuer.';

  @override
  String get biometricUnlockAction => 'Déverrouiller';

  @override
  String get biometricUnlockingStatus => 'Déverrouillage...';

  @override
  String get biometricUnlockReason =>
      'Confirmez votre identité pour déverrouiller Paperless Go.';

  @override
  String get biometricUnlockFailed =>
      'L\'authentification a été annulée ou a échoué. Réessayez pour continuer.';

  @override
  String get signOutAction => 'Se déconnecter';

  @override
  String get retryTagLoadingAction => 'Recharger les tags';

  @override
  String get noTagsAvailableOnServer =>
      'Aucun tag n\'est disponible sur le serveur.';

  @override
  String get homeRefreshTooltip => 'Actualiser l\'accueil';

  @override
  String get logoutTooltip => 'Se déconnecter';

  @override
  String get recentUploadsTab => 'Imports récents';

  @override
  String get todosTab => 'Todos';

  @override
  String get scanLaterAction => 'Numériser plus tard';

  @override
  String get scanDocumentAction => 'Numériser un document';

  @override
  String get scanDocumentTitle => 'Numériser un document';

  @override
  String get scanDocumentDescription =>
      'Capturez une ou plusieurs pages, vérifiez-les, puis importez le PDF obtenu dans paperless-ngx.';

  @override
  String get scanDocumentEmptyTitle => 'Lancer un nouveau scan';

  @override
  String get scanDocumentEmptyDescription =>
      'Utilisez l\'appareil photo de votre appareil pour capturer un document papier. Toutes les pages numérisées sont regroupées dans un seul PDF avant l\'import.';

  @override
  String get scanDocumentTitleFieldLabel => 'Titre du document';

  @override
  String get scanDocumentTitleFieldHint => 'Titre facultatif à utiliser';

  @override
  String scanDocumentPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages numérisées',
      one: '1 page numérisée',
    );
    return '$_temp0';
  }

  @override
  String get scanDocumentAddPagesAction => 'Numériser d\'autres pages';

  @override
  String get scanDocumentReplacePagesAction => 'Recommencer le scan';

  @override
  String get scanDocumentUploadAction => 'Importer le scan';

  @override
  String get scanDocumentUploadingAction => 'Import en cours...';

  @override
  String get scanDocumentQueued =>
      'Le scan a été mis en file d\'attente pour traitement.';

  @override
  String get scanDocumentScanFailed =>
      'Le scanner n\'a pas pu être lancé sur cet appareil.';

  @override
  String get scanDocumentUploadFailed => 'Le scan n\'a pas pu être importé.';

  @override
  String get removeScannedPageTooltip => 'Supprimer la page numérisée';

  @override
  String scannedPageLabel(int page) {
    return 'Page $page';
  }

  @override
  String get homeUpdated => 'Accueil mis à jour.';

  @override
  String get homeRefreshFailed => 'L\'actualisation de l\'accueil a échoué.';

  @override
  String get noUploadsYetTitle => 'Aucun import pour le moment';

  @override
  String get noUploadsYetDescription =>
      'Les documents récents apparaîtront ici une fois les imports traités par votre serveur.';

  @override
  String get couldNotLoadRecentUploadsTitle =>
      'Impossible de charger les imports récents';

  @override
  String get couldNotLoadRecentUploadsDescription =>
      'La page d\'accueil a atteint votre serveur, mais le chargement des documents a échoué. Tirez pour réessayer plus tard.';

  @override
  String get nothingToReviewTitle => 'Rien à vérifier';

  @override
  String get nothingToReviewDescription =>
      'Les documents actuellement dans votre boîte de réception apparaissent ici pour une vérification manuelle.';

  @override
  String get verificationQueueTitle => 'File de vérification';

  @override
  String get verificationQueueDescription =>
      'Les documents actuellement dans votre boîte de réception sont listés ici pour une révision manuelle.';

  @override
  String get couldNotLoadReviewQueueTitle =>
      'Impossible de charger la file de vérification';

  @override
  String get couldNotLoadReviewQueueDescription =>
      'L\'application ne peut pas charger pour le moment les documents de la boîte de réception à vérifier.';

  @override
  String get drawerRecentlyOpened => 'Récemment ouverts';

  @override
  String get drawerSettings => 'Paramètres';

  @override
  String get drawerHelpFeedback => 'Aide et commentaires';

  @override
  String get drawerStatisticsTitle => 'Statistiques';

  @override
  String get drawerDocuments => 'Documents';

  @override
  String get drawerCorrespondents => 'Correspondants';

  @override
  String get drawerTags => 'Tags';

  @override
  String get drawerDocumentTypes => 'Types de document';

  @override
  String get drawerStatisticsUnavailable =>
      'Les statistiques ne sont pas disponibles pour le moment.';

  @override
  String get managementOptionsEmpty =>
      'Aucun élément disponible pour le moment. Utilisez l\'action de création pour en ajouter un.';

  @override
  String get managementSearchHint => 'Rechercher des types';

  @override
  String get noManagementOptionsMatchSearch =>
      'Aucune entrée ne correspond à la recherche actuelle.';

  @override
  String get renameCorrespondentAction => 'Renommer le correspondant';

  @override
  String get renameDocumentTypeAction => 'Renommer le type de document';

  @override
  String get renameTagAction => 'Renommer le tag';

  @override
  String get deleteCorrespondentAction => 'Supprimer le correspondant';

  @override
  String get deleteDocumentAction => 'Supprimer le document';

  @override
  String get deleteDocumentTypeAction => 'Supprimer le type de document';

  @override
  String get deleteTagAction => 'Supprimer le tag';

  @override
  String deleteCorrespondentConfirmationMessage(Object name) {
    return 'Supprimer \"$name\" ? Cette action est irreversible.';
  }

  @override
  String deleteDocumentConfirmationMessage(Object name) {
    return 'Supprimer \"$name\" ? Cette action est irreversible.';
  }

  @override
  String deleteDocumentTypeConfirmationMessage(Object name) {
    return 'Supprimer \"$name\" ? Cette action est irreversible.';
  }

  @override
  String deleteTagConfirmationMessage(Object name) {
    return 'Supprimer \"$name\" ? Cette action est irreversible.';
  }

  @override
  String refreshFailedLabel(Object timestamp) {
    return 'Actualisation échouée $timestamp';
  }

  @override
  String get refreshingLabel => 'Actualisation...';

  @override
  String get waitingForFirstSyncLabel =>
      'En attente de la première synchronisation';

  @override
  String refreshingLastUpdatedLabel(Object timestamp) {
    return 'Actualisation... dernière mise à jour $timestamp';
  }

  @override
  String get updatedJustNowLabel => 'Mis à jour à l\'instant';

  @override
  String updatedMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '1 min',
    );
    return 'Mis à jour il y a $_temp0';
  }

  @override
  String updatedAtLabel(Object timestamp) {
    return 'Mis à jour $timestamp';
  }

  @override
  String todayAtLabel(Object time) {
    return 'aujourd\'hui à $time';
  }

  @override
  String yesterdayAtLabel(Object time) {
    return 'hier à $time';
  }

  @override
  String get documentsTitle => 'Documents';

  @override
  String get refreshDocumentsTooltip => 'Actualiser les documents';

  @override
  String get searchByTitleHint => 'Rechercher par titre';

  @override
  String get clearSearchTooltip => 'Effacer la recherche';

  @override
  String get filtersTooltip => 'Filtres';

  @override
  String connectedToServer(Object serverUrl) {
    return 'Connecté à $serverUrl';
  }

  @override
  String get documentsUpdated => 'Documents mis à jour.';

  @override
  String get documentRefreshFailed =>
      'L\'actualisation des documents a échoué.';

  @override
  String get filtersTitle => 'Filtres';

  @override
  String get resetAction => 'Réinitialiser';

  @override
  String get sortByLabel => 'Trier par';

  @override
  String get filterTagLabel => 'Tag';

  @override
  String get filterCorrespondentLabel => 'Correspondant';

  @override
  String get filterDocumentTypeLabel => 'Type de document';

  @override
  String get anyOption => 'Tous';

  @override
  String get applyFiltersAction => 'Appliquer les filtres';

  @override
  String get sortCreatedNewest => 'Date de création (plus récent d\'abord)';

  @override
  String get sortCreatedOldest => 'Date de création (plus ancien d\'abord)';

  @override
  String get sortAddedNewest => 'Date d\'ajout (plus récent d\'abord)';

  @override
  String get sortAddedOldest => 'Date d\'ajout (plus ancien d\'abord)';

  @override
  String get sortTitleAz => 'Titre (A-Z)';

  @override
  String get sortTitleZa => 'Titre (Z-A)';

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
  String get noDocumentsMatchSearch =>
      'Aucun document ne correspond à la recherche actuelle.';

  @override
  String get detailsAction => 'Détails';

  @override
  String get openAction => 'Ouvrir';

  @override
  String get openingAction => 'Ouverture...';

  @override
  String get previousAction => 'Précédent';

  @override
  String pageIndicator(int page) {
    return 'Page $page';
  }

  @override
  String get nextAction => 'Suivant';

  @override
  String get couldNotLoadDocuments => 'Impossible de charger les documents.';

  @override
  String get recentlyOpenedTitle => 'Récemment ouverts';

  @override
  String get clearHistoryTooltip => 'Effacer l\'historique';

  @override
  String get recentlyOpenedEmpty =>
      'Les documents que vous ouvrez ou inspectez apparaîtront ici.';

  @override
  String get clearRecentlyOpenedTitle =>
      'Effacer les documents récemment ouverts ?';

  @override
  String get clearRecentlyOpenedDescription =>
      'Cela supprime l\'historique local des documents que vous avez ouverts depuis le menu.';

  @override
  String get recentlyOpenedCleared =>
      'Historique des documents récents effacé.';

  @override
  String openedAtLabel(Object time) {
    return 'Ouvert à $time';
  }

  @override
  String get helpFeedbackTitle => 'Aide et commentaires';

  @override
  String get documentationTitle => 'Documentation';

  @override
  String get documentationDescription =>
      'Ouvre la documentation paperless-ngx pour la configuration, l\'utilisation et l\'API.';

  @override
  String get reportIssueTitle => 'Signaler un problème';

  @override
  String get reportIssueDescription =>
      'Ouvre le suivi des tickets amont pour signaler des bugs ou demander des améliorations.';

  @override
  String get donateTitle => 'Faire un don';

  @override
  String get donateDescription =>
      'Choisissez un montant et continuez dans votre navigateur pour soutenir le développement.';

  @override
  String get donateDialogTitle => 'Soutenir le développement';

  @override
  String get donateAmountLabel => 'Montant';

  @override
  String get donateAmountHint => '5,00';

  @override
  String get donateContinueAction => 'Continuer vers le don';

  @override
  String get donateInvalidAmount => 'Saisissez un montant supérieur à 0.';

  @override
  String get copySupportSummaryTitle => 'Copier le résumé d\'assistance';

  @override
  String get copySupportSummaryDescription =>
      'Copie la version de l\'application et les détails du serveur dans le presse-papiers avant d\'envoyer un retour.';

  @override
  String get supportSummaryCopied => 'Résumé d\'assistance copié.';

  @override
  String get unknownLabel => 'inconnu';

  @override
  String get documentDetailsTitle => 'Détails du document';

  @override
  String get editMetadataAction => 'Modifier les métadonnées';

  @override
  String get openDocumentAction => 'Ouvrir le document';

  @override
  String get openOriginalAction => 'Ouvrir l\'original';

  @override
  String get thumbnailPreviewTitle => 'Aperçu miniature';

  @override
  String get noThumbnailPreviewAvailable =>
      'Aucun aperçu miniature disponible.';

  @override
  String authenticatedThumbnailRequest(Object serverUrl) {
    return 'Requête de miniature authentifiée pour $serverUrl';
  }

  @override
  String get metadataTitle => 'Métadonnées';

  @override
  String get fileNameLabel => 'Nom du fichier';

  @override
  String get mimeTypeLabel => 'Type MIME';

  @override
  String get createdLabel => 'Créé';

  @override
  String get addedLabel => 'Ajouté';

  @override
  String get pagesLabel => 'Pages';

  @override
  String get archiveSerialNumberLabel => 'Numéro de série d\'archive';

  @override
  String get correspondentLabel => 'Correspondant';

  @override
  String get documentTypeLabel => 'Type de document';

  @override
  String get tagsLabel => 'Tags';

  @override
  String get contentPreviewTitle => 'Aperçu du contenu';

  @override
  String get metadataUpdated => 'Métadonnées mises à jour.';

  @override
  String get editMetadataTitle => 'Modifier les métadonnées';

  @override
  String get editableFieldsTitle => 'Champs modifiables';

  @override
  String get titleLabel => 'Titre';

  @override
  String get createdDateLabel => 'Date de création';

  @override
  String get createdDateHint => 'AAAA-MM-JJ';

  @override
  String get newCorrespondentAction => 'Nouveau correspondant';

  @override
  String get correspondentNameLabel => 'Nom du correspondant';

  @override
  String get chooseCorrespondentHint => 'Choisir un correspondant';

  @override
  String get noCorrespondentOption => 'Aucun correspondant';

  @override
  String get couldNotLoadCorrespondents =>
      'Impossible de charger les correspondants.';

  @override
  String get selectCorrespondentDialogTitle => 'Sélectionner un correspondant';

  @override
  String get searchCorrespondentsHint => 'Rechercher des correspondants';

  @override
  String get noCorrespondentsMatchSearch =>
      'Aucun correspondant ne correspond à la recherche actuelle.';

  @override
  String get newDocumentTypeAction => 'Nouveau type de document';

  @override
  String get documentTypeNameLabel => 'Nom du type de document';

  @override
  String get chooseDocumentTypeHint => 'Choisir un type de document';

  @override
  String get noDocumentTypeOption => 'Aucun type de document';

  @override
  String get couldNotLoadDocumentTypes =>
      'Impossible de charger les types de document.';

  @override
  String get selectDocumentTypeDialogTitle =>
      'Sélectionner un type de document';

  @override
  String get searchDocumentTypesHint => 'Rechercher des types de document';

  @override
  String get noDocumentTypesMatchSearch =>
      'Aucun type de document ne correspond à la recherche actuelle.';

  @override
  String get newTagAction => 'Nouveau tag';

  @override
  String get tagNameLabel => 'Nom du tag';

  @override
  String get noTagsSelected => 'Aucun tag sélectionné.';

  @override
  String get editTagsAction => 'Modifier les tags';

  @override
  String get selectTagsDialogTitle => 'Sélectionner les tags';

  @override
  String get searchTagsHint => 'Rechercher des tags';

  @override
  String get selectedTagsSectionTitle => 'Tags sélectionnés';

  @override
  String get availableTagsSectionTitle => 'Tous les tags';

  @override
  String get noTagsMatchSearch =>
      'Aucun tag ne correspond à la recherche actuelle.';

  @override
  String createTagConfirmationMessage(Object name) {
    return 'Créer \"$name\" et l\'ajouter à ce document ?';
  }

  @override
  String get enterNameValidation => 'Saisissez un nom.';

  @override
  String get invalidDateValidation =>
      'Utilisez une date valide comme 2026-03-20.';

  @override
  String get correspondentCreated => 'Correspondant créé.';

  @override
  String get correspondentRenamed => 'Correspondant renommé.';

  @override
  String get correspondentDeleted => 'Correspondant supprimé.';

  @override
  String get documentDeleted => 'Document supprimé.';

  @override
  String get documentTypeCreated => 'Type de document créé.';

  @override
  String get documentTypeRenamed => 'Type de document renommé.';

  @override
  String get documentTypeDeleted => 'Type de document supprimé.';

  @override
  String get tagCreated => 'Tag créé.';

  @override
  String get tagRenamed => 'Tag renommé.';

  @override
  String get tagDeleted => 'Tag supprimé.';

  @override
  String get couldNotLoadDocumentDetails =>
      'Impossible de charger les détails du document.';

  @override
  String documentSubtitleUploaded(Object timestamp) {
    return 'Importé $timestamp';
  }

  @override
  String documentSubtitleDated(Object timestamp) {
    return 'Daté du $timestamp';
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
