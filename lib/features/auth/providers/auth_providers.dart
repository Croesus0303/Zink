import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/repositories/auth_repository.dart';
import '../data/models/user_model.dart';
import '../../../core/utils/logger.dart';
import '../../events/providers/events_providers.dart';
import '../../../core/services/notification_service.dart';

// Auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.currentUser;
});

// Current user data provider (Firestore document)
final currentUserDataProvider = FutureProvider<UserModel?>((ref) {
  // Watch the auth state to ensure this provider refreshes when user changes
  final authState = ref.watch(authStateProvider);
  final authRepository = ref.watch(authRepositoryProvider);

  // Return null if not authenticated
  return authState.when(
    data: (user) {
      if (user == null) return Future.value(null);
      return authRepository.getCurrentUserData();
    },
    loading: () => Future.value(null),
    error: (_, __) => Future.value(null),
  );
});

// Authentication service provider
final authServiceProvider = Provider<AuthService>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthService(authRepository, ref);
});

class AuthService {
  final AuthRepository _authRepository;
  final Ref _ref;

  AuthService(this._authRepository, this._ref);

  Future<AuthResult> signInWithGoogle() async {
    try {
      final result = await _authRepository.signInWithGoogle();
      if (result != null) {
        return AuthResult.success();
      } else {
        return AuthResult.cancelled();
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Firebase Auth Exception during Google Sign In', e);
      return AuthResult.failure(_getErrorMessage(e));
    } catch (e) {
      AppLogger.e('Unexpected error during Google Sign In', e);
      return AuthResult.failure(
          'An unexpected error occurred. Please try again.');
    }
  }

  Future<AuthResult> signInWithApple() async {
    try {
      final result = await _authRepository.signInWithApple();
      if (result != null) {
        return AuthResult.success();
      } else {
        return AuthResult.cancelled();
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Firebase Auth Exception during Apple Sign In', e);
      return AuthResult.failure(_getErrorMessage(e));
    } catch (e) {
      AppLogger.e('Unexpected error during Apple Sign In', e);
      return AuthResult.failure(e.toString());
    }
  }

  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result != null) {
        return AuthResult.success();
      } else {
        return AuthResult.failure('Sign in failed');
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Firebase Auth Exception during email/password sign in', e);
      return AuthResult.failure(_getErrorMessage(e));
    } catch (e) {
      AppLogger.e('Unexpected error during email/password sign in', e);
      return AuthResult.failure(
          'An unexpected error occurred. Please try again.');
    }
  }

  Future<AuthResult> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _authRepository.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result != null) {
        return AuthResult.success();
      } else {
        return AuthResult.failure('Sign up failed');
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Firebase Auth Exception during email/password sign up', e);
      return AuthResult.failure(_getErrorMessage(e));
    } catch (e) {
      AppLogger.e('Unexpected error during email/password sign up', e);
      return AuthResult.failure(
          'An unexpected error occurred. Please try again.');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _authRepository.sendPasswordResetEmail(email);
  }

  Future<void> signOut() async {
    try {
      AppLogger.i('Starting comprehensive sign out process');

      // Sign out from Firebase and Google first
      await _authRepository.signOut();

      // Invalidate all auth-related providers to clear cached data
      _ref.invalidate(authStateProvider);
      _ref.invalidate(currentUserProvider);
      _ref.invalidate(currentUserDataProvider);

      // Invalidate user-specific data providers
      _ref.invalidate(submissionFilterProvider);
      _ref.invalidate(userSubmissionsProvider);
      _ref.invalidate(userDataProvider);
      _ref.invalidate(userSubmissionsFromUserCollectionProvider);
      _ref.invalidate(userLikedSubmissionIdsProvider);
      _ref.invalidate(userLikeCountFromUserCollectionProvider);
      _ref.invalidate(userLikedSubmissionsProvider);
      _ref.invalidate(userSubmissionCountProvider);
      _ref.invalidate(userLikeCountProvider);
      _ref.invalidate(userCommentCountProvider);
      _ref.invalidate(likeStatusProvider);

      // Invalidate notification providers
      _ref.invalidate(fcmTokenProvider);
      _ref.invalidate(notificationSettingsProvider);

      // Invalidate general data providers that may have user context
      _ref.invalidate(submissionsStreamProvider);
      _ref.invalidate(submissionsProvider);
      _ref.invalidate(commentsStreamProvider);
      _ref.invalidate(commentsProvider);
      _ref.invalidate(likesStreamProvider);
      _ref.invalidate(filteredSubmissionsProvider);
      _ref.invalidate(submissionProvider);
      _ref.invalidate(eventsStreamProvider);
      _ref.invalidate(eventsProvider);
      _ref.invalidate(activeEventProvider);
      _ref.invalidate(pastEventsProvider);
      _ref.invalidate(likeCountProvider);
      _ref.invalidate(commentCountProvider);
      _ref.invalidate(submissionCountProvider);

      AppLogger.i('All user-specific providers invalidated after sign out');
      AppLogger.i('Sign out process completed successfully');
    } catch (e, stackTrace) {
      AppLogger.e('Error during comprehensive sign out', e, stackTrace);
      rethrow;
    }
  }

  Future<void> reauthenticateWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _authRepository.reauthenticateWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      if (e is FirebaseAuthException) {
        throw Exception(_getErrorMessage(e));
      }
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      AppLogger.i('Starting account deletion process');
      
      // Delete account using repository
      await _authRepository.deleteAccount();
      
      // Invalidate all providers after account deletion
      _ref.invalidate(authStateProvider);
      _ref.invalidate(currentUserProvider);
      _ref.invalidate(currentUserDataProvider);
      
      AppLogger.i('Account deletion completed successfully');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to delete account', e, stackTrace);
      if (e is FirebaseAuthException) {
        throw Exception(_getErrorMessage(e));
      }
      rethrow;
    }
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different credential.';
      case 'invalid-credential':
        return 'The credential received is malformed or has expired.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'email-already-in-use':
        return 'This email address is already registered. Please sign in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'requires-recent-login':
        return 'Please sign out and sign in again before retrying this request.';
      case 'invalid-verification-code':
        return 'The verification code is invalid. Please try again.';
      case 'invalid-verification-id':
        return 'The verification ID is invalid. Please try again.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

class AuthResult {
  final bool isSuccess;
  final bool isCancelled;
  final String? errorMessage;

  AuthResult._({
    required this.isSuccess,
    required this.isCancelled,
    this.errorMessage,
  });

  factory AuthResult.success() => AuthResult._(
        isSuccess: true,
        isCancelled: false,
      );

  factory AuthResult.cancelled() => AuthResult._(
        isSuccess: false,
        isCancelled: true,
      );

  factory AuthResult.failure(String message) => AuthResult._(
        isSuccess: false,
        isCancelled: false,
        errorMessage: message,
      );
}
