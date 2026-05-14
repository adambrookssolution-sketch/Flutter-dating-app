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
  String get herHeight => 'Her height (optional)';

  @override
  String get hisHeight => 'His height (optional)';

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
  String get errorEmailAlreadyInUse =>
      'This email is already registered. Please sign in instead.';

  @override
  String get errorWeakPassword => 'Password must have at least 8 characters.';

  @override
  String get errorInvalidEmailFormat => 'Email format is not valid.';

  @override
  String get errorUserNotFound => 'No account exists with that email.';

  @override
  String get errorWrongPassword => 'Incorrect password.';

  @override
  String get errorInvalidCredential => 'Email or password is incorrect.';

  @override
  String get errorTooManyAttempts =>
      'Too many attempts. Please wait a few minutes.';

  @override
  String get errorUserDisabled => 'This account is disabled.';

  @override
  String get errorNetworkRequest =>
      'No internet connection. Check your network.';

  @override
  String get errorGoogleSignInConfig =>
      'Google Sign-In is not yet configured for this APK build. Check the SHA-1 in the console.';

  @override
  String get errorGoogleSignInCancelled => 'Google sign-in cancelled.';

  @override
  String get completeProfile => 'Complete your profile';

  @override
  String get saveProfile => 'Save';

  @override
  String get goToVerificationVideo => 'Verification Video';

  @override
  String get photos => 'Photos';

  @override
  String get photoMinError => 'Add at least 3 photos';

  @override
  String get photosCoupleTogetherHint =>
      'All photos must show the couple together';

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

  @override
  String blockedCouple(String him, String her) {
    return 'Blocked $him & $her';
  }

  @override
  String couldNotBlock(String error) {
    return 'Could not block: $error';
  }

  @override
  String get reportSubmittedThanks =>
      'Thanks — the report will be reviewed by our team.';

  @override
  String requestSentTo(String name) {
    return 'Request sent to $name';
  }

  @override
  String get retry => 'Retry';

  @override
  String get feedEmptyTitle => 'No matching couples right now';

  @override
  String get feedEmptyBody =>
      'Try widening your filters or come back later — new couples join every day.';

  @override
  String get filtersReset => 'Reset';

  @override
  String get filtersTitle => 'Filters';

  @override
  String get filtersDistanceMin5km => 'Min 5 km';

  @override
  String filtersAgeMin(int n) {
    return 'Min $n';
  }

  @override
  String filtersAgeMax(int n) {
    return 'Max $n';
  }

  @override
  String get selectResortOrCruise => 'Select Resort or Cruise';

  @override
  String get anyDestination => 'Any destination';

  @override
  String get messageRequestTitle => 'Message request';

  @override
  String get messageRequestDismiss => 'Dismiss';

  @override
  String get senderProfileUnavailable => 'Sender profile unavailable';

  @override
  String get reportCouple => 'Report couple';

  @override
  String get couldNotLoadCoupleProfile => 'Could not load couple profile';

  @override
  String get imagePickerGallery => 'Gallery';

  @override
  String get imagePickerCamera => 'Camera';

  @override
  String get photoMain => 'Main';

  @override
  String get notSignedIn => 'Not signed in';

  @override
  String get securityTitle => 'Security';

  @override
  String couldNotLoadError(String error) {
    return 'Could not load: $error';
  }

  @override
  String unblockFailed(String error) {
    return 'Unblock failed: $error';
  }

  @override
  String get unblockAction => 'Unblock';

  @override
  String get accountSettingsTitle => 'Account settings';

  @override
  String get changePassword => 'Change password';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get reportSubmitted => 'Report submitted';

  @override
  String get reportCoupleTitle => 'Report couple';

  @override
  String get blockThisCoupleToo => 'Block this couple too';

  @override
  String get manageTripsTitle => 'Manage trips';

  @override
  String get addTrip => 'Add trip';

  @override
  String get exploreMoreTrips => 'Explore More Trips';

  @override
  String get noTripsYet =>
      'No trips yet.\nTap \"Add trip\" to get your first match.';

  @override
  String get couldNotOpenPartnerSite => 'Couldn\'t open partner travel site.';

  @override
  String get deleteTripTitle => 'Delete trip?';

  @override
  String deleteTripBody(String destination) {
    return 'Cancels notifications to couples matched on \"$destination\".';
  }

  @override
  String get delete => 'Delete';

  @override
  String get noBlockedCouples => 'You have not blocked anyone.';

  @override
  String blockedOn(String date) {
    return 'Blocked on $date';
  }

  @override
  String get blockOriginViaReport => '(via report)';

  @override
  String get blockOriginAuto => '(auto)';

  @override
  String get changeEmail => 'Change email';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get languageSettingTitle => 'Language';

  @override
  String get languageSettingSubtitleSystem => 'Follow device language';

  @override
  String get languageOptionSystem => 'System default';

  @override
  String get languageOptionEnglish => 'English';

  @override
  String get languageOptionSpanish => 'Español';

  @override
  String get chatSearchHint => 'Search couples or messages';

  @override
  String get feedCountryFilterTitle => 'Country';

  @override
  String get feedCountryFilterAll => 'All countries';

  @override
  String get explicitContentToggleLabel => 'Show explicit content';

  @override
  String get explicitContentToggleHelp =>
      'Couples can mark posts as explicit. They are hidden by default and only appear when this is on.';

  @override
  String get explicitContentMarkLabel => 'Mark this post as explicit';

  @override
  String get reportCategoryFakeProfile => 'Fake profile';

  @override
  String get reportCategoryHarassment => 'Harassment';

  @override
  String get reportCategoryNonConsensual => 'Non-consensual content';

  @override
  String get reportCategoryMinor => 'Suspected minor';

  @override
  String get reportCategorySpam => 'Spam';

  @override
  String get reportCategoryOther => 'Other';

  @override
  String reportingCouple(String names) {
    return 'Reporting $names';
  }

  @override
  String get reportCategoryLabel => 'Category';

  @override
  String get reportDescriptionRequired => 'Description (required)';

  @override
  String get reportDescriptionOptional => 'Description (optional)';

  @override
  String get reportDescriptionHint =>
      'Share any context that would help moderators…';

  @override
  String get reportDescribeOther =>
      'Please describe the issue when selecting \"Other\".';

  @override
  String get reportAlsoBlockSubtitle =>
      'Both couples stop seeing each other immediately.';

  @override
  String get reportSubmit => 'Submit report';

  @override
  String get reportSubmitting => 'Submitting…';

  @override
  String get reportFooterConfidential =>
      'Reports are confidential. The reported couple is never told who submitted the report.';

  @override
  String reportCouldNotSubmit(String error) {
    return 'Could not submit: $error';
  }

  @override
  String couldNotAccept(String error) {
    return 'Could not accept: $error';
  }

  @override
  String couldNotDismiss(String error) {
    return 'Could not dismiss: $error';
  }

  @override
  String couldNotCancelDeletion(String error) {
    return 'Could not cancel deletion: $error';
  }

  @override
  String get keepDeletionScheduled => 'Keep deletion scheduled';

  @override
  String couldNotRequestDeletion(String error) {
    return 'Could not request deletion: $error';
  }

  @override
  String get deleteAccountTitle => 'Delete account';

  @override
  String get addTripTitle => 'Add trip';

  @override
  String get destinationLabel => 'Destination';

  @override
  String get datesLabel => 'Dates';

  @override
  String get travelMatchTitle => 'Travel match';

  @override
  String get startVerification => 'Start verification';

  @override
  String get retake => 'Retake';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get goBack => 'Go back';

  @override
  String get blockThisCouple => 'Block this couple';

  @override
  String get reportAction => 'Report';
}
