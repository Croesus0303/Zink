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

  /// Sign out confirmation dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirmation;

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
  String commentCount(int count);

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

  /// Profile picture label
  ///
  /// In en, this message translates to:
  /// **'Profile Picture'**
  String get profilePicture;

  /// Change profile picture button text
  ///
  /// In en, this message translates to:
  /// **'Change Profile Picture'**
  String get changeProfilePicture;

  /// Display name field label
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// Basic information section title
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// Social media links section title
  ///
  /// In en, this message translates to:
  /// **'Social Media Links'**
  String get socialMediaLinks;

  /// Instagram social media platform
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get instagram;

  /// Twitter social media platform
  ///
  /// In en, this message translates to:
  /// **'Twitter'**
  String get twitter;

  /// Facebook social media platform
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get facebook;

  /// LinkedIn social media platform
  ///
  /// In en, this message translates to:
  /// **'LinkedIn'**
  String get linkedin;

  /// Website field label
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Email field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Password field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Confirm password field placeholder
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get reenterPassword;

  /// Email validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// Email format validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// Password validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// Password length validation error
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// Confirm password validation error
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmPassword;

  /// Password mismatch validation error
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// App section header in settings
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get app;

  /// About menu item
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// App version display
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// Privacy policy menu item
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Help and support menu item
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// Delete account menu item
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// Delete account subtitle
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and all data'**
  String get permanentlyDeleteAccount;

  /// Close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// App description in about dialog
  ///
  /// In en, this message translates to:
  /// **'A social photo sharing app for events and moments.'**
  String get socialPhotoSharingApp;

  /// Privacy policy title
  ///
  /// In en, this message translates to:
  /// **'Zink Privacy Policy'**
  String get zinkPrivacyPolicy;

  /// Last updated text
  ///
  /// In en, this message translates to:
  /// **'Last updated: {year}'**
  String lastUpdated(String year);

  /// Privacy policy section title
  ///
  /// In en, this message translates to:
  /// **'Information We Collect'**
  String get informationWeCollect;

  /// Privacy policy section title
  ///
  /// In en, this message translates to:
  /// **'How We Use Your Information'**
  String get howWeUseInformation;

  /// Privacy policy section title
  ///
  /// In en, this message translates to:
  /// **'Information Sharing'**
  String get informationSharing;

  /// Privacy policy section title
  ///
  /// In en, this message translates to:
  /// **'Data Security'**
  String get dataSecurity;

  /// Privacy policy section title
  ///
  /// In en, this message translates to:
  /// **'Your Rights'**
  String get yourRights;

  /// Contact us section title
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// FAQ section title
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get frequentlyAskedQuestions;

  /// FAQ answer about creating account
  ///
  /// In en, this message translates to:
  /// **'How do I create an account?\nTap the sign up button and follow the prompts to create your account.'**
  String get howCreateAccount;

  /// FAQ answer about posting photo
  ///
  /// In en, this message translates to:
  /// **'How do I post a photo?\nTap the camera icon in the events section and select an active event.'**
  String get howPostPhoto;

  /// FAQ answer about liking submission
  ///
  /// In en, this message translates to:
  /// **'How do I like a submission?\nTap the heart icon below any photo submission.'**
  String get howLikeSubmission;

  /// FAQ answer about editing profile
  ///
  /// In en, this message translates to:
  /// **'How do I edit my profile?\nGo to Profile > Menu > Edit Profile.'**
  String get howEditProfile;

  /// Contact support section title
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// Support email address
  ///
  /// In en, this message translates to:
  /// **'Email: support@zinkapp.com'**
  String get emailSupport;

  /// Support response time
  ///
  /// In en, this message translates to:
  /// **'Response time: 24-48 hours'**
  String get responseTime;

  /// Urgent issues note
  ///
  /// In en, this message translates to:
  /// **'For urgent issues, please include \"URGENT\" in your subject line.'**
  String get urgentIssuesNote;

  /// App version section title
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// Platform description
  ///
  /// In en, this message translates to:
  /// **'Platform: Mobile App'**
  String get platformMobile;

  /// Report bug section title
  ///
  /// In en, this message translates to:
  /// **'Report a Bug'**
  String get reportBug;

  /// Bug report instructions
  ///
  /// In en, this message translates to:
  /// **'If you encounter any issues, please describe:\n• What you were doing when the problem occurred\n• Steps to reproduce the issue\n• Your device model and OS version'**
  String get bugReportInstructions;

  /// Delete account warning
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. This will permanently delete your account and all associated data.'**
  String get actionCannotBeUndone;

  /// Password confirmation prompt
  ///
  /// In en, this message translates to:
  /// **'Please enter your password to confirm:'**
  String get enterPasswordToConfirm;

  /// Password required validation error
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// Account deletion success message
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully'**
  String get accountDeletedSuccessfully;

  /// Incorrect password error
  ///
  /// In en, this message translates to:
  /// **'Incorrect password. Please try again.'**
  String get incorrectPassword;

  /// Too many attempts error
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Please try again later.'**
  String get tooManyFailedAttempts;

  /// Account deletion failure error
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account. Please try again.'**
  String get failedToDeleteAccount;

  /// Final confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Final Confirmation'**
  String get finalConfirmation;

  /// Final deletion warning
  ///
  /// In en, this message translates to:
  /// **'Are you absolutely sure? This action cannot be undone and will permanently delete:\n\n• Your profile and account data\n• All your posts and submissions\n• Your chat history\n• All other associated data\n\nThis action is irreversible.'**
  String get absolutelySureWarning;

  /// Final delete confirmation button
  ///
  /// In en, this message translates to:
  /// **'Yes, Delete My Account'**
  String get yesDeleteMyAccount;

  /// Event not found title
  ///
  /// In en, this message translates to:
  /// **'Event Not Found'**
  String get eventNotFound;

  /// Error loading event message
  ///
  /// In en, this message translates to:
  /// **'Error loading event'**
  String get errorLoadingEvent;

  /// Go back button text
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// Submission limit reached title
  ///
  /// In en, this message translates to:
  /// **'Submission Limit Reached'**
  String get submissionLimitReached;

  /// Submission limit reached message
  ///
  /// In en, this message translates to:
  /// **'You have used all your submissions for this event.'**
  String get usedAllSubmissions;

  /// Challenge section title
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get challenge;

  /// Event ending soon status
  ///
  /// In en, this message translates to:
  /// **'Ending soon'**
  String get endingSoon;

  /// Your photo section title
  ///
  /// In en, this message translates to:
  /// **'Your Photo'**
  String get yourPhoto;

  /// Add photo placeholder
  ///
  /// In en, this message translates to:
  /// **'Add your photo'**
  String get addYourPhoto;

  /// Submission guidelines title
  ///
  /// In en, this message translates to:
  /// **'Submission Guidelines'**
  String get submissionGuidelines;

  /// Submission guideline 1
  ///
  /// In en, this message translates to:
  /// **'Make sure your photo matches the challenge theme'**
  String get matchChallengeTheme;

  /// Submission guideline 2
  ///
  /// In en, this message translates to:
  /// **'Use good lighting and clear focus'**
  String get useGoodLighting;

  /// Submission guideline 3
  ///
  /// In en, this message translates to:
  /// **'Original photos only - no screenshots or downloaded images'**
  String get originalPhotosOnly;

  /// Camera permission denied message
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required to take photos'**
  String get cameraPermissionDenied;

  /// Photo library permission denied message
  ///
  /// In en, this message translates to:
  /// **'Photo library permission is required to select photos'**
  String get photoLibraryPermissionDenied;

  /// Failed to take photo error
  ///
  /// In en, this message translates to:
  /// **'Failed to take photo: {error}'**
  String failedToTakePhoto(String error);

  /// Failed to select photo error
  ///
  /// In en, this message translates to:
  /// **'Failed to select photo: {error}'**
  String failedToSelectPhoto(String error);

  /// No photo selected error
  ///
  /// In en, this message translates to:
  /// **'Please select a photo first'**
  String get pleaseSelectPhotoFirst;

  /// User not authenticated error
  ///
  /// In en, this message translates to:
  /// **'User not authenticated'**
  String get userNotAuthenticated;

  /// Failed to submit photo error
  ///
  /// In en, this message translates to:
  /// **'Failed to submit photo: {error}'**
  String failedToSubmitPhoto(String error);

  /// Submitting status text
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submitting;

  /// Error loading submission data
  ///
  /// In en, this message translates to:
  /// **'Error loading submission data'**
  String get errorLoadingSubmissionData;

  /// Authentication required title
  ///
  /// In en, this message translates to:
  /// **'Authentication Required'**
  String get authenticationRequired;

  /// Sign in to submit message
  ///
  /// In en, this message translates to:
  /// **'Please sign in to submit photos'**
  String get pleaseSignInToSubmit;

  /// Submission not found title
  ///
  /// In en, this message translates to:
  /// **'Submission Not Found'**
  String get submissionNotFound;

  /// Error loading submission message
  ///
  /// In en, this message translates to:
  /// **'Error loading submission'**
  String get errorLoadingSubmission;

  /// Photo title
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// Delete post title
  ///
  /// In en, this message translates to:
  /// **'Delete Post'**
  String get deletePost;

  /// Delete post confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this post? This action cannot be undone.'**
  String get sureDeletePost;

  /// Post deleted success message
  ///
  /// In en, this message translates to:
  /// **'Post deleted successfully'**
  String get postDeletedSuccessfully;

  /// Failed to delete post error
  ///
  /// In en, this message translates to:
  /// **'Failed to delete post'**
  String get failedToDeletePost;

  /// Messages screen title
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// Error loading chats message
  ///
  /// In en, this message translates to:
  /// **'Error loading chats'**
  String get errorLoadingChats;

  /// No conversations message
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversationsYet;

  /// Unknown user display name
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get unknownUser;

  /// No messages in chat
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// Failed to load user data error
  ///
  /// In en, this message translates to:
  /// **'Failed to load user data'**
  String get failedToLoadUserData;

  /// Chat deleted success message
  ///
  /// In en, this message translates to:
  /// **'Chat deleted'**
  String get chatDeleted;

  /// Delete chat button text
  ///
  /// In en, this message translates to:
  /// **'Delete Chat'**
  String get deleteChat;

  /// Just now timestamp
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// User label
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// Error loading messages
  ///
  /// In en, this message translates to:
  /// **'Error loading messages'**
  String get errorLoadingMessages;

  /// Type message placeholder
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// User not found message
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// Page not found error
  ///
  /// In en, this message translates to:
  /// **'Page not found: {location}'**
  String pageNotFound(String location);

  /// Go home button text
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get goHome;

  /// No submissions message
  ///
  /// In en, this message translates to:
  /// **'No submissions yet'**
  String get noSubmissionsYet;

  /// Be first to submit message
  ///
  /// In en, this message translates to:
  /// **'Be the first to submit a photo!'**
  String get beFirstToSubmit;

  /// Error loading submissions message
  ///
  /// In en, this message translates to:
  /// **'Error loading submissions'**
  String get errorLoadingSubmissions;

  /// Anonymous winner display name
  ///
  /// In en, this message translates to:
  /// **'Anonymous Winner'**
  String get anonymousWinner;

  /// Champion message
  ///
  /// In en, this message translates to:
  /// **'Champion of this event!'**
  String get championOfEvent;

  /// Storage test screen title
  ///
  /// In en, this message translates to:
  /// **'Storage Test'**
  String get storageTest;

  /// Test storage button text
  ///
  /// In en, this message translates to:
  /// **'Test Storage Connection'**
  String get testStorageConnection;

  /// Pick image button text
  ///
  /// In en, this message translates to:
  /// **'Pick Image & Upload'**
  String get pickImageAndUpload;

  /// Selected image label
  ///
  /// In en, this message translates to:
  /// **'Selected Image:'**
  String get selectedImage;

  /// Auth error message
  ///
  /// In en, this message translates to:
  /// **'An account already exists with a different credential.'**
  String get accountExistsWithDifferentCredential;

  /// Auth error message
  ///
  /// In en, this message translates to:
  /// **'The credential received is malformed or has expired.'**
  String get credentialMalformedOrExpired;

  /// Auth error message
  ///
  /// In en, this message translates to:
  /// **'This operation is not allowed. Please contact support.'**
  String get operationNotAllowed;

  /// Auth error message
  ///
  /// In en, this message translates to:
  /// **'This user account has been disabled.'**
  String get userAccountDisabled;

  /// Auth error message
  ///
  /// In en, this message translates to:
  /// **'No user found with this email address.'**
  String get noUserFoundWithEmail;

  /// Auth error message
  ///
  /// In en, this message translates to:
  /// **'Incorrect password. Please try again.'**
  String get incorrectPasswordTryAgain;

  /// Auth error message
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Try again later.'**
  String get tooManyRequestsTryLater;

  /// Auth error message
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get networkErrorCheckConnection;

  /// Auth error message
  ///
  /// In en, this message translates to:
  /// **'This email address is already registered. Please sign in instead.'**
  String get emailAlreadyRegistered;

  /// Auth error message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get enterValidEmailAddress;

  /// Auth error message
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Please choose a stronger password.'**
  String get passwordTooWeak;

  /// Auth error message
  ///
  /// In en, this message translates to:
  /// **'Please sign out and sign in again before retrying this request.'**
  String get signOutAndSignInAgain;

  /// Auth error message
  ///
  /// In en, this message translates to:
  /// **'The verification code is invalid. Please try again.'**
  String get verificationCodeInvalid;

  /// Auth error message
  ///
  /// In en, this message translates to:
  /// **'The verification ID is invalid. Please try again.'**
  String get verificationIdInvalid;

  /// Auth error message
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please try again.'**
  String get authenticationFailedTryAgain;

  /// Failed to load chat error
  ///
  /// In en, this message translates to:
  /// **'Failed to load chat: {error}'**
  String failedToLoadChat(String error);

  /// Failed to send message error
  ///
  /// In en, this message translates to:
  /// **'Failed to send message: {error}'**
  String failedToSendMessage(String error);

  /// Description for empty conversations
  ///
  /// In en, this message translates to:
  /// **'Start a conversation by visiting someone\'s profile'**
  String get noConversationsDescription;

  /// Start conversation prompt
  ///
  /// In en, this message translates to:
  /// **'Start the conversation!'**
  String get startConversation;

  /// Failed to delete chat error
  ///
  /// In en, this message translates to:
  /// **'Failed to delete chat: {error}'**
  String failedToDeleteChat(String error);

  /// Delete chat confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this chat? This action cannot be undone.'**
  String get sureDeleteChat;

  /// Yesterday timestamp format
  ///
  /// In en, this message translates to:
  /// **'Yesterday {time}'**
  String yesterdayAt(String time);

  /// Days ago format
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String daysAgo(int days);

  /// Hours and minutes left format
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m left'**
  String hoursLeft(int hours, int minutes);

  /// Minutes left format
  ///
  /// In en, this message translates to:
  /// **'{minutes}m left'**
  String minutesLeft(int minutes);

  /// Active status
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Ended status
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get ended;

  /// Minutes ago format
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// Hours ago format
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// Days ago short format
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgoShort(int days);

  /// Comments section title
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// Profile not set up message
  ///
  /// In en, this message translates to:
  /// **'Profile not set up yet'**
  String get profileNotSetUp;

  /// Complete profile setup prompt
  ///
  /// In en, this message translates to:
  /// **'Please complete your profile setup'**
  String get pleaseCompleteProfileSetup;

  /// Error loading profile message
  ///
  /// In en, this message translates to:
  /// **'Error loading profile: {error}'**
  String errorLoadingProfile(String error);

  /// Spotlight text
  ///
  /// In en, this message translates to:
  /// **'SPOTLIGHT'**
  String get spotlight;

  /// Past tasks header
  ///
  /// In en, this message translates to:
  /// **'Past Tasks'**
  String get pastTasks;

  /// No active tasks message
  ///
  /// In en, this message translates to:
  /// **'No active tasks right now'**
  String get noActiveTasksRight;

  /// Tasks loading message
  ///
  /// In en, this message translates to:
  /// **'Tasks loading...'**
  String get tasksLoading;

  /// Error loading tasks message
  ///
  /// In en, this message translates to:
  /// **'Error occurred while loading tasks'**
  String get errorLoadingTasks;

  /// No past tasks message
  ///
  /// In en, this message translates to:
  /// **'No past tasks yet'**
  String get noPastTasksYet;

  /// Notification permission request message
  ///
  /// In en, this message translates to:
  /// **'Allow permission to receive notifications about new tasks and updates.'**
  String get notificationPermissionMessage;

  /// Not now button text
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get notNow;

  /// Allow permission button text
  ///
  /// In en, this message translates to:
  /// **'Allow Permission'**
  String get allowPermission;

  /// Notifications header
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Permission granted success message
  ///
  /// In en, this message translates to:
  /// **'Notification permission granted!'**
  String get notificationPermissionGranted;

  /// Permission denied message
  ///
  /// In en, this message translates to:
  /// **'Notification permission denied. You can grant permission from settings.'**
  String get notificationPermissionDenied;

  /// Today date text
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Days left format
  ///
  /// In en, this message translates to:
  /// **'{days}d left'**
  String daysLeft(int days);

  /// Days and hours left format
  ///
  /// In en, this message translates to:
  /// **'{days}d {hours}h left'**
  String daysAndHoursLeft(int days, int hours);

  /// Empty state message for notifications
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// Description for empty notifications state
  ///
  /// In en, this message translates to:
  /// **'You\'ll receive notifications about likes and comments here'**
  String get notificationsWillAppearHere;

  /// Error message when notifications fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading notifications'**
  String get errorLoadingNotifications;

  /// Success message when all notifications are marked as read
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read'**
  String get allNotificationsMarkedAsRead;

  /// Error message when marking notifications as read fails
  ///
  /// In en, this message translates to:
  /// **'Failed to mark notifications as read'**
  String get failedToMarkNotificationsAsRead;

  /// Error message when deleting a notification fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete notification'**
  String get failedToDeleteNotification;

  /// Minutes ago short format
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgoShort(int minutes);

  /// Hours ago short format
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgoShort(int hours);

  /// Yesterday text
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Weeks ago short format
  ///
  /// In en, this message translates to:
  /// **'{weeks}w ago'**
  String weeksAgoShort(int weeks);

  /// Timeline tab label
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// Events tab label
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// Empty timeline message
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get noPostsYet;

  /// Empty timeline subtitle
  ///
  /// In en, this message translates to:
  /// **'Check back later for new posts'**
  String get checkBackLater;

  /// Timeline error message
  ///
  /// In en, this message translates to:
  /// **'Error loading timeline'**
  String get errorLoadingTimeline;

  /// Unknown user fallback
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;
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
