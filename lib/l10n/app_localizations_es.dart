// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Affinity';

  @override
  String get itsAMatch => '¡ES UN MATCH!';

  @override
  String get matchUs => 'Vosotros';

  @override
  String get sendMessage => 'Enviar mensaje';

  @override
  String get keepExploring => 'Seguir explorando';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get signUp => 'Registrarse';

  @override
  String get signInAccounts => 'Inicia sesión con tus cuentas.';

  @override
  String get signInWithGoogle => 'Iniciar sesión con Google';

  @override
  String get signInWithApple => 'Iniciar sesión con Apple';

  @override
  String get logIn => 'Iniciar sesión';

  @override
  String get createAccount => 'Crear una cuenta';

  @override
  String get email => 'Correo electrónico';

  @override
  String get emailHint => 'Introduce tu correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get passwordHint => 'Introduce tu contraseña';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get haveNotAccount => '¿No tienes una cuenta?';

  @override
  String get name => 'Nombre';

  @override
  String get her => 'Nombre de ella';

  @override
  String get his => 'Nombre de él';

  @override
  String get dateOfBirth => 'Fecha de nacimiento';

  @override
  String get dateOfBirthFormat => 'DD-MM-AAAA';

  @override
  String get selectCity => 'Selecciona ciudad';

  @override
  String get description => 'Descripción';

  @override
  String get tellUsAboutYourself => 'Cuéntanos sobre vosotros';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get confirmPasswordHint => 'Vuelve a introducir tu contraseña';

  @override
  String get welcomeBack => '¡Bienvenido de vuelta!';

  @override
  String get welcomeBackDescription =>
      'Una vez verificado, la próxima vez que inicies sesión deberás introducir el código de verificación.';

  @override
  String get verify => 'Verificar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get errorEmailEmpty => 'Por favor ingresa un correo electrónico';

  @override
  String get errorEmailInvalid =>
      'Por favor ingresa un correo electrónico válido';

  @override
  String get errorPasswordEmpty => 'Por favor ingresa una contraseña';

  @override
  String get errorPasswordTooShort =>
      'La contraseña debe tener al menos 8 caracteres';

  @override
  String get weHaveSentYouACode => 'Te hemos enviado un código';

  @override
  String theCodeWasSentTo(String email) {
    return 'El código fue enviado a $email';
  }

  @override
  String resendCodeIn(String seconds) {
    return 'Reenviar código en ${seconds}s';
  }

  @override
  String get resendCode => 'Reenviar código';

  @override
  String get navCouples => 'Parejas';

  @override
  String get navCommunity => 'Comunidad';

  @override
  String get navInbox => 'Mensajes';

  @override
  String get navProfile => 'Perfil';

  @override
  String get youAreIn => '¡Ya estás dentro!';

  @override
  String get recoveryPasswordSuccess =>
      'Esperamos que disfrutes explorando y conectando con nuestra vibrante comunidad.';

  @override
  String get goToLogin => 'Ir al inicio de sesión';

  @override
  String get startConversation => 'Iniciar conversación';

  @override
  String get chatMessageQuickStarters => 'Mensaje rápido (para comenzar)';

  @override
  String get errorGoogleSignIn =>
      'Error al iniciar sesión con Google. Por favor, inténtalo de nuevo.';

  @override
  String get errorAppleSignIn =>
      'Error al iniciar sesión con Apple. Por favor, inténtalo de nuevo.';

  @override
  String get logOut => 'Cerrar sesión';

  @override
  String get logOutConfirm => '¿Estás seguro de que quieres cerrar sesión?';

  @override
  String get alreadyAMember => '¿Ya eres miembro?';

  @override
  String get height => 'Altura';

  @override
  String get herHeight => 'Altura de ella (opcional)';

  @override
  String get hisHeight => 'Altura de él (opcional)';

  @override
  String get interests => 'Intereses';

  @override
  String get heightUnit => 'Unidad';

  @override
  String get heightCm => 'cm';

  @override
  String get heightFt => 'ft/in';

  @override
  String get errorConfirmPassword => 'Las contraseñas no coinciden';

  @override
  String get errorSignUp =>
      'Error al registrarse. Por favor, inténtalo de nuevo.';

  @override
  String get errorSignIn =>
      'Error al iniciar sesión. Por favor, revisa tus credenciales.';

  @override
  String get errorEmailAlreadyInUse =>
      'Este correo ya está registrado. Iniciá sesión.';

  @override
  String get errorWeakPassword =>
      'La contraseña debe tener al menos 8 caracteres.';

  @override
  String get errorInvalidEmailFormat => 'El formato del correo no es válido.';

  @override
  String get errorUserNotFound => 'No existe una cuenta con ese correo.';

  @override
  String get errorWrongPassword => 'Contraseña incorrecta.';

  @override
  String get errorInvalidCredential => 'Correo o contraseña incorrectos.';

  @override
  String get errorTooManyAttempts =>
      'Demasiados intentos. Esperá unos minutos.';

  @override
  String get errorUserDisabled => 'Esta cuenta está deshabilitada.';

  @override
  String get errorNetworkRequest => 'Sin conexión a internet. Verificá tu red.';

  @override
  String get errorGoogleSignInConfig =>
      'Google Sign-In aún no está configurado para esta versión del APK. Revisar el SHA-1 en la consola.';

  @override
  String get errorGoogleSignInCancelled =>
      'Inicio de sesión con Google cancelado.';

  @override
  String get completeProfile => 'Completa tu perfil';

  @override
  String get saveProfile => 'Guardar';

  @override
  String get goToVerificationVideo => 'Video de Verificación';

  @override
  String get photos => 'Fotos';

  @override
  String get photoMinError => 'Agrega al menos 3 fotos';

  @override
  String get photosCoupleTogetherHint =>
      'Todas las fotos deben mostrar a la pareja junta';

  @override
  String get errorSaveProfile =>
      'No se pudo guardar el perfil. Inténtalo de nuevo.';

  @override
  String get errorAllFieldsRequired => 'Todos los campos son obligatorios';

  @override
  String get errorNameTooShort =>
      'Los nombres deben tener al menos 2 caracteres';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get manageTrips => 'Gestionar viajes';

  @override
  String get viewFavoriteCouples => 'Ver parejas favoritas o guardadas';

  @override
  String get accountSettings => 'Ajustes de la cuenta';

  @override
  String get security => 'Seguridad';

  @override
  String get help => 'Ayuda';

  @override
  String get preferences => 'Preferencias';

  @override
  String get support => 'Soporte';

  @override
  String get addYourTags => 'Agrega tus etiquetas';

  @override
  String get tagsDescription =>
      'Muestra lo que los define como pareja. Tus etiquetas ayudan a crear mejores coincidencias y conexiones más significativas.';

  @override
  String get dynamicsSelectWhatRepresentsYou =>
      'SELECCIONA LO QUE LOS REPRESENTA';

  @override
  String get dynamicsSelectWhatRepresentsYouSubtitle =>
      'Cuéntanos sobre sus dinámicas, preferencias e intereses.';

  @override
  String get dynamicsSelectWhatYouAreLookingFor =>
      'Selecciona lo que están buscando';

  @override
  String get dynamicsLookingForTitle => 'BUSCANDO';

  @override
  String get dynamicsLookingForSubtitle =>
      'Estas opciones describen lo que están buscando en la otra pareja.';

  @override
  String get dynamicsBlockTitle => 'DINÁMICAS';

  @override
  String get dynamicsIndividualIdentity => 'Identidad individual';

  @override
  String get dynamicsRole => 'Rol';

  @override
  String get dynamicsTypeOfInteraction => 'Tipo de interacción';

  @override
  String get dynamicsExperience => 'Experiencia';

  @override
  String get dynamicsInterestsLabel => 'Intereses';

  @override
  String get dynamicsHerLabel => 'Ella:';

  @override
  String get dynamicsHimLabel => 'Él:';

  @override
  String get dynamicsOpenToUnicornHer => 'Abierta a ser Unicornio (ella)';

  @override
  String get dynamicsOpenToBullHim => 'Abierto a ser Toro (él)';

  @override
  String get dynamicsLookingForUnicorn => 'Buscando Unicornio';

  @override
  String get dynamicsLookingForBull => 'Buscando Toro';

  @override
  String get dynamicsAboutUsOptional => 'Acerca de nosotros (opcional)';

  @override
  String get dynamicsAboutUsHint => 'Cuéntanos sobre ustedes';

  @override
  String get addTag => 'Agregar';

  @override
  String get updateInterestsNote =>
      'Puedes actualizar tus intereses en cualquier momento desde tu perfil.';

  @override
  String get addTagTitle => 'Agregar etiqueta';

  @override
  String get addTagHint => 'Escribe una etiqueta...';

  @override
  String get chatSuggestion1 => 'Hola ❤️ Solo queríamos saludarte';

  @override
  String get chatSuggestion2 =>
      '¡Nos encantó su perfil! 😍 Teníamos que escribir';

  @override
  String get chatSuggestion3 => '¿Qué planes tienen este fin de semana? 🎉';

  @override
  String get chatSuggestion4 => 'Su vibe es todo ✨ teníamos que conectar';

  @override
  String get chatSuggestion5 => '¿Qué tal una cita doble? ☕🍷';

  @override
  String get chatSuggestion6 => 'Buscábamos una pareja como ustedes 🙌';

  @override
  String blockedCouple(String him, String her) {
    return 'Bloqueaste a $him y $her';
  }

  @override
  String couldNotBlock(String error) {
    return 'No se pudo bloquear: $error';
  }

  @override
  String get reportSubmittedThanks =>
      'Gracias — nuestro equipo revisará el reporte.';

  @override
  String requestSentTo(String name) {
    return 'Solicitud enviada a $name';
  }

  @override
  String get retry => 'Reintentar';

  @override
  String get feedEmptyTitle => 'Por ahora no hay parejas que coincidan';

  @override
  String get feedEmptyBody =>
      'Probá ampliar tus filtros o volvé más tarde — todos los días se suman parejas nuevas.';

  @override
  String get filtersReset => 'Restablecer';

  @override
  String get filtersTitle => 'Filtros';

  @override
  String get filtersDistanceMin5km => 'Mín 5 km';

  @override
  String filtersAgeMin(int n) {
    return 'Mín $n';
  }

  @override
  String filtersAgeMax(int n) {
    return 'Máx $n';
  }

  @override
  String get selectResortOrCruise => 'Selecciona un resort o crucero';

  @override
  String get anyDestination => 'Cualquier destino';

  @override
  String get messageRequestTitle => 'Solicitud de mensaje';

  @override
  String get messageRequestDismiss => 'Descartar';

  @override
  String get senderProfileUnavailable => 'Perfil del remitente no disponible';

  @override
  String get reportCouple => 'Reportar pareja';

  @override
  String get couldNotLoadCoupleProfile =>
      'No se pudo cargar el perfil de la pareja';

  @override
  String get imagePickerGallery => 'Galería';

  @override
  String get imagePickerCamera => 'Cámara';

  @override
  String get photoMain => 'Principal';

  @override
  String get notSignedIn => 'Sesión no iniciada';

  @override
  String get securityTitle => 'Seguridad';

  @override
  String couldNotLoadError(String error) {
    return 'No se pudo cargar: $error';
  }

  @override
  String unblockFailed(String error) {
    return 'Desbloqueo fallido: $error';
  }

  @override
  String get unblockAction => 'Desbloquear';

  @override
  String get accountSettingsTitle => 'Ajustes de cuenta';

  @override
  String get changePassword => 'Cambiar contraseña';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get reportSubmitted => 'Reporte enviado';

  @override
  String get reportCoupleTitle => 'Reportar pareja';

  @override
  String get blockThisCoupleToo => 'Bloquear también a esta pareja';

  @override
  String get manageTripsTitle => 'Gestionar viajes';

  @override
  String get addTrip => 'Añadir viaje';

  @override
  String get exploreMoreTrips => 'Explorar más viajes';

  @override
  String get noTripsYet =>
      'Todavía no hay viajes.\nToca \"Añadir viaje\" para obtener tu primera coincidencia.';

  @override
  String get couldNotOpenPartnerSite =>
      'No se pudo abrir el sitio del partner de viajes.';

  @override
  String get deleteTripTitle => '¿Eliminar viaje?';

  @override
  String deleteTripBody(String destination) {
    return 'Cancela las notificaciones a las parejas con coincidencia en \"$destination\".';
  }

  @override
  String get delete => 'Eliminar';

  @override
  String get noBlockedCouples => 'No has bloqueado a nadie.';

  @override
  String blockedOn(String date) {
    return 'Bloqueado el $date';
  }

  @override
  String get blockOriginViaReport => '(vía reporte)';

  @override
  String get blockOriginAuto => '(automático)';

  @override
  String get changeEmail => 'Cambiar correo';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get languageSettingTitle => 'Idioma';

  @override
  String get languageSettingSubtitleSystem => 'Usar idioma del dispositivo';

  @override
  String get languageOptionSystem => 'Predeterminado del sistema';

  @override
  String get languageOptionEnglish => 'English';

  @override
  String get languageOptionSpanish => 'Español';

  @override
  String get chatSearchHint => 'Buscar parejas o mensajes';

  @override
  String get feedCountryFilterTitle => 'País';

  @override
  String get feedCountryFilterAll => 'Todos los países';

  @override
  String get explicitContentToggleLabel => 'Mostrar contenido explícito';

  @override
  String get explicitContentToggleHelp =>
      'Las parejas pueden marcar publicaciones como explícitas. Están ocultas por defecto y solo aparecen al activar esta opción.';

  @override
  String get explicitContentMarkLabel =>
      'Marcar esta publicación como explícita';

  @override
  String get reportCategoryFakeProfile => 'Perfil falso';

  @override
  String get reportCategoryHarassment => 'Acoso';

  @override
  String get reportCategoryNonConsensual => 'Contenido no consensuado';

  @override
  String get reportCategoryMinor => 'Sospecha de menor de edad';

  @override
  String get reportCategorySpam => 'Spam';

  @override
  String get reportCategoryOther => 'Otro';

  @override
  String reportingCouple(String names) {
    return 'Reportando a $names';
  }

  @override
  String get reportCategoryLabel => 'Categoría';

  @override
  String get reportDescriptionRequired => 'Descripción (obligatoria)';

  @override
  String get reportDescriptionOptional => 'Descripción (opcional)';

  @override
  String get reportDescriptionHint =>
      'Comparte el contexto que pueda ayudar a los moderadores…';

  @override
  String get reportDescribeOther =>
      'Por favor describe el problema cuando selecciones \"Otro\".';

  @override
  String get reportAlsoBlockSubtitle =>
      'Ambas parejas dejan de verse al instante.';

  @override
  String get reportSubmit => 'Enviar reporte';

  @override
  String get reportSubmitting => 'Enviando…';

  @override
  String get reportFooterConfidential =>
      'Los reportes son confidenciales. La pareja reportada nunca sabe quién envió el reporte.';

  @override
  String reportCouldNotSubmit(String error) {
    return 'No se pudo enviar: $error';
  }

  @override
  String couldNotAccept(String error) {
    return 'No se pudo aceptar: $error';
  }

  @override
  String couldNotDismiss(String error) {
    return 'No se pudo descartar: $error';
  }

  @override
  String couldNotCancelDeletion(String error) {
    return 'No se pudo cancelar la eliminación: $error';
  }

  @override
  String get keepDeletionScheduled => 'Mantener eliminación programada';

  @override
  String couldNotRequestDeletion(String error) {
    return 'No se pudo solicitar la eliminación: $error';
  }

  @override
  String get deleteAccountTitle => 'Eliminar cuenta';

  @override
  String get addTripTitle => 'Añadir viaje';

  @override
  String get destinationLabel => 'Destino';

  @override
  String get datesLabel => 'Fechas';

  @override
  String get travelMatchTitle => 'Travel match';

  @override
  String get startVerification => 'Iniciar verificación';

  @override
  String get retake => 'Repetir';

  @override
  String get openSettings => 'Abrir ajustes';

  @override
  String get goBack => 'Volver';

  @override
  String get blockThisCouple => 'Bloquear a esta pareja';

  @override
  String get reportAction => 'Reportar';

  @override
  String get openChat => 'Ir al chat';

  @override
  String get errorMustBeAdult => 'Ambos miembros deben ser mayores de 18 años';

  @override
  String get editTrip => 'Editar viaje';

  @override
  String get manageTripTitle => 'Gestionar Viaje';

  @override
  String get scheduledTrips => 'Viajes programados';

  @override
  String get addATrip => '+ Agregar un viaje';

  @override
  String get noTripsScheduled => 'No tiene viajes programados';

  @override
  String get destination => 'Destino';

  @override
  String get tripCountry => 'País';

  @override
  String get tripCity => 'Ciudad';

  @override
  String get startDate => 'Fecha de inicio';

  @override
  String get endDate => 'Fecha de fin';

  @override
  String get block => 'Bloquear';

  @override
  String get report => 'Reportar';

  @override
  String get verifyYourEmail => 'Verifica tu correo';

  @override
  String verifyEmailSentTo(Object email) {
    return 'Enviamos un enlace de verificación a $email. Haz clic en él para activar tu cuenta.';
  }

  @override
  String get continueAction => 'Continuar';

  @override
  String get resendEmail => 'Reenviar correo';

  @override
  String resendEmailIn(Object seconds) {
    return 'Reenviar en ${seconds}s';
  }

  @override
  String get useDifferentEmail => 'Usar otro correo';

  @override
  String get errorEmailNotVerified =>
      'Correo aún no verificado. Revisa tu bandeja de entrada.';

  @override
  String get askAboutTrip => 'Preguntar sobre este viaje';

  @override
  String tripMessageTemplate(Object date, Object destination) {
    return 'Hola, vi que viajas a $destination el $date. ¿Coordinamos algo?';
  }

  @override
  String get searchCouples => 'Buscar por nombre...';

  @override
  String get favoriteCouples => 'Parejas favoritas';

  @override
  String get removeFavorite => 'Quitar de favoritos';

  @override
  String get removeFavoriteConfirm =>
      '¿Estás seguro de que quieres quitar esta pareja de tus favoritos?';

  @override
  String get noFavoriteCouples =>
      'Aún no tienes parejas favoritas.\n¡Empieza a guardar las que te gusten!';

  @override
  String get language => 'Idioma';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageSpanish => 'Español';

  @override
  String get prevPhoto => 'Foto anterior';

  @override
  String get nextPhoto => 'Foto siguiente';

  @override
  String get mainPhoto => 'Principal';

  @override
  String get errorLoadProfiles => 'No se pudo cargar los perfiles';

  @override
  String get errorLoadFavorites => 'No se pudo cargar los favoritos';

  @override
  String get noNewCouples =>
      'No hay nuevas parejas por descubrir ahora.\n¡Vuelve más tarde!';

  @override
  String get deleteCommentTitle => 'Eliminar comentario';

  @override
  String get deleteReplyTitle => 'Eliminar respuesta';

  @override
  String get cannotBeUndone => 'Esta acción no se puede deshacer.';

  @override
  String get gallery => 'Galería';

  @override
  String get camera => 'Cámara';

  @override
  String errorPosting(Object error) {
    return 'Error al publicar: $error';
  }

  @override
  String get addComment => 'Añade un comentario...';

  @override
  String get whatsOnYourMind => '¿Qué tenéis en mente?';

  @override
  String get addImage => 'Añadir imagen';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String get chatInputHint => 'Escribe algo...';

  @override
  String get chatEmptyState =>
      'Inicia vuestra conversación…\nvuestra historia empieza aquí. 🌟';

  @override
  String get requests => 'Solicitudes';

  @override
  String get errorSave => 'Error al guardar. Inténtalo de nuevo.';

  @override
  String get noConversations =>
      'Aún no hay conversaciones.\n¡Empieza a conectar con parejas!';

  @override
  String get errorLoadPosts => 'No se pudieron cargar los posts.';

  @override
  String get noPosts => 'Aún no hay publicaciones.\n¡Sé el primero! 🎉';

  @override
  String get deletePostTitle => '¿Eliminar publicación?';

  @override
  String get deletePost => 'Eliminar post';

  @override
  String get comments => 'Comentarios';

  @override
  String get noComments => 'Sin comentarios aún.\n¡Sé el primero! 💬';

  @override
  String replyingTo(Object name) {
    return 'Respondiendo a $name';
  }

  @override
  String get replyingToComment => 'Respondiendo al comentario';

  @override
  String get reply => 'Responder';

  @override
  String get hideReplies => 'Ocultar respuestas';

  @override
  String get viewReply => 'Ver 1 respuesta';

  @override
  String viewReplies(Object count) {
    return 'Ver $count respuestas';
  }

  @override
  String get shareWithCommunity => 'Comparte con la comunidad';

  @override
  String get postToCommunity => 'Publicar en la comunidad';

  @override
  String get deleteAccountDangerZone => 'Zona de peligro';

  @override
  String get deleteAccountDescription =>
      'Esto eliminará permanentemente tu perfil, fotos, viajes y todos los datos asociados. Esta acción no se puede deshacer.';

  @override
  String get deleteAccountTypeToConfirm =>
      'Escribe \"eliminar\" para confirmar';

  @override
  String get deleteAccountConfirmWord => 'eliminar';

  @override
  String get deleteAccountButton => 'Eliminar mi cuenta';

  @override
  String get deleteAccountError =>
      'No se pudo eliminar la cuenta. Inténtalo de nuevo.';

  @override
  String get deleteAccountDeleting => 'Eliminando cuenta...';

  @override
  String get errorServiceUnavailable =>
      'Servicio temporalmente no disponible. Vuelve a intentar en un momento.';
}
