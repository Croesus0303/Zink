import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../data/repositories/auth_repository.dart';
import '../data/models/user_model.dart';
import '../../../core/utils/logger.dart';

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
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.getCurrentUserData();
});

// Authentication service provider
final authServiceProvider = Provider<AuthService>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthService(authRepository);
});


class AuthService {
  final AuthRepository _authRepository;

  AuthService(this._authRepository);

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
      return AuthResult.failure('An unexpected error occurred. Please try again.');
    }
  }


  Future<void> signOut() async {
    await _authRepository.signOut();
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
        return 'No user found with this credential.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
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