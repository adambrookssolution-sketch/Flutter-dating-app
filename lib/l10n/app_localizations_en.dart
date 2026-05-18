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
  String get itsAMatch => 'IT\'S A MATCH!';

  @override
  String get matchUs => 'Us';

  @override
  String get sendMessage => 'Send message';

  @override
  String get keepExploring => 'Keep exploring';

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
  String get dynamicsSelectWhatRepresentsYou => 'SELECT WHAT REPRESENTS YOU';

  @override
  String get dynamicsSelectWhatRepresentsYouSubtitle =>
      'Tell us about your dynamics, preferences and interests.';

  @override
  String get dynamicsSelectWhatYouAreLookingFor =>
      'Select what you are looking for';

  @override
  String get dynamicsLookingForTitle => 'LOOKING FOR';

  @override
  String get dynamicsLookingForSubtitle =>
      'These choices describe what you\'re looking for in the other couple.';

  @override
  String get dynamicsBlockTitle => 'DYNAMICS';

  @override
  String get dynamicsIndividualIdentity => 'Individual Identity';

  @override
  String get dynamicsRole => 'Role';

  @override
  String get dynamicsTypeOfInteraction => 'Type of Interaction';

  @override
  String get dynamicsExperience => 'Experience';

  @override
  String get dynamicsInterestsLabel => 'Interests';

  @override
  String get dynamicsHerLabel => 'Her:';

  @override
  String get dynamicsHimLabel => 'Him:';

  @override
  String get dynamicsOpenToUnicornHer => 'Open to be a Unicorn (her)';

  @override
  String get dynamicsOpenToBullHim => 'Open to be a Bull (him)';

  @override
  String get dynamicsLookingForUnicorn => 'Looking for Unicorn';

  @override
  String get dynamicsLookingForBull => 'Looking for Bull';

  @override
  String get dynamicsAboutUsOptional => 'About us (optional)';

  @override
  String get dynamicsAboutUsHint => 'Tell us about yourselves';

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

  @override
  String get openChat => 'Open Chat';

  @override
  String get errorMustBeAdult => 'Both members must be at least 18 years old';

  @override
  String get editTrip => 'Edit trip';

  @override
  String get manageTripTitle => 'Manage Trip';

  @override
  String get scheduledTrips => 'Scheduled trips';

  @override
  String get addATrip => '+ Add a trip';

  @override
  String get noTripsScheduled => 'No trips scheduled';

  @override
  String get destination => 'Destination';

  @override
  String get tripCountry => 'Country';

  @override
  String get tripCity => 'City';

  @override
  String get startDate => 'Start date';

  @override
  String get endDate => 'End date';

  @override
  String get block => 'Block';

  @override
  String get report => 'Report';

  @override
  String get verifyYourEmail => 'Verify your email';

  @override
  String verifyEmailSentTo(Object email) {
    return 'We\'ve sent a verification link to $email. Click it to activate your account.';
  }

  @override
  String get continueAction => 'Continue';

  @override
  String get resendEmail => 'Resend email';

  @override
  String resendEmailIn(Object seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get useDifferentEmail => 'Use a different email';

  @override
  String get errorEmailNotVerified =>
      'Email not verified yet. Please check your inbox.';

  @override
  String get askAboutTrip => 'Ask about this trip';

  @override
  String tripMessageTemplate(Object date, Object destination) {
    return 'Hi, I saw you\'re traveling to $destination on $date. Should we coordinate something?';
  }

  @override
  String get searchCouples => 'Search by name...';

  @override
  String get favoriteCouples => 'Favorite Couples';

  @override
  String get removeFavorite => 'Remove from favorites';

  @override
  String get removeFavoriteConfirm =>
      'Are you sure you want to remove this couple from your favorites?';

  @override
  String get noFavoriteCouples =>
      'No favorite couples yet.\nStart adding couples you like!';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get prevPhoto => 'Prev photo';

  @override
  String get nextPhoto => 'Next photo';

  @override
  String get mainPhoto => 'Main';

  @override
  String get errorLoadProfiles => 'Could not load profiles';

  @override
  String get errorLoadFavorites => 'Could not load favorites';

  @override
  String get noNewCouples =>
      'No new couples to discover right now.\nCome back later!';

  @override
  String get deleteCommentTitle => 'Delete comment';

  @override
  String get deleteReplyTitle => 'Delete reply';

  @override
  String get cannotBeUndone => 'This action cannot be undone.';

  @override
  String get gallery => 'Gallery';

  @override
  String get camera => 'Camera';

  @override
  String errorPosting(Object error) {
    return 'Error posting: $error';
  }

  @override
  String get addComment => 'Add a comment...';

  @override
  String get whatsOnYourMind => 'What\'s on your mind?';

  @override
  String get addImage => 'Add image';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get chatInputHint => 'Type something...';

  @override
  String get chatEmptyState =>
      'Start your conversation…\nyour story begins here. 🌟';

  @override
  String get requests => 'Requests';

  @override
  String get errorSave => 'Error saving. Please try again.';

  @override
  String get noConversations =>
      'No conversations yet.\nStart connecting with couples!';

  @override
  String get errorLoadPosts => 'Could not load posts.';

  @override
  String get noPosts => 'No posts yet.\nBe the first! 🎉';

  @override
  String get deletePostTitle => 'Delete post?';

  @override
  String get deletePost => 'Delete post';

  @override
  String get comments => 'Comments';

  @override
  String get noComments => 'No comments yet.\nBe the first! 💬';

  @override
  String replyingTo(Object name) {
    return 'Replying to $name';
  }

  @override
  String get replyingToComment => 'Replying to comment';

  @override
  String get reply => 'Reply';

  @override
  String get hideReplies => 'Hide replies';

  @override
  String get viewReply => 'See 1 reply';

  @override
  String viewReplies(Object count) {
    return 'See $count replies';
  }

  @override
  String get shareWithCommunity => 'Share with the community';

  @override
  String get postToCommunity => 'Post to the community';

  @override
  String get deleteAccountDangerZone => 'Danger Zone';

  @override
  String get deleteAccountDescription =>
      'This will permanently delete your profile, photos, trips, and all associated data. This action cannot be undone.';

  @override
  String get deleteAccountTypeToConfirm => 'Type \"delete\" to confirm';

  @override
  String get deleteAccountConfirmWord => 'delete';

  @override
  String get deleteAccountButton => 'Delete my account';

  @override
  String get deleteAccountError =>
      'Could not delete account. Please try again.';

  @override
  String get deleteAccountDeleting => 'Deleting account...';

  @override
  String get errorServiceUnavailable =>
      'Service temporarily unavailable. Please try again in a moment.';

  @override
  String get verificationCueLookAtCamera => 'Look at the camera';

  @override
  String get verificationCueTurnRight => 'Turn your head to the right';

  @override
  String get verificationCueTurnLeft => 'Turn your head to the left';

  @override
  String get verificationIntroBody =>
      'Look at the camera, then turn your head to the right, then to the left';

  @override
  String get verificationStepBothPartners =>
      'Ideally both partners appear — one is also allowed';

  @override
  String get verificationStepLighting => 'Good lighting on your face';

  @override
  String get verificationStepRecordingLength =>
      'Recording lasts about 8 seconds';

  @override
  String get verificationStepNoFilters =>
      'No filters, no edits — straight from the camera';

  @override
  String get verificationIntroHeaderHere => 'Here\'s what you need to do:';

  @override
  String get reportSubmittedWithFollowup =>
      'Thanks — our team will review your report and we will notify you once a decision is made.';

  @override
  String get communityMarkExplicitTag =>
      'Mark this post as explicit content (18+)';

  @override
  String get communityFilterCountry => 'Country';

  @override
  String get communityShowExplicit => 'Show explicit feed';
}
