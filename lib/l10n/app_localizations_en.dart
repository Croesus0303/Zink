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
  String get signOutConfirmation => 'Are you sure you want to sign out?';

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
  String commentCount(int count) {
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

  @override
  String get settings => 'Settings';

  @override
  String get email => 'Email';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get password => 'Password';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get reenterPassword => 'Re-enter your password';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get pleaseConfirmPassword => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get app => 'App';

  @override
  String get about => 'About';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get helpAndSupport => 'Help & Support';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get permanentlyDeleteAccount =>
      'Permanently delete your account and all data';

  @override
  String get close => 'Close';

  @override
  String get socialPhotoSharingApp =>
      'A social photo sharing app for events and moments.';

  @override
  String get zinkPrivacyPolicy => 'Zink Privacy Policy';

  @override
  String lastUpdated(String year) {
    return 'Last updated: $year';
  }

  @override
  String get informationWeCollect => 'Information We Collect';

  @override
  String get howWeUseInformation => 'How We Use Your Information';

  @override
  String get informationSharing => 'Information Sharing';

  @override
  String get dataSecurity => 'Data Security';

  @override
  String get yourRights => 'Your Rights';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get frequentlyAskedQuestions => 'Frequently Asked Questions';

  @override
  String get howCreateAccount =>
      'How do I create an account?\nTap the sign up button and follow the prompts to create your account.';

  @override
  String get howPostPhoto =>
      'How do I post a photo?\nTap the camera icon in the events section and select an active event.';

  @override
  String get howLikeSubmission =>
      'How do I like a submission?\nTap the heart icon below any photo submission.';

  @override
  String get howEditProfile =>
      'How do I edit my profile?\nGo to Profile > Menu > Edit Profile.';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get emailSupport => 'Email: support@zinkapp.com';

  @override
  String get responseTime => 'Response time: 24-48 hours';

  @override
  String get urgentIssuesNote =>
      'For urgent issues, please include \"URGENT\" in your subject line.';

  @override
  String get appVersion => 'App Version';

  @override
  String get platformMobile => 'Platform: Mobile App';

  @override
  String get reportBug => 'Report a Bug';

  @override
  String get bugReportInstructions =>
      'If you encounter any issues, please describe:\n• What you were doing when the problem occurred\n• Steps to reproduce the issue\n• Your device model and OS version';

  @override
  String get actionCannotBeUndone =>
      'This action cannot be undone. This will permanently delete your account and all associated data.';

  @override
  String get enterPasswordToConfirm => 'Please enter your password to confirm:';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get accountDeletedSuccessfully => 'Account deleted successfully';

  @override
  String get incorrectPassword => 'Incorrect password. Please try again.';

  @override
  String get tooManyFailedAttempts =>
      'Too many failed attempts. Please try again later.';

  @override
  String get failedToDeleteAccount =>
      'Failed to delete account. Please try again.';

  @override
  String get finalConfirmation => 'Final Confirmation';

  @override
  String get absolutelySureWarning =>
      'Are you absolutely sure? This action cannot be undone and will permanently delete:\n\n• Your profile and account data\n• All your posts and submissions\n• Your chat history\n• All other associated data\n\nThis action is irreversible.';

  @override
  String get yesDeleteMyAccount => 'Yes, Delete My Account';

  @override
  String get eventNotFound => 'Event Not Found';

  @override
  String get errorLoadingEvent => 'Error loading event';

  @override
  String get goBack => 'Go Back';

  @override
  String get submissionLimitReached => 'Submission Limit Reached';

  @override
  String get usedAllSubmissions =>
      'You have used all your submissions for this event.';

  @override
  String get challenge => 'Challenge';

  @override
  String get endingSoon => 'Ending soon';

  @override
  String get yourPhoto => 'Your Photo';

  @override
  String get addYourPhoto => 'Add your photo';

  @override
  String get submissionGuidelines => 'Submission Guidelines';

  @override
  String get matchChallengeTheme =>
      'Make sure your photo matches the challenge theme';

  @override
  String get useGoodLighting => 'Use good lighting and clear focus';

  @override
  String get originalPhotosOnly =>
      'Original photos only - no screenshots or downloaded images';

  @override
  String get cameraPermissionDenied =>
      'Camera permission is required to take photos';

  @override
  String get photoLibraryPermissionDenied =>
      'Photo library permission is required to select photos';

  @override
  String failedToTakePhoto(String error) {
    return 'Failed to take photo: $error';
  }

  @override
  String failedToSelectPhoto(String error) {
    return 'Failed to select photo: $error';
  }

  @override
  String get pleaseSelectPhotoFirst => 'Please select a photo first';

  @override
  String get userNotAuthenticated => 'User not authenticated';

  @override
  String failedToSubmitPhoto(String error) {
    return 'Failed to submit photo: $error';
  }

  @override
  String get submitting => 'Submitting...';

  @override
  String get errorLoadingSubmissionData => 'Error loading submission data';

  @override
  String get authenticationRequired => 'Authentication Required';

  @override
  String get pleaseSignInToSubmit => 'Please sign in to submit photos';

  @override
  String get submissionNotFound => 'Submission Not Found';

  @override
  String get errorLoadingSubmission => 'Error loading submission';

  @override
  String get photo => 'Photo';

  @override
  String get deletePost => 'Delete Post';

  @override
  String get sureDeletePost =>
      'Are you sure you want to delete this post? This action cannot be undone.';

  @override
  String get postDeletedSuccessfully => 'Post deleted successfully';

  @override
  String get failedToDeletePost => 'Failed to delete post';

  @override
  String get messages => 'Messages';

  @override
  String get errorLoadingChats => 'Error loading chats';

  @override
  String get noConversationsYet => 'No conversations yet';

  @override
  String get unknownUser => 'Unknown User';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get failedToLoadUserData => 'Failed to load user data';

  @override
  String get chatDeleted => 'Chat deleted';

  @override
  String get deleteChat => 'Delete Chat';

  @override
  String get justNow => 'Just now';

  @override
  String get user => 'User';

  @override
  String get errorLoadingMessages => 'Error loading messages';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get userNotFound => 'User not found';

  @override
  String pageNotFound(String location) {
    return 'Page not found: $location';
  }

  @override
  String get goHome => 'Go Home';

  @override
  String get noSubmissionsYet => 'No submissions yet';

  @override
  String get beFirstToSubmit => 'Be the first to submit a photo!';

  @override
  String get errorLoadingSubmissions => 'Error loading submissions';

  @override
  String get anonymousWinner => 'Anonymous Winner';

  @override
  String get championOfEvent => 'Champion of this event!';

  @override
  String get storageTest => 'Storage Test';

  @override
  String get testStorageConnection => 'Test Storage Connection';

  @override
  String get pickImageAndUpload => 'Pick Image & Upload';

  @override
  String get selectedImage => 'Selected Image:';

  @override
  String get accountExistsWithDifferentCredential =>
      'An account already exists with a different credential.';

  @override
  String get credentialMalformedOrExpired =>
      'The credential received is malformed or has expired.';

  @override
  String get operationNotAllowed =>
      'This operation is not allowed. Please contact support.';

  @override
  String get userAccountDisabled => 'This user account has been disabled.';

  @override
  String get noUserFoundWithEmail => 'No user found with this email address.';

  @override
  String get incorrectPasswordTryAgain =>
      'Incorrect password. Please try again.';

  @override
  String get tooManyRequestsTryLater => 'Too many requests. Try again later.';

  @override
  String get networkErrorCheckConnection =>
      'Network error. Please check your connection.';

  @override
  String get emailAlreadyRegistered =>
      'This email address is already registered. Please sign in instead.';

  @override
  String get enterValidEmailAddress => 'Please enter a valid email address.';

  @override
  String get passwordTooWeak =>
      'Password is too weak. Please choose a stronger password.';

  @override
  String get signOutAndSignInAgain =>
      'Please sign out and sign in again before retrying this request.';

  @override
  String get verificationCodeInvalid =>
      'The verification code is invalid. Please try again.';

  @override
  String get verificationIdInvalid =>
      'The verification ID is invalid. Please try again.';

  @override
  String get authenticationFailedTryAgain =>
      'Authentication failed. Please try again.';

  @override
  String failedToLoadChat(String error) {
    return 'Failed to load chat: $error';
  }

  @override
  String failedToSendMessage(String error) {
    return 'Failed to send message: $error';
  }

  @override
  String get noConversationsDescription =>
      'Start a conversation by visiting someone\'s profile';

  @override
  String get startConversation => 'Start the conversation!';

  @override
  String failedToDeleteChat(String error) {
    return 'Failed to delete chat: $error';
  }

  @override
  String get sureDeleteChat =>
      'Are you sure you want to delete this chat? This action cannot be undone.';

  @override
  String yesterdayAt(String time) {
    return 'Yesterday $time';
  }

  @override
  String daysAgo(int days) {
    return '$days days ago';
  }

  @override
  String hoursLeft(int hours, int minutes) {
    return '${hours}h ${minutes}m left';
  }

  @override
  String minutesLeft(int minutes) {
    return '${minutes}m left';
  }

  @override
  String get active => 'Active';

  @override
  String get ended => 'Ended';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String daysAgoShort(int days) {
    return '${days}d ago';
  }

  @override
  String get comments => 'Comments';

  @override
  String get profileNotSetUp => 'Profile not set up yet';

  @override
  String get pleaseCompleteProfileSetup => 'Please complete your profile setup';

  @override
  String errorLoadingProfile(String error) {
    return 'Error loading profile: $error';
  }

  @override
  String get spotlight => 'SPOTLIGHT';

  @override
  String get pastTasks => 'Past Tasks';

  @override
  String get noActiveTasksRight => 'No active tasks right now';

  @override
  String get tasksLoading => 'Tasks loading...';

  @override
  String get errorLoadingTasks => 'Error occurred while loading tasks';

  @override
  String get noPastTasksYet => 'No past tasks yet';

  @override
  String get notificationPermissionMessage =>
      'Allow permission to receive notifications about new tasks and updates.';

  @override
  String get notNow => 'Not Now';

  @override
  String get allowPermission => 'Allow Permission';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationPermissionGranted =>
      'Notification permission granted!';

  @override
  String get notificationPermissionDenied =>
      'Notification permission denied. You can grant permission from settings.';

  @override
  String get today => 'Today';

  @override
  String daysLeft(int days) {
    return '${days}d left';
  }

  @override
  String daysAndHoursLeft(int days, int hours) {
    return '${days}d ${hours}h left';
  }

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get notificationsWillAppearHere =>
      'You\'ll receive notifications about likes and comments here';

  @override
  String get errorLoadingNotifications => 'Error loading notifications';

  @override
  String get allNotificationsMarkedAsRead => 'All notifications marked as read';

  @override
  String get failedToMarkNotificationsAsRead =>
      'Failed to mark notifications as read';

  @override
  String get failedToDeleteNotification => 'Failed to delete notification';

  @override
  String minutesAgoShort(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgoShort(int hours) {
    return '${hours}h ago';
  }

  @override
  String get yesterday => 'Yesterday';

  @override
  String weeksAgoShort(int weeks) {
    return '${weeks}w ago';
  }

  @override
  String get timeline => 'Timeline';

  @override
  String get events => 'Events';

  @override
  String get noPostsYet => 'No posts yet';

  @override
  String get checkBackLater => 'Check back later for new posts';

  @override
  String get errorLoadingTimeline => 'Error loading timeline';

  @override
  String get unknown => 'Unknown';
}
