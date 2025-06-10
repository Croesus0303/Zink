// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Zink';

  @override
  String get appTagline => 'AI-Powered Photo Challenges';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get signInOrSignUp => 'Sign in or Sign up';

  @override
  String get newUserPrompt => 'New to Zink? Sign up with your Google account';

  @override
  String get existingUserPrompt =>
      'Already have an account? Sign in to continue';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get signOut => 'Sign Out';

  @override
  String welcome(String name) {
    return 'Welcome $name!';
  }

  @override
  String get home => 'Home';

  @override
  String get noActiveChallenges => 'No active challenges right now';

  @override
  String get activeChallenge => 'Active Challenge';

  @override
  String get pastChallenges => 'Past Challenges';

  @override
  String timeRemaining(String time) {
    return 'Time Remaining: $time';
  }

  @override
  String get submitPhoto => 'Submit Photo';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get submissions => 'Submissions';

  @override
  String likes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count likes',
      one: '1 like',
      zero: 'No likes',
    );
    return '$_temp0';
  }

  @override
  String comments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comments',
      one: '1 comment',
      zero: 'No comments',
    );
    return '$_temp0';
  }

  @override
  String get addComment => 'Add a comment...';

  @override
  String get profile => 'Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get username => 'Username';

  @override
  String get socialLinks => 'Social Links';

  @override
  String get myChallenges => 'My Challenges';

  @override
  String totalSubmissions(int count) {
    return '$count Submissions';
  }

  @override
  String get mostPopular => 'Most Popular';

  @override
  String get newest => 'Newest';

  @override
  String get oldest => 'Oldest';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get newChallengeAvailable => 'New challenge available!';

  @override
  String get challengeEndingSoon => 'Challenge ending soon!';

  @override
  String get submissionSuccessful => 'Photo submitted successfully!';

  @override
  String get submit => 'Submit';

  @override
  String get welcomeToZink => 'Welcome to Zink!';

  @override
  String get onboardingSubtitle => 'Let\'s set up your profile to get started';

  @override
  String get chooseUsername => 'Choose a username';

  @override
  String get enterUsername => 'Enter your username';

  @override
  String get whatsYourAge => 'What\'s your age?';

  @override
  String get enterAge => 'Enter your age';

  @override
  String get completeSetup => 'Complete Setup';

  @override
  String get usernameRequired => 'Username is required';

  @override
  String get usernameTooShort => 'Username must be at least 3 characters';

  @override
  String get usernameTooLong => 'Username must be less than 20 characters';

  @override
  String get usernameInvalidChars =>
      'Username can only contain letters, numbers, and underscores';

  @override
  String get ageRequired => 'Age is required';

  @override
  String get enterValidNumber => 'Please enter a valid number';

  @override
  String get ageTooYoung => 'You must be at least 13 years old';

  @override
  String get enterValidAge => 'Please enter a valid age';

  @override
  String get privacyNote =>
      'By continuing, you agree to our Terms of Service and Privacy Policy. Your information is secure and will only be used to enhance your experience.';

  @override
  String get profilePicture => 'Profile Picture';

  @override
  String get changeProfilePicture => 'Change Profile Picture';

  @override
  String get displayName => 'Display Name';

  @override
  String get basicInformation => 'Basic Information';

  @override
  String get socialMediaLinks => 'Social Media Links';

  @override
  String get instagram => 'Instagram';

  @override
  String get twitter => 'Twitter';

  @override
  String get facebook => 'Facebook';

  @override
  String get linkedin => 'LinkedIn';

  @override
  String get website => 'Website';
}
