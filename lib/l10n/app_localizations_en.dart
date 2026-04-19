// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Affinity';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get signInAccounts => 'Sign in using your accounts.';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get logIn => 'Log in';

  @override
  String get createAccount => 'Create an account';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get haveNotAccount => 'Haven\'t got an account?';

  @override
  String get name => 'Name';

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
  String get cancel => 'Cancel';

  @override
  String get errorEmailEmpty => 'Please enter an email';

  @override
  String get errorEmailInvalid => 'Please enter a correct email';

  @override
  String get errorPasswordEmpty => 'Please enter a password';

  @override
  String get errorPasswordTooShort => 'Password must be at least 8 characters';

  @override
  String get weHaveSentYouACode => 'We’ve sent you a code';

  @override
  String theCodeWasSentTo(String email) {
    return 'The code was sent to $email';
  }

  @override
  String resendCodeIn(String seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get resendCode => 'Resend code';

  @override
  String get navCouples => 'Couples';

  @override
  String get navCommunity => 'Community';

  @override
  String get navInbox => 'Inbox';

  @override
  String get navProfile => 'Profile';

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
  String get errorGoogleSignIn => 'Google sign-in failed. Please try again.';

  @override
  String get errorAppleSignIn => 'Apple sign-in failed. Please try again.';

  @override
  String get logOut => 'Log out';

  @override
  String get logOutConfirm => 'Are you sure you want to log out?';

  @override
  String get alreadyAMember => 'Already a member?';

  @override
  String get height => 'Height';

  @override
  String get herHeight => 'Her height';

  @override
  String get hisHeight => 'His height';

  @override
  String get interests => 'Interests';

  @override
  String get heightUnit => 'Unit';

  @override
  String get heightCm => 'cm';

  @override
  String get heightFt => 'ft/in';

  @override
  String get errorConfirmPassword => 'Passwords do not match';

  @override
  String get errorSignUp => 'Sign-up failed. Please try again.';

  @override
  String get errorSignIn => 'Sign-in failed. Please check your credentials.';

  @override
  String get completeProfile => 'Complete your profile';

  @override
  String get saveProfile => 'Save';

  @override
  String get photos => 'Photos';

  @override
  String get photoMinError => 'Add at least 1 photo';

  @override
  String get errorSaveProfile => 'Could not save profile. Please try again.';

  @override
  String get errorAllFieldsRequired => 'All fields are required';

  @override
  String get errorNameTooShort => 'Names must be at least 2 characters';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get manageTrips => 'Manage trips';

  @override
  String get viewFavoriteCouples => 'View favorite or saved couples';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get security => 'Security';

  @override
  String get help => 'Help';

  @override
  String get preferences => 'Preferences';

  @override
  String get support => 'Support';

  @override
  String get addYourTags => 'Add your tags';

  @override
  String get tagsDescription =>
      'Show what defines you as a couple. Your tags help create better matches and more meaningful connections.';

  @override
  String get addTag => 'Add';

  @override
  String get updateInterestsNote =>
      'You can update your interests anytime from your profile.';

  @override
  String get addTagTitle => 'Add tag';

  @override
  String get addTagHint => 'Type a tag...';

  @override
  String get chatSuggestion1 => 'Hey you ❤️ Just wanted to say hi!';

  @override
  String get chatSuggestion2 => 'We loved your profile! 😍 Had to reach out';

  @override
  String get chatSuggestion3 => 'What are you two up to this weekend? 🎉';

  @override
  String get chatSuggestion4 => 'Your vibe is everything ✨ we had to match!';

  @override
  String get chatSuggestion5 => 'How about a double date? ☕🍷';

  @override
  String get chatSuggestion6 => 'We\'ve been looking for a couple like you 🙌';
}
