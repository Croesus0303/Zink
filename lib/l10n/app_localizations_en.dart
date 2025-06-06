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
}
