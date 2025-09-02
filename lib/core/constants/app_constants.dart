class AppConstants {
  // App Info
  static const String appName = 'Zink';
  static const String appVersion = '1.0.0';

  // API Endpoints
  static const String baseUrl = 'https://api.zink.app';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String eventsCollection = 'events';
  static const String submissionsCollection = 'submissions';
  static const String commentsCollection = 'comments';
  static const String likesCollection = 'likes';

  // Time Constants
  static const int challengeDurationHours = 2;
  static const int notificationIntervalHours = 6;

  // Pagination
  static const int pageSize = 20;

  // Image Upload
  static const int maxImageSizeMB = 10;
  static const int imageQuality = 85;
}
