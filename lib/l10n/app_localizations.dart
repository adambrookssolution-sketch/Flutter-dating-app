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
  String get languageSettingTitle;

  /// No description provided for @languageSettingSubtitleSystem.
  String get languageSettingSubtitleSystem;

  /// No description provided for @languageOptionSystem.
  String get languageOptionSystem;

  /// No description provided for @languageOptionEnglish.
  String get languageOptionEnglish;

  /// No description provided for @languageOptionSpanish.
  String get languageOptionSpanish;

  /// No description provided for @chatSearchHint.
  String get chatSearchHint;

  /// No description provided for @feedCountryFilterTitle.
  String get feedCountryFilterTitle;

  /// No description provided for @feedCountryFilterAll.
  String get feedCountryFilterAll;

  /// No description provided for @explicitContentToggleLabel.
  String get explicitContentToggleLabel;

  /// No description provided for @explicitContentToggleHelp.
  String get explicitContentToggleHelp;

  /// No description provided for @explicitContentMarkLabel.
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
