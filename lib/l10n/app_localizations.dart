import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Affinity'**
  String get appTitle;

  /// No description provided for @itsAMatch.
  ///
  /// In en, this message translates to:
  /// **'IT\'S A MATCH!'**
  String get itsAMatch;

  /// No description provided for @matchUs.
  ///
  /// In en, this message translates to:
  /// **'Us'**
  String get matchUs;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// No description provided for @keepExploring.
  ///
  /// In en, this message translates to:
  /// **'Keep exploring'**
  String get keepExploring;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signInAccounts.
  ///
  /// In en, this message translates to:
  /// **'Sign in using your accounts.'**
  String get signInAccounts;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @signInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInWithApple;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccount;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @haveNotAccount.
  ///
  /// In en, this message translates to:
  /// **'Haven\'t got an account?'**
  String get haveNotAccount;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @her.
  ///
  /// In en, this message translates to:
  /// **'Enter her name'**
  String get her;

  /// No description provided for @his.
  ///
  /// In en, this message translates to:
  /// **'Enter his name'**
  String get his;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @dateOfBirthFormat.
  ///
  /// In en, this message translates to:
  /// **'MM-DD-YYYY'**
  String get dateOfBirthFormat;

  /// No description provided for @selectCity.
  ///
  /// In en, this message translates to:
  /// **'Select City'**
  String get selectCity;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @tellUsAboutYourself.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself'**
  String get tellUsAboutYourself;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get confirmPasswordHint;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeBack;

  /// No description provided for @welcomeBackDescription.
  ///
  /// In en, this message translates to:
  /// **'Once verified, the next time you log in, you will be required to enter the verification code.'**
  String get welcomeBackDescription;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Error shown when the email field is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter an email'**
  String get errorEmailEmpty;

  /// Error shown when the email format is invalid
  ///
  /// In en, this message translates to:
  /// **'Please enter a correct email'**
  String get errorEmailInvalid;

  /// Error shown when the password field is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get errorPasswordEmpty;

  /// Error shown when the password is shorter than 8 characters
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get errorPasswordTooShort;

  /// No description provided for @weHaveSentYouACode.
  ///
  /// In en, this message translates to:
  /// **'We’ve sent you a code'**
  String get weHaveSentYouACode;

  /// No description provided for @theCodeWasSentTo.
  ///
  /// In en, this message translates to:
  /// **'The code was sent to {email}'**
  String theCodeWasSentTo(String email);

  /// No description provided for @resendCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String resendCodeIn(String seconds);

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @navCouples.
  ///
  /// In en, this message translates to:
  /// **'Couples'**
  String get navCouples;

  /// No description provided for @navCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get navCommunity;

  /// No description provided for @navInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get navInbox;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @youAreIn.
  ///
  /// In en, this message translates to:
  /// **'You\'re in!'**
  String get youAreIn;

  /// No description provided for @recoveryPasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'We hope you have a fantastic time exploring and connecting with our vibrant community.'**
  String get recoveryPasswordSuccess;

  /// No description provided for @goToLogin.
  ///
  /// In en, this message translates to:
  /// **'Go to Login'**
  String get goToLogin;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start Conversation'**
  String get startConversation;

  /// No description provided for @chatMessageQuickStarters.
  ///
  /// In en, this message translates to:
  /// **'Chat Message (quick starters)'**
  String get chatMessageQuickStarters;

  /// No description provided for @errorGoogleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get errorGoogleSignIn;

  /// No description provided for @errorAppleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in failed. Please try again.'**
  String get errorAppleSignIn;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @logOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logOutConfirm;

  /// No description provided for @alreadyAMember.
  ///
  /// In en, this message translates to:
  /// **'Already a member?'**
  String get alreadyAMember;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @herHeight.
  ///
  /// In en, this message translates to:
  /// **'Her height (optional)'**
  String get herHeight;

  /// No description provided for @hisHeight.
  ///
  /// In en, this message translates to:
  /// **'His height (optional)'**
  String get hisHeight;

  /// No description provided for @interests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get interests;

  /// No description provided for @heightUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get heightUnit;

  /// No description provided for @heightCm.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get heightCm;

  /// No description provided for @heightFt.
  ///
  /// In en, this message translates to:
  /// **'ft/in'**
  String get heightFt;

  /// No description provided for @errorConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get errorConfirmPassword;

  /// No description provided for @errorSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign-up failed. Please try again.'**
  String get errorSignUp;

  /// No description provided for @errorSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Please check your credentials.'**
  String get errorSignIn;

  /// No description provided for @errorEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Please sign in instead.'**
  String get errorEmailAlreadyInUse;

  /// No description provided for @errorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must have at least 8 characters.'**
  String get errorWeakPassword;

  /// No description provided for @errorInvalidEmailFormat.
  ///
  /// In en, this message translates to:
  /// **'Email format is not valid.'**
  String get errorInvalidEmailFormat;

  /// No description provided for @errorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account exists with that email.'**
  String get errorUserNotFound;

  /// No description provided for @errorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password.'**
  String get errorWrongPassword;

  /// No description provided for @errorInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get errorInvalidCredential;

  /// No description provided for @errorTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a few minutes.'**
  String get errorTooManyAttempts;

  /// No description provided for @errorUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account is disabled.'**
  String get errorUserDisabled;

  /// No description provided for @errorNetworkRequest.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your network.'**
  String get errorNetworkRequest;

  /// No description provided for @errorGoogleSignInConfig.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In is not yet configured for this APK build. Check the SHA-1 in the console.'**
  String get errorGoogleSignInConfig;

  /// No description provided for @errorGoogleSignInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in cancelled.'**
  String get errorGoogleSignInCancelled;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get completeProfile;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveProfile;

  /// No description provided for @goToVerificationVideo.
  ///
  /// In en, this message translates to:
  /// **'Verification Video'**
  String get goToVerificationVideo;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @photoMinError.
  ///
  /// In en, this message translates to:
  /// **'Add at least 3 photos'**
  String get photoMinError;

  /// No description provided for @photosCoupleTogetherHint.
  ///
  /// In en, this message translates to:
  /// **'All photos must show the couple together'**
  String get photosCoupleTogetherHint;

  /// No description provided for @errorSaveProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not save profile. Please try again.'**
  String get errorSaveProfile;

  /// No description provided for @errorAllFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'All fields are required'**
  String get errorAllFieldsRequired;

  /// No description provided for @errorNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Names must be at least 2 characters'**
  String get errorNameTooShort;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @manageTrips.
  ///
  /// In en, this message translates to:
  /// **'Manage trips'**
  String get manageTrips;

  /// No description provided for @viewFavoriteCouples.
  ///
  /// In en, this message translates to:
  /// **'View favorite or saved couples'**
  String get viewFavoriteCouples;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @addYourTags.
  ///
  /// In en, this message translates to:
  /// **'Add your tags'**
  String get addYourTags;

  /// No description provided for @tagsDescription.
  ///
  /// In en, this message translates to:
  /// **'Show what defines you as a couple. Your tags help create better matches and more meaningful connections.'**
  String get tagsDescription;

  /// No description provided for @dynamicsSelectWhatRepresentsYou.
  ///
  /// In en, this message translates to:
  /// **'SELECT WHAT REPRESENTS YOU'**
  String get dynamicsSelectWhatRepresentsYou;

  /// No description provided for @dynamicsSelectWhatRepresentsYouSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your dynamics, preferences and interests.'**
  String get dynamicsSelectWhatRepresentsYouSubtitle;

  /// No description provided for @dynamicsSelectWhatYouAreLookingFor.
  ///
  /// In en, this message translates to:
  /// **'Select what you are looking for'**
  String get dynamicsSelectWhatYouAreLookingFor;

  /// No description provided for @dynamicsLookingForTitle.
  ///
  /// In en, this message translates to:
  /// **'LOOKING FOR'**
  String get dynamicsLookingForTitle;

  /// No description provided for @dynamicsLookingForSubtitle.
  ///
  /// In en, this message translates to:
  /// **'These choices describe what you\'re looking for in the other couple.'**
  String get dynamicsLookingForSubtitle;

  /// No description provided for @dynamicsBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'DYNAMICS'**
  String get dynamicsBlockTitle;

  /// No description provided for @dynamicsIndividualIdentity.
  ///
  /// In en, this message translates to:
  /// **'Individual Identity'**
  String get dynamicsIndividualIdentity;

  /// No description provided for @dynamicsRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get dynamicsRole;

  /// No description provided for @dynamicsTypeOfInteraction.
  ///
  /// In en, this message translates to:
  /// **'Type of Interaction'**
  String get dynamicsTypeOfInteraction;

  /// No description provided for @dynamicsExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get dynamicsExperience;

  /// No description provided for @dynamicsInterestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get dynamicsInterestsLabel;

  /// Info dialog content — Identity.
  String get infoIdentityTitle;
  String get infoIdentityBody;
  /// Info dialog content — Role.
  String get infoRoleTitle;
  String get infoRoleBody;
  /// Info dialog content — Interaction.
  String get infoInteractionTitle;
  String get infoInteractionBody;
  /// Info dialog content — Experiences & Interests.
  String get infoExperienceTitle;
  String get infoExperienceBody;
  /// Info dialog content — Individual Openness.
  String get infoOpenessTitle;
  String get infoOpenessBody;
  /// Educational hints in the dynamics block.
  String get infoMultipleHint;
  String get infoSchoolWelcome;
  String get infoStartIdentity;
  /// Guided template hint for the couple description field.
  String get descriptionGuidedHint;

  // ── Taxonomy values (dynamics) — localized labels, English stays
  // as the canonical Firestore value.
  String get dynValHetero;
  String get dynValBiCurious;
  String get dynValBi;
  String get dynValDom;
  String get dynValSub;
  String get dynValSwitch;
  String get dynValParallelPlay;
  String get dynValSoftSwap;
  String get dynValFullSwap;
  String get dynValSameRoom;
  String get dynValSeparateRoom;
  String get dynValVoyeur;
  String get dynValExhibition;
  String get dynValMmf;
  String get dynValFfm;
  String get dynValGroupPlay;
  String get dynValBdsm;
  String get dynValRoleplay;

  /// No description provided for @dynamicsHerLabel.
  ///
  /// In en, this message translates to:
  /// **'Her:'**
  String get dynamicsHerLabel;

  /// No description provided for @dynamicsHimLabel.
  ///
  /// In en, this message translates to:
  /// **'Him:'**
  String get dynamicsHimLabel;

  /// No description provided for @dynamicsOpenToUnicornHer.
  ///
  /// In en, this message translates to:
  /// **'Open to be a Unicorn (her)'**
  String get dynamicsOpenToUnicornHer;

  /// No description provided for @dynamicsOpenToBullHim.
  ///
  /// In en, this message translates to:
  /// **'Open to be a Bull (him)'**
  String get dynamicsOpenToBullHim;

  /// No description provided for @dynamicsLookingForUnicorn.
  ///
  /// In en, this message translates to:
  /// **'Looking for Unicorn'**
  String get dynamicsLookingForUnicorn;

  /// No description provided for @dynamicsLookingForBull.
  ///
  /// In en, this message translates to:
  /// **'Looking for Bull'**
  String get dynamicsLookingForBull;

  /// No description provided for @dynamicsAboutUsOptional.
  ///
  /// In en, this message translates to:
  /// **'About us (optional)'**
  String get dynamicsAboutUsOptional;

  /// No description provided for @dynamicsAboutUsHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourselves'**
  String get dynamicsAboutUsHint;

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addTag;

  /// No description provided for @updateInterestsNote.
  ///
  /// In en, this message translates to:
  /// **'You can update your interests anytime from your profile.'**
  String get updateInterestsNote;

  /// No description provided for @addTagTitle.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get addTagTitle;

  /// No description provided for @addTagHint.
  ///
  /// In en, this message translates to:
  /// **'Type a tag...'**
  String get addTagHint;

  /// No description provided for @chatSuggestion1.
  ///
  /// In en, this message translates to:
  /// **'Hey you ❤️ Just wanted to say hi!'**
  String get chatSuggestion1;

  /// No description provided for @chatSuggestion2.
  ///
  /// In en, this message translates to:
  /// **'We loved your profile! 😍 Had to reach out'**
  String get chatSuggestion2;

  /// No description provided for @chatSuggestion3.
  ///
  /// In en, this message translates to:
  /// **'What are you two up to this weekend? 🎉'**
  String get chatSuggestion3;

  /// No description provided for @chatSuggestion4.
  ///
  /// In en, this message translates to:
  /// **'Your vibe is everything ✨ we had to match!'**
  String get chatSuggestion4;

  /// No description provided for @chatSuggestion5.
  ///
  /// In en, this message translates to:
  /// **'How about a double date? ☕🍷'**
  String get chatSuggestion5;

  /// No description provided for @chatSuggestion6.
  ///
  /// In en, this message translates to:
  /// **'We\'ve been looking for a couple like you 🙌'**
  String get chatSuggestion6;

  /// No description provided for @blockedCouple.
  ///
  /// In en, this message translates to:
  /// **'Blocked {him} & {her}'**
  String blockedCouple(String him, String her);

  /// No description provided for @couldNotBlock.
  ///
  /// In en, this message translates to:
  /// **'Could not block: {error}'**
  String couldNotBlock(String error);

  /// No description provided for @reportSubmittedThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks — the report will be reviewed by our team.'**
  String get reportSubmittedThanks;

  /// No description provided for @requestSentTo.
  ///
  /// In en, this message translates to:
  /// **'Request sent to {name}'**
  String requestSentTo(String name);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @feedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching couples right now'**
  String get feedEmptyTitle;

  /// No description provided for @feedEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Try widening your filters or come back later — new couples join every day.'**
  String get feedEmptyBody;

  /// No description provided for @filtersReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get filtersReset;

  /// No description provided for @filtersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersTitle;

  /// No description provided for @filtersDistanceMin5km.
  ///
  /// In en, this message translates to:
  /// **'Min 5 km'**
  String get filtersDistanceMin5km;

  /// No description provided for @filtersAgeMin.
  ///
  /// In en, this message translates to:
  /// **'Min {n}'**
  String filtersAgeMin(int n);

  /// No description provided for @filtersAgeMax.
  ///
  /// In en, this message translates to:
  /// **'Max {n}'**
  String filtersAgeMax(int n);

  /// No description provided for @selectResortOrCruise.
  ///
  /// In en, this message translates to:
  /// **'Select Resort or Cruise'**
  String get selectResortOrCruise;

  /// No description provided for @anyDestination.
  ///
  /// In en, this message translates to:
  /// **'Any destination'**
  String get anyDestination;

  /// No description provided for @messageRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Message request'**
  String get messageRequestTitle;

  /// No description provided for @messageRequestDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get messageRequestDismiss;

  /// No description provided for @senderProfileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sender profile unavailable'**
  String get senderProfileUnavailable;

  /// No description provided for @reportCouple.
  ///
  /// In en, this message translates to:
  /// **'Report couple'**
  String get reportCouple;

  /// No description provided for @couldNotLoadCoupleProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not load couple profile'**
  String get couldNotLoadCoupleProfile;

  /// No description provided for @imagePickerGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get imagePickerGallery;

  /// No description provided for @imagePickerCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get imagePickerCamera;

  /// No description provided for @photoMain.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get photoMain;

  /// No description provided for @notSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get notSignedIn;

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securityTitle;

  /// No description provided for @couldNotLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load: {error}'**
  String couldNotLoadError(String error);

  /// No description provided for @unblockFailed.
  ///
  /// In en, this message translates to:
  /// **'Unblock failed: {error}'**
  String unblockFailed(String error);

  /// No description provided for @unblockAction.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblockAction;

  /// No description provided for @accountSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Account settings'**
  String get accountSettingsTitle;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted'**
  String get reportSubmitted;

  /// No description provided for @reportCoupleTitle.
  ///
  /// In en, this message translates to:
  /// **'Report couple'**
  String get reportCoupleTitle;

  /// No description provided for @blockThisCoupleToo.
  ///
  /// In en, this message translates to:
  /// **'Block this couple too'**
  String get blockThisCoupleToo;

  /// No description provided for @manageTripsTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage trips'**
  String get manageTripsTitle;

  /// No description provided for @addTrip.
  ///
  /// In en, this message translates to:
  /// **'Add trip'**
  String get addTrip;

  /// No description provided for @exploreMoreTrips.
  ///
  /// In en, this message translates to:
  /// **'Explore More Trips'**
  String get exploreMoreTrips;

  /// No description provided for @noTripsYet.
  ///
  /// In en, this message translates to:
  /// **'No trips yet.\nTap \"Add trip\" to get your first match.'**
  String get noTripsYet;

  /// No description provided for @couldNotOpenPartnerSite.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open partner travel site.'**
  String get couldNotOpenPartnerSite;

  /// No description provided for @deleteTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete trip?'**
  String get deleteTripTitle;

  /// No description provided for @deleteTripBody.
  ///
  /// In en, this message translates to:
  /// **'Cancels notifications to couples matched on \"{destination}\".'**
  String deleteTripBody(String destination);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @noBlockedCouples.
  ///
  /// In en, this message translates to:
  /// **'You have not blocked anyone.'**
  String get noBlockedCouples;

  /// No description provided for @blockedOn.
  ///
  /// In en, this message translates to:
  /// **'Blocked on {date}'**
  String blockedOn(String date);

  /// No description provided for @blockOriginViaReport.
  ///
  /// In en, this message translates to:
  /// **'(via report)'**
  String get blockOriginViaReport;

  /// No description provided for @blockOriginAuto.
  ///
  /// In en, this message translates to:
  /// **'(auto)'**
  String get blockOriginAuto;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get changeEmail;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @languageSettingTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettingTitle;

  /// No description provided for @languageSettingSubtitleSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow device language'**
  String get languageSettingSubtitleSystem;

  /// No description provided for @languageOptionSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageOptionSystem;

  /// No description provided for @languageOptionEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageOptionEnglish;

  /// No description provided for @languageOptionSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageOptionSpanish;

  /// No description provided for @chatSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search couples or messages'**
  String get chatSearchHint;

  /// No description provided for @feedCountryFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get feedCountryFilterTitle;

  /// No description provided for @feedCountryFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All countries'**
  String get feedCountryFilterAll;

  /// No description provided for @explicitContentToggleLabel.
  ///
  /// In en, this message translates to:
  /// **'Show explicit content'**
  String get explicitContentToggleLabel;

  /// No description provided for @explicitContentToggleHelp.
  ///
  /// In en, this message translates to:
  /// **'Couples can mark posts as explicit. They are hidden by default and only appear when this is on.'**
  String get explicitContentToggleHelp;

  /// No description provided for @explicitContentMarkLabel.
  ///
  /// In en, this message translates to:
  /// **'Mark this post as explicit'**
  String get explicitContentMarkLabel;

  /// No description provided for @reportCategoryFakeProfile.
  ///
  /// In en, this message translates to:
  /// **'Fake profile'**
  String get reportCategoryFakeProfile;

  /// No description provided for @reportCategoryHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get reportCategoryHarassment;

  /// No description provided for @reportCategoryNonConsensual.
  ///
  /// In en, this message translates to:
  /// **'Non-consensual content'**
  String get reportCategoryNonConsensual;

  /// No description provided for @reportCategoryMinor.
  ///
  /// In en, this message translates to:
  /// **'Suspected minor'**
  String get reportCategoryMinor;

  /// No description provided for @reportCategorySpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get reportCategorySpam;

  /// No description provided for @reportCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportCategoryOther;

  /// No description provided for @reportingCouple.
  ///
  /// In en, this message translates to:
  /// **'Reporting {names}'**
  String reportingCouple(String names);

  /// No description provided for @reportCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get reportCategoryLabel;

  /// No description provided for @reportDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Description (required)'**
  String get reportDescriptionRequired;

  /// No description provided for @reportDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get reportDescriptionOptional;

  /// No description provided for @reportDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Share any context that would help moderators…'**
  String get reportDescriptionHint;

  /// No description provided for @reportDescribeOther.
  ///
  /// In en, this message translates to:
  /// **'Please describe the issue when selecting \"Other\".'**
  String get reportDescribeOther;

  /// No description provided for @reportAlsoBlockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Both couples stop seeing each other immediately.'**
  String get reportAlsoBlockSubtitle;

  /// No description provided for @reportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get reportSubmit;

  /// No description provided for @reportSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get reportSubmitting;

  /// No description provided for @reportFooterConfidential.
  ///
  /// In en, this message translates to:
  /// **'Reports are confidential. The reported couple is never told who submitted the report.'**
  String get reportFooterConfidential;

  /// No description provided for @reportCouldNotSubmit.
  ///
  /// In en, this message translates to:
  /// **'Could not submit: {error}'**
  String reportCouldNotSubmit(String error);

  /// No description provided for @couldNotAccept.
  ///
  /// In en, this message translates to:
  /// **'Could not accept: {error}'**
  String couldNotAccept(String error);

  /// No description provided for @couldNotDismiss.
  ///
  /// In en, this message translates to:
  /// **'Could not dismiss: {error}'**
  String couldNotDismiss(String error);

  /// No description provided for @couldNotCancelDeletion.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel deletion: {error}'**
  String couldNotCancelDeletion(String error);

  /// No description provided for @keepDeletionScheduled.
  ///
  /// In en, this message translates to:
  /// **'Keep deletion scheduled'**
  String get keepDeletionScheduled;

  /// No description provided for @couldNotRequestDeletion.
  ///
  /// In en, this message translates to:
  /// **'Could not request deletion: {error}'**
  String couldNotRequestDeletion(String error);

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountTitle;

  /// No description provided for @addTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Add trip'**
  String get addTripTitle;

  /// No description provided for @destinationLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destinationLabel;

  /// No description provided for @datesLabel.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get datesLabel;

  /// No description provided for @travelMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Travel match'**
  String get travelMatchTitle;

  /// No description provided for @startVerification.
  ///
  /// In en, this message translates to:
  /// **'Start verification'**
  String get startVerification;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// No description provided for @blockThisCouple.
  ///
  /// In en, this message translates to:
  /// **'Block this couple'**
  String get blockThisCouple;

  /// No description provided for @reportAction.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportAction;

  /// No description provided for @openChat.
  ///
  /// In en, this message translates to:
  /// **'Open Chat'**
  String get openChat;

  /// No description provided for @errorMustBeAdult.
  ///
  /// In en, this message translates to:
  /// **'Both members must be at least 18 years old'**
  String get errorMustBeAdult;

  /// No description provided for @editTrip.
  ///
  /// In en, this message translates to:
  /// **'Edit trip'**
  String get editTrip;

  /// No description provided for @manageTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Trip'**
  String get manageTripTitle;

  /// No description provided for @scheduledTrips.
  ///
  /// In en, this message translates to:
  /// **'Scheduled trips'**
  String get scheduledTrips;

  /// No description provided for @addATrip.
  ///
  /// In en, this message translates to:
  /// **'+ Add a trip'**
  String get addATrip;

  /// No description provided for @noTripsScheduled.
  ///
  /// In en, this message translates to:
  /// **'No trips scheduled'**
  String get noTripsScheduled;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @tripCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get tripCountry;

  /// No description provided for @tripCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get tripCity;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get endDate;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @reportPost.
  ///
  /// In en, this message translates to:
  /// **'Report post'**
  String get reportPost;

  /// No description provided for @blockAuthor.
  ///
  /// In en, this message translates to:
  /// **'Block couple'**
  String get blockAuthor;

  /// No description provided for @blockCoupleConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Block this couple?'**
  String get blockCoupleConfirmTitle;

  /// No description provided for @blockCoupleConfirmBody.
  ///
  /// In en, this message translates to:
  /// **"You won't see their posts, profile or messages anymore. You can undo this from Settings."**
  String get blockCoupleConfirmBody;

  /// No description provided for @verifyYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyYourEmail;

  /// No description provided for @verifyEmailSentTo.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a verification link to {email}. Click it to activate your account.'**
  String verifyEmailSentTo(Object email);

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get resendEmail;

  /// No description provided for @resendEmailIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendEmailIn(Object seconds);

  /// No description provided for @useDifferentEmail.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get useDifferentEmail;

  /// No description provided for @errorEmailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Email not verified yet. Please check your inbox.'**
  String get errorEmailNotVerified;

  /// No description provided for @askAboutTrip.
  ///
  /// In en, this message translates to:
  /// **'Ask about this trip'**
  String get askAboutTrip;

  /// No description provided for @tripMessageTemplate.
  ///
  /// In en, this message translates to:
  /// **'Hi, I saw you\'re traveling to {destination} on {date}. Should we coordinate something?'**
  String tripMessageTemplate(Object date, Object destination);

  /// No description provided for @searchCouples.
  ///
  /// In en, this message translates to:
  /// **'Search by name...'**
  String get searchCouples;

  /// No description provided for @favoriteCouples.
  ///
  /// In en, this message translates to:
  /// **'Favorite Couples'**
  String get favoriteCouples;

  /// No description provided for @removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFavorite;

  /// No description provided for @removeFavoriteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this couple from your favorites?'**
  String get removeFavoriteConfirm;

  /// No description provided for @noFavoriteCouples.
  ///
  /// In en, this message translates to:
  /// **'No favorite couples yet.\nStart adding couples you like!'**
  String get noFavoriteCouples;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// No description provided for @prevPhoto.
  ///
  /// In en, this message translates to:
  /// **'Prev photo'**
  String get prevPhoto;

  /// No description provided for @nextPhoto.
  ///
  /// In en, this message translates to:
  /// **'Next photo'**
  String get nextPhoto;

  /// No description provided for @mainPhoto.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get mainPhoto;

  /// No description provided for @errorLoadProfiles.
  ///
  /// In en, this message translates to:
  /// **'Could not load profiles'**
  String get errorLoadProfiles;

  /// No description provided for @errorLoadFavorites.
  ///
  /// In en, this message translates to:
  /// **'Could not load favorites'**
  String get errorLoadFavorites;

  /// No description provided for @noNewCouples.
  ///
  /// In en, this message translates to:
  /// **'No new couples to discover right now.\nCome back later!'**
  String get noNewCouples;

  /// No description provided for @deleteCommentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete comment'**
  String get deleteCommentTitle;

  /// No description provided for @deleteReplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete reply'**
  String get deleteReplyTitle;

  /// No description provided for @cannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get cannotBeUndone;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @errorPosting.
  ///
  /// In en, this message translates to:
  /// **'Error posting: {error}'**
  String errorPosting(Object error);

  /// No description provided for @addComment.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get addComment;

  /// No description provided for @whatsOnYourMind.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind?'**
  String get whatsOnYourMind;

  /// No description provided for @addImage.
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get addImage;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @chatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type something...'**
  String get chatInputHint;

  /// No description provided for @chatEmptyState.
  ///
  /// In en, this message translates to:
  /// **'Start your conversation…\nyour story begins here. 🌟'**
  String get chatEmptyState;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @errorSave.
  ///
  /// In en, this message translates to:
  /// **'Error saving. Please try again.'**
  String get errorSave;

  /// No description provided for @noConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet.\nStart connecting with couples!'**
  String get noConversations;

  /// No description provided for @errorLoadPosts.
  ///
  /// In en, this message translates to:
  /// **'Could not load posts.'**
  String get errorLoadPosts;

  /// No description provided for @noPosts.
  ///
  /// In en, this message translates to:
  /// **'No posts yet.\nBe the first! 🎉'**
  String get noPosts;

  /// No description provided for @deletePostTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete post?'**
  String get deletePostTitle;

  /// No description provided for @deletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete post'**
  String get deletePost;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @noComments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.\nBe the first! 💬'**
  String get noComments;

  /// No description provided for @replyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String replyingTo(Object name);

  /// No description provided for @replyingToComment.
  ///
  /// In en, this message translates to:
  /// **'Replying to comment'**
  String get replyingToComment;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @hideReplies.
  ///
  /// In en, this message translates to:
  /// **'Hide replies'**
  String get hideReplies;

  /// No description provided for @viewReply.
  ///
  /// In en, this message translates to:
  /// **'See 1 reply'**
  String get viewReply;

  /// No description provided for @viewReplies.
  ///
  /// In en, this message translates to:
  /// **'See {count} replies'**
  String viewReplies(Object count);

  /// No description provided for @shareWithCommunity.
  ///
  /// In en, this message translates to:
  /// **'Share with the community'**
  String get shareWithCommunity;

  /// No description provided for @postToCommunity.
  ///
  /// In en, this message translates to:
  /// **'Post to the community'**
  String get postToCommunity;

  /// No description provided for @deleteAccountDangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get deleteAccountDangerZone;

  /// No description provided for @deleteAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your profile, photos, trips, and all associated data. This action cannot be undone.'**
  String get deleteAccountDescription;

  /// No description provided for @deleteAccountTypeToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type \"delete\" to confirm'**
  String get deleteAccountTypeToConfirm;

  /// No description provided for @deleteAccountConfirmWord.
  ///
  /// In en, this message translates to:
  /// **'delete'**
  String get deleteAccountConfirmWord;

  /// No description provided for @deleteAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteAccountButton;

  /// No description provided for @deleteAccountError.
  ///
  /// In en, this message translates to:
  /// **'Could not delete account. Please try again.'**
  String get deleteAccountError;

  /// No description provided for @deleteAccountDeleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting account...'**
  String get deleteAccountDeleting;

  /// No description provided for @errorServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Service temporarily unavailable. Please try again in a moment.'**
  String get errorServiceUnavailable;

  /// No description provided for @verificationCueLookAtCamera.
  ///
  /// In en, this message translates to:
  /// **'Look at the camera'**
  String get verificationCueLookAtCamera;

  /// No description provided for @verificationCueTurnRight.
  ///
  /// In en, this message translates to:
  /// **'Turn your head to the right'**
  String get verificationCueTurnRight;

  /// No description provided for @verificationCueTurnLeft.
  ///
  /// In en, this message translates to:
  /// **'Turn your head to the left'**
  String get verificationCueTurnLeft;

  /// No description provided for @verificationIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Look at the camera, then turn your head to the right, then to the left'**
  String get verificationIntroBody;

  /// No description provided for @verificationStepBothPartners.
  ///
  /// In en, this message translates to:
  /// **'Ideally both partners appear — one is also allowed'**
  String get verificationStepBothPartners;

  /// No description provided for @verificationStepLighting.
  ///
  /// In en, this message translates to:
  /// **'Good lighting on your face'**
  String get verificationStepLighting;

  /// No description provided for @verificationStepRecordingLength.
  ///
  /// In en, this message translates to:
  /// **'Recording lasts about 8 seconds'**
  String get verificationStepRecordingLength;

  /// No description provided for @verificationStepNoFilters.
  ///
  /// In en, this message translates to:
  /// **'No filters, no edits — straight from the camera'**
  String get verificationStepNoFilters;

  /// No description provided for @verificationIntroHeaderHere.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what you need to do:'**
  String get verificationIntroHeaderHere;

  /// No description provided for @reportSubmittedWithFollowup.
  ///
  /// In en, this message translates to:
  /// **'Thanks — our team will review your report and we will notify you once a decision is made.'**
  String get reportSubmittedWithFollowup;

  /// No description provided for @communityMarkExplicitTag.
  ///
  /// In en, this message translates to:
  /// **'Mark this post as explicit content (18+)'**
  String get communityMarkExplicitTag;

  /// No description provided for @communityFilterCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get communityFilterCountry;

  /// No description provided for @communityShowExplicit.
  ///
  /// In en, this message translates to:
  /// **'Show explicit feed'**
  String get communityShowExplicit;

  /// No description provided for @requestMatchNoInterestsListed.
  ///
  /// In en, this message translates to:
  /// **'This couple has not listed their interests yet.'**
  String get requestMatchNoInterestsListed;
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
