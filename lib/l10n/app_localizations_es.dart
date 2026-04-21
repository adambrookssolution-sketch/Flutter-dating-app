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
}
