import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

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
    Locale('tr')
  ];

  /// The name of the application
  ///
  /// In en, this message translates to:
  /// **'Zink'**
  String get appName;

  /// The tagline of the application
  ///
  /// In en, this message translates to:
  /// **'AI-Powered Photo Challenges'**
  String get appTagline;

  /// Google sign in button text
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Sign in or sign up header text
  ///
  /// In en, this message translates to:
  /// **'Sign in or Sign up'**
  String get signInOrSignUp;

  /// Prompt for new users
  ///
  /// In en, this message translates to:
  /// **'New to Zink? Sign up with your Google account'**
  String get newUserPrompt;

  /// Prompt for existing users
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in to continue'**
  String get existingUserPrompt;

  /// Apple sign in button text
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// Sign out button text
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Welcome message with user name
  ///
  /// In en, this message translates to:
  /// **'Welcome {name}!'**
  String welcome(String name);

  /// Home navigation item
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Message when there are no active challenges
  ///
  /// In en, this message translates to:
  /// **'No active challenges right now'**
  String get noActiveChallenges;

  /// Title for active challenge section
  ///
  /// In en, this message translates to:
  /// **'Active Challenge'**
  String get activeChallenge;

  /// Title for past challenges section
  ///
  /// In en, this message translates to:
  /// **'Past Challenges'**
  String get pastChallenges;

  /// Time remaining for challenge
  ///
  /// In en, this message translates to:
  /// **'Time Remaining: {time}'**
  String timeRemaining(String time);

  /// Submit photo button text
  ///
  /// In en, this message translates to:
  /// **'Submit Photo'**
  String get submitPhoto;

  /// Take photo button text
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// Choose from gallery button text
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// Submissions section title
  ///
  /// In en, this message translates to:
  /// **'Submissions'**
  String get submissions;

  /// Like count text
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No likes} =1{1 like} other{{count} likes}}'**
  String likes(int count);

  /// Comment count text
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No comments} =1{1 comment} other{{count} comments}}'**
  String comments(int count);

  /// Add comment placeholder text
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get addComment;

  /// Profile navigation item
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Edit profile button text
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Username field label
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// Social links section title
  ///
  /// In en, this message translates to:
  /// **'Social Links'**
  String get socialLinks;

  /// My challenges section title
  ///
  /// In en, this message translates to:
  /// **'My Challenges'**
  String get myChallenges;

  /// Total submissions count
  ///
  /// In en, this message translates to:
  /// **'{count} Submissions'**
  String totalSubmissions(int count);

  /// Most popular filter option
  ///
  /// In en, this message translates to:
  /// **'Most Popular'**
  String get mostPopular;

  /// Newest filter option
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get newest;

  /// Oldest filter option
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get oldest;

  /// Loading text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Error title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Confirm button text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// New challenge notification title
  ///
  /// In en, this message translates to:
  /// **'New challenge available!'**
  String get newChallengeAvailable;

  /// Challenge ending soon notification
  ///
  /// In en, this message translates to:
  /// **'Challenge ending soon!'**
  String get challengeEndingSoon;

  /// Submission success message
  ///
  /// In en, this message translates to:
  /// **'Photo submitted successfully!'**
  String get submissionSuccessful;

  /// Submit button text
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// Welcome title on onboarding screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to Zink!'**
  String get welcomeToZink;

  /// Subtitle on onboarding screen
  ///
  /// In en, this message translates to:
  /// **'Let\'s set up your profile to get started'**
  String get onboardingSubtitle;

  /// Username field label on onboarding
  ///
  /// In en, this message translates to:
  /// **'Choose a username'**
  String get chooseUsername;

  /// Username field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get enterUsername;

  /// Age field label on onboarding
  ///
  /// In en, this message translates to:
  /// **'What\'s your age?'**
  String get whatsYourAge;

  /// Age field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your age'**
  String get enterAge;

  /// Complete setup button text
  ///
  /// In en, this message translates to:
  /// **'Complete Setup'**
  String get completeSetup;

  /// Username validation error
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get usernameRequired;

  /// Username too short validation error
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get usernameTooShort;

  /// Username too long validation error
  ///
  /// In en, this message translates to:
  /// **'Username must be less than 20 characters'**
  String get usernameTooLong;

  /// Username invalid characters validation error
  ///
  /// In en, this message translates to:
  /// **'Username can only contain letters, numbers, and underscores'**
  String get usernameInvalidChars;

  /// Age validation error
  ///
  /// In en, this message translates to:
  /// **'Age is required'**
  String get ageRequired;

  /// Age invalid number validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get enterValidNumber;

  /// Age too young validation error
  ///
  /// In en, this message translates to:
  /// **'You must be at least 13 years old'**
  String get ageTooYoung;

  /// Age too old validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid age'**
  String get enterValidAge;

  /// Privacy note text on onboarding
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Terms of Service and Privacy Policy. Your information is secure and will only be used to enhance your experience.'**
  String get privacyNote;
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
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
