// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Paperless-ngx';

  @override
  String get navigationHome => 'Inicio';

  @override
  String get navigationDocuments => 'Documentos';

  @override
  String get serverUrlLabel => 'URL del servidor';

  @override
  String get serverUrlHint => 'https://paperless.example.com';

  @override
  String get usernameLabel => 'Nombre de usuario';

  @override
  String get usernameHint => 'john.doe';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get passwordHint => 'Introduce tu contraseña';

  @override
  String get cancelAction => 'Cancelar';

  @override
  String get clearAction => 'Limpiar';

  @override
  String get applyAction => 'Aplicar';

  @override
  String get retryAction => 'Reintentar';

  @override
  String get saveAction => 'Guardar';

  @override
  String get savingAction => 'Guardando...';

  @override
  String get createAction => 'Crear';

  @override
  String get addingAction => 'Añadiendo...';

  @override
  String get loadingStatus => 'Cargando...';

  @override
  String get couldNotLoadStatus => 'No se pudo cargar';

  @override
  String get loginConnectTitle => 'Conéctate a tu servidor';

  @override
  String get loginConnectDescription =>
      'Usa la URL de tu instancia de paperless-ngx y las credenciales de tu cuenta para acceder a tus documentos.';

  @override
  String get loginButton => 'Iniciar sesión';

  @override
  String connectedAs(Object displayName) {
    return 'Conectado como $displayName';
  }

  @override
  String get loginValidationServerUrlRequired =>
      'Introduce la URL de tu servidor paperless-ngx.';

  @override
  String get loginValidationFullUrl =>
      'Usa una URL completa como https://paperless.example.com.';

  @override
  String get loginValidationUsernameRequired =>
      'Introduce tu nombre de usuario.';

  @override
  String get loginValidationPasswordRequired => 'Introduce tu contraseña.';

  @override
  String get loginSuccess => 'Conexión realizada correctamente.';

  @override
  String get loginFailedGeneric =>
      'Error al iniciar sesión. Inténtalo de nuevo.';

  @override
  String get authUnexpectedResponse =>
      'El servidor devolvió una respuesta inesperada.';

  @override
  String get authWrongPageInsteadOfApi =>
      'La solicitud llegó a la página incorrecta de paperless en lugar de a la API. Revisa la URL base, especialmente si el servidor está alojado bajo una subruta.';

  @override
  String get authAuthenticationFailed =>
      'Autenticación fallida. Revisa la URL, el nombre de usuario y la contraseña.';

  @override
  String get authServerRejectedLogin =>
      'El servidor rechazó la solicitud de inicio de sesión. Revisa la URL base, especialmente si paperless-ngx está alojado bajo una subruta.';

  @override
  String get authUnableToReachServer =>
      'No se puede acceder al servidor de paperless-ngx.';

  @override
  String get authInvalidServerUrl =>
      'Introduce una URL de servidor válida que incluya http:// o https://.';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsConnectionSection => 'Conexión';

  @override
  String get settingsAppearanceBehaviorSection => 'Apariencia y comportamiento';

  @override
  String get settingsTodosSection => 'Todos';

  @override
  String get settingsServerUrlSubtitle =>
      'Punto de acceso de paperless-ngx usado para iniciar sesión, sincronizar y descargar.';

  @override
  String get settingsUsernameSubtitle =>
      'Cuenta utilizada para autenticarse en el servidor.';

  @override
  String get settingsPasswordSubtitle =>
      'Se guarda localmente y se vuelve a verificar al guardar.';

  @override
  String get saveSettingsAction => 'Guardar ajustes';

  @override
  String get settingsSaveSuccess => 'Ajustes guardados y conexión verificada.';

  @override
  String get settingsSaveFailedGeneric =>
      'No se pudieron guardar los ajustes. Inténtalo de nuevo.';

  @override
  String get appLanguageTitle => 'Idioma de la aplicación';

  @override
  String get appLanguageSubtitle =>
      'Elige si la aplicación sigue el idioma del sistema o usa siempre una traducción concreta.';

  @override
  String get appLanguageSystem => 'Predeterminado del sistema';

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
      'Elige si la aplicación usa la paleta clara u oscura.';

  @override
  String get themeModeLight => 'Claro';

  @override
  String get themeModeDark => 'Oscuro';

  @override
  String get cachePreviewsTitle =>
      'Guardar miniaturas y vistas previas en caché';

  @override
  String get cachePreviewsSubtitle =>
      'Mantiene la preferencia para una navegación más rápida a medida que crece la caché local.';

  @override
  String get todoTagsTitle => 'Etiquetas TODO';

  @override
  String get todoTagsSubtitle =>
      'Selecciona qué etiquetas del servidor alimentan la pestaña Todos.';

  @override
  String get selectTodoTagsAction => 'Seleccionar etiquetas TODO';

  @override
  String get couldNotLoadAvailableTags =>
      'No se pudieron cargar las etiquetas disponibles.';

  @override
  String get retryTagLoadingAction => 'Reintentar carga de etiquetas';

  @override
  String get loadingAvailableTags => 'Cargando etiquetas disponibles...';

  @override
  String get selectTodoTagsDialogTitle => 'Seleccionar etiquetas TODO';

  @override
  String get noTagsAvailableOnServer =>
      'No hay etiquetas disponibles en el servidor.';

  @override
  String get homeRefreshTooltip => 'Actualizar inicio';

  @override
  String get logoutTooltip => 'Cerrar sesión';

  @override
  String get recentUploadsTab => 'Cargas recientes';

  @override
  String get todosTab => 'Todos';

  @override
  String get scanLaterAction => 'Escanear más tarde';

  @override
  String get scanDocumentAction => 'Escanear documento';

  @override
  String get scanDocumentTitle => 'Escanear documento';

  @override
  String get scanDocumentDescription =>
      'Captura una o varias páginas, revísalas y sube el PDF resultante a paperless-ngx.';

  @override
  String get scanDocumentEmptyTitle => 'Iniciar un nuevo escaneo';

  @override
  String get scanDocumentEmptyDescription =>
      'Usa la cámara del dispositivo para capturar un documento en papel. Todas las páginas escaneadas se combinan en un único PDF antes de subirlo.';

  @override
  String get scanDocumentTitleFieldLabel => 'Título del documento';

  @override
  String get scanDocumentTitleFieldHint => 'Título opcional para usar';

  @override
  String scanDocumentPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas escaneadas',
      one: '1 página escaneada',
    );
    return '$_temp0';
  }

  @override
  String get scanDocumentAddPagesAction => 'Escanear más páginas';

  @override
  String get scanDocumentReplacePagesAction => 'Escanear de nuevo';

  @override
  String get scanDocumentUploadAction => 'Subir escaneo';

  @override
  String get scanDocumentUploadingAction => 'Subiendo...';

  @override
  String get scanDocumentQueued => 'Escaneo en cola para su procesamiento.';

  @override
  String get scanDocumentScanFailed =>
      'No se pudo iniciar el escáner en este dispositivo.';

  @override
  String get scanDocumentUploadFailed => 'No se pudo subir el escaneo.';

  @override
  String get removeScannedPageTooltip => 'Quitar página escaneada';

  @override
  String scannedPageLabel(int page) {
    return 'Página $page';
  }

  @override
  String get homeUpdated => 'Inicio actualizado.';

  @override
  String get homeRefreshFailed => 'La actualización del inicio ha fallado.';

  @override
  String get noUploadsYetTitle => 'Todavía no hay cargas';

  @override
  String get noUploadsYetDescription =>
      'Los documentos recientes aparecerán aquí cuando tu servidor haya procesado las cargas.';

  @override
  String get couldNotLoadRecentUploadsTitle =>
      'No se pudieron cargar las cargas recientes';

  @override
  String get couldNotLoadRecentUploadsDescription =>
      'La página de inicio pudo llegar a tu servidor, pero la carga de documentos falló. Desliza para actualizar más tarde.';

  @override
  String get nothingToReviewTitle => 'Nada que revisar';

  @override
  String get nothingToReviewDescription =>
      'Los documentos con tus etiquetas TODO configuradas aparecerán aquí cuando necesiten atención manual.';

  @override
  String get verificationQueueTitle => 'Cola de verificación';

  @override
  String get verificationQueueDescription =>
      'Los documentos que coinciden con tus etiquetas TODO configuradas se muestran aquí para revisión manual. Elige una o más etiquetas TODO en Ajustes para que los documentos puedan aparecer en la cola de revisión.';

  @override
  String get openTodoTagSettingsAction => 'Abrir ajustes de etiquetas TODO';

  @override
  String get couldNotLoadReviewQueueTitle =>
      'No se pudo cargar la cola de revisión';

  @override
  String get couldNotLoadReviewQueueDescription =>
      'La aplicación no puede cargar ahora mismo los documentos que coinciden con tus etiquetas TODO configuradas.';

  @override
  String get drawerRecentlyOpened => 'Abiertos recientemente';

  @override
  String get drawerSettings => 'Ajustes';

  @override
  String get drawerHelpFeedback => 'Ayuda y comentarios';

  @override
  String get drawerStatisticsTitle => 'Estadísticas';

  @override
  String get drawerDocuments => 'Documentos';

  @override
  String get drawerCorrespondents => 'Corresponsales';

  @override
  String get drawerTags => 'Etiquetas';

  @override
  String get drawerDocumentTypes => 'Tipos de documento';

  @override
  String get drawerStatisticsUnavailable =>
      'Las estadísticas no están disponibles ahora mismo.';

  @override
  String refreshFailedLabel(Object timestamp) {
    return 'Actualización fallida $timestamp';
  }

  @override
  String get refreshingLabel => 'Actualizando...';

  @override
  String get waitingForFirstSyncLabel => 'Esperando la primera sincronización';

  @override
  String refreshingLastUpdatedLabel(Object timestamp) {
    return 'Actualizando... última actualización $timestamp';
  }

  @override
  String get updatedJustNowLabel => 'Actualizado ahora mismo';

  @override
  String updatedMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '1 min',
    );
    return 'Actualizado hace $_temp0';
  }

  @override
  String updatedAtLabel(Object timestamp) {
    return 'Actualizado $timestamp';
  }

  @override
  String todayAtLabel(Object time) {
    return 'hoy a las $time';
  }

  @override
  String yesterdayAtLabel(Object time) {
    return 'ayer a las $time';
  }

  @override
  String get documentsTitle => 'Documentos';

  @override
  String get refreshDocumentsTooltip => 'Actualizar documentos';

  @override
  String get searchByTitleHint => 'Buscar por título';

  @override
  String get clearSearchTooltip => 'Limpiar búsqueda';

  @override
  String get filtersTooltip => 'Filtros';

  @override
  String connectedToServer(Object serverUrl) {
    return 'Conectado a $serverUrl';
  }

  @override
  String get documentsUpdated => 'Documentos actualizados.';

  @override
  String get documentRefreshFailed =>
      'La actualización de documentos ha fallado.';

  @override
  String get filtersTitle => 'Filtros';

  @override
  String get resetAction => 'Restablecer';

  @override
  String get sortByLabel => 'Ordenar por';

  @override
  String get filterTagLabel => 'Etiqueta';

  @override
  String get filterCorrespondentLabel => 'Corresponsal';

  @override
  String get filterDocumentTypeLabel => 'Tipo de documento';

  @override
  String get anyOption => 'Cualquiera';

  @override
  String get applyFiltersAction => 'Aplicar filtros';

  @override
  String get sortCreatedNewest => 'Fecha de creación (más recientes primero)';

  @override
  String get sortCreatedOldest => 'Fecha de creación (más antiguos primero)';

  @override
  String get sortAddedNewest =>
      'Fecha de incorporación (más recientes primero)';

  @override
  String get sortAddedOldest => 'Fecha de incorporación (más antiguos primero)';

  @override
  String get sortTitleAz => 'Título (A-Z)';

  @override
  String get sortTitleZa => 'Título (Z-A)';

  @override
  String documentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documentos',
      one: '1 documento',
    );
    return '$_temp0';
  }

  @override
  String get noDocumentsMatchSearch =>
      'Ningún documento coincide con la búsqueda actual.';

  @override
  String get detailsAction => 'Detalles';

  @override
  String get openAction => 'Abrir';

  @override
  String get openingAction => 'Abriendo...';

  @override
  String get previousAction => 'Anterior';

  @override
  String pageIndicator(int page) {
    return 'Página $page';
  }

  @override
  String get nextAction => 'Siguiente';

  @override
  String get couldNotLoadDocuments => 'No se pudieron cargar los documentos.';

  @override
  String get recentlyOpenedTitle => 'Abiertos recientemente';

  @override
  String get clearHistoryTooltip => 'Borrar historial';

  @override
  String get recentlyOpenedEmpty =>
      'Los documentos que abras o inspecciones aparecerán aquí.';

  @override
  String get clearRecentlyOpenedTitle =>
      '¿Borrar documentos abiertos recientemente?';

  @override
  String get clearRecentlyOpenedDescription =>
      'Esto elimina el historial local de documentos que abriste desde el menú.';

  @override
  String get recentlyOpenedCleared =>
      'Se borraron los documentos abiertos recientemente.';

  @override
  String openedAtLabel(Object time) {
    return 'Abierto a las $time';
  }

  @override
  String get helpFeedbackTitle => 'Ayuda y comentarios';

  @override
  String get documentationTitle => 'Documentación';

  @override
  String get documentationDescription =>
      'Abre la documentación de paperless-ngx para configuración, uso y guía de la API.';

  @override
  String get reportIssueTitle => 'Informar de un problema';

  @override
  String get reportIssueDescription =>
      'Abre el rastreador de incidencias para informar de errores o solicitar mejoras.';

  @override
  String get copySupportSummaryTitle => 'Copiar resumen de soporte';

  @override
  String get copySupportSummaryDescription =>
      'Copia la versión de la aplicación y los detalles del servidor al portapapeles antes de enviar comentarios.';

  @override
  String get supportSummaryCopied => 'Resumen de soporte copiado.';

  @override
  String get unknownLabel => 'desconocido';

  @override
  String get documentDetailsTitle => 'Detalles del documento';

  @override
  String get editMetadataAction => 'Editar metadatos';

  @override
  String get openDocumentAction => 'Abrir documento';

  @override
  String get openOriginalAction => 'Abrir original';

  @override
  String get thumbnailPreviewTitle => 'Vista previa en miniatura';

  @override
  String get noThumbnailPreviewAvailable =>
      'No hay vista previa en miniatura disponible.';

  @override
  String authenticatedThumbnailRequest(Object serverUrl) {
    return 'Solicitud autenticada de miniatura para $serverUrl';
  }

  @override
  String get metadataTitle => 'Metadatos';

  @override
  String get fileNameLabel => 'Nombre de archivo';

  @override
  String get mimeTypeLabel => 'Tipo MIME';

  @override
  String get createdLabel => 'Creado';

  @override
  String get addedLabel => 'Añadido';

  @override
  String get pagesLabel => 'Páginas';

  @override
  String get archiveSerialNumberLabel => 'Número de serie de archivo';

  @override
  String get correspondentLabel => 'Corresponsal';

  @override
  String get documentTypeLabel => 'Tipo de documento';

  @override
  String get tagsLabel => 'Etiquetas';

  @override
  String get contentPreviewTitle => 'Vista previa del contenido';

  @override
  String get metadataUpdated => 'Metadatos actualizados.';

  @override
  String get editMetadataTitle => 'Editar metadatos';

  @override
  String get editableFieldsTitle => 'Campos editables';

  @override
  String get titleLabel => 'Título';

  @override
  String get createdDateLabel => 'Fecha de creación';

  @override
  String get createdDateHint => 'AAAA-MM-DD';

  @override
  String get newCorrespondentAction => 'Nuevo corresponsal';

  @override
  String get correspondentNameLabel => 'Nombre del corresponsal';

  @override
  String get chooseCorrespondentHint => 'Elegir un corresponsal';

  @override
  String get noCorrespondentOption => 'Sin corresponsal';

  @override
  String get couldNotLoadCorrespondents =>
      'No se pudieron cargar los corresponsales.';

  @override
  String get newDocumentTypeAction => 'Nuevo tipo de documento';

  @override
  String get documentTypeNameLabel => 'Nombre del tipo de documento';

  @override
  String get chooseDocumentTypeHint => 'Elegir un tipo de documento';

  @override
  String get noDocumentTypeOption => 'Sin tipo de documento';

  @override
  String get couldNotLoadDocumentTypes =>
      'No se pudieron cargar los tipos de documento.';

  @override
  String get newTagAction => 'Nueva etiqueta';

  @override
  String get tagNameLabel => 'Nombre de la etiqueta';

  @override
  String get noTagsSelected => 'No hay etiquetas seleccionadas.';

  @override
  String get noTodoTagsSelectedYet =>
      'Todavía no se han seleccionado etiquetas TODO.';

  @override
  String get noTodoTagsSelectedDescription =>
      'Usa Seleccionar etiquetas TODO abajo para elegir qué documentos aparecen en la pestaña Todos.';

  @override
  String get editTagsAction => 'Editar etiquetas';

  @override
  String get selectTagsDialogTitle => 'Seleccionar etiquetas';

  @override
  String get enterNameValidation => 'Introduce un nombre.';

  @override
  String get invalidDateValidation => 'Usa una fecha válida como 2026-03-20.';

  @override
  String get correspondentCreated => 'Corresponsal creado.';

  @override
  String get documentTypeCreated => 'Tipo de documento creado.';

  @override
  String get tagCreated => 'Etiqueta creada.';

  @override
  String get couldNotLoadDocumentDetails =>
      'No se pudieron cargar los detalles del documento.';

  @override
  String documentSubtitleUploaded(Object timestamp) {
    return 'Subido $timestamp';
  }

  @override
  String documentSubtitleDated(Object timestamp) {
    return 'Con fecha $timestamp';
  }

  @override
  String documentPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count páginas',
      one: '1 página',
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
