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
  String get her => 'Enter her name';

  @override
  String get his => 'Enter his name';

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get dateOfBirthFormat => 'MM-DD-YYYY';

  @override
  String get selectCity => 'Select City';

  @override
  String get description => 'Description';

  @override
  String get tellUsAboutYourself => 'Tell us about yourself';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get confirmPasswordHint => 'Re-enter your password';

  @override
  String get welcomeBack => 'Welcome back!';

  @override
  String get welcomeBackDescription =>
      'Once verified, the next time you log in, you will be required to enter the verification code.';

  @override
  String get verify => 'Verify';

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
  String get youAreIn => 'You\'re in!';

  @override
  String get recoveryPasswordSuccess =>
      'We hope you have a fantastic time exploring and connecting with our vibrant community.';

  @override
  String get goToLogin => 'Go to Login';

  @override
  String get startConversation => 'Start Conversation';

  @override
  String get chatMessageQuickStarters => 'Chat Message (quick starters)';

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
  String get alreadyAMember => 'Already a member?';

  @override
  String get height => 'Height';

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
}
