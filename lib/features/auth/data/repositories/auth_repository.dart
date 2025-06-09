import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/utils/logger.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  AuthRepository({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
    required FirebaseFirestore firestore,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn,
        _firestore = firestore;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      AppLogger.i('Starting Google Sign In');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        AppLogger.w('Google Sign In cancelled by user');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      AppLogger.i(
          'Google Sign In successful for user: ${userCredential.user?.uid}');

      // Check if this is a new user (first-time sign-up)
      if (userCredential.user != null) {
        final userDoc = await _firestore
            .collection(UserModel.collectionPath)
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          AppLogger.i('New user detected, will require onboarding');
          // Don't create document here - let onboarding handle it
        } else {
          AppLogger.i('Existing user signed in');
        }
      }

      return userCredential;
    } catch (e, stackTrace) {
      AppLogger.e('Google Sign In failed', e, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      AppLogger.i('Starting sign out');

      // Sign out from all authentication providers
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);

      // Also disconnect from Google to clear cached credentials
      // Catch disconnect errors as they're not critical for sign out
      try {
        await _googleSignIn.disconnect();
        AppLogger.i('Google disconnect successful');
      } catch (disconnectError) {
        AppLogger.w(
            'Google disconnect failed (non-critical): $disconnectError');
        // Continue with sign out even if disconnect fails
      }

      AppLogger.i('Sign out completed successfully');
    } catch (e, stackTrace) {
      AppLogger.e('Sign out failed', e, stackTrace);
      rethrow;
    }
  }

  Future<UserModel?> getCurrentUserData() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final userDoc = await _firestore
          .collection(UserModel.collectionPath)
          .doc(user.uid)
          .get();
      if (!userDoc.exists) return null;

      return UserModel.fromFirestore(userDoc);
    } catch (e, stackTrace) {
      AppLogger.e('Failed to get current user data', e, stackTrace);
      return null;
    }
  }

  Future<void> completeUserOnboarding({
    required String username,
    required int age,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Check if username is already taken
      final usernameQuery = await _firestore
          .collection(UserModel.collectionPath)
          .where('username', isEqualTo: username)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        throw Exception('Username is already taken');
      }

      // Create the complete user document
      final userData = {
        'uid': user.uid,
        'username': username,
        'age': age,
        'createdAt': FieldValue.serverTimestamp(),
        'displayName':
            user.displayName ?? user.email?.split('@').first ?? 'User',
        'photoURL': user.photoURL,
        'socialLinks': {},
        'isOnboardingComplete': true,
      };

      await _firestore
          .collection(UserModel.collectionPath)
          .doc(user.uid)
          .set(userData);

      AppLogger.i(
          'User onboarding completed and document created for user: ${user.uid}');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to complete user onboarding', e, stackTrace);
      rethrow;
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
    try {
      final query = await _firestore
          .collection(UserModel.collectionPath)
          .where('username', isEqualTo: username)
          .get();

      return query.docs.isEmpty;
    } catch (e, stackTrace) {
      AppLogger.e('Failed to check username availability', e, stackTrace);
      return false;
    }
  }

  Future<UserModel?> getUserData(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(UserModel.collectionPath)
          .doc(userId)
          .get();

      if (!userDoc.exists) return null;

      return UserModel.fromFirestore(userDoc);
    } catch (e, stackTrace) {
      AppLogger.e('Failed to get user data for $userId', e, stackTrace);
      return null;
    }
  }

  // Email/Password Authentication Methods
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.i('Starting email/password sign in for email: $email');

      final UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      AppLogger.i(
          'Email/password sign in successful for user: ${userCredential.user?.uid}');

      // Check if user document exists
      if (userCredential.user != null) {
        final userDoc = await _firestore
            .collection(UserModel.collectionPath)
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          AppLogger.i('User document not found, will require onboarding');
        } else {
          AppLogger.i('Existing user signed in');
        }
      }

      return userCredential;
    } catch (e, stackTrace) {
      AppLogger.e('Email/password sign in failed', e, stackTrace);
      rethrow;
    }
  }

  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.i('Starting email/password sign up for email: $email');

      final UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      AppLogger.i(
          'Email/password sign up successful for user: ${userCredential.user?.uid}');

      // New user created, will require onboarding
      if (userCredential.user != null) {
        AppLogger.i('New user created, will require onboarding');
      }

      return userCredential;
    } catch (e, stackTrace) {
      AppLogger.e('Email/password sign up failed', e, stackTrace);
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      AppLogger.i('Sending password reset email to: $email');
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      AppLogger.i('Password reset email sent successfully');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to send password reset email', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.i('Updating password for user: ${user.uid}');
      await user.updatePassword(newPassword);
      AppLogger.i('Password updated successfully');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to update password', e, stackTrace);
      rethrow;
    }
  }

  Future<void> reauthenticateWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      final credential =
          EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(credential);
      AppLogger.i('Re-authentication successful');
    } catch (e, stackTrace) {
      AppLogger.e('Re-authentication failed', e, stackTrace);
      rethrow;
    }
  }
}

// Providers
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    firebaseAuth: FirebaseAuth.instance,
    googleSignIn: ref.watch(googleSignInProvider),
    firestore: FirebaseFirestore.instance,
  );
});
