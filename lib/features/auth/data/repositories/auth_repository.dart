import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:io';
import '../../../../core/utils/logger.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseMessaging _messaging;

  AuthRepository({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required FirebaseMessaging messaging,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn,
        _firestore = firestore,
        _storage = storage,
        _messaging = messaging;

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
          // Update FCM token for existing users
          await updateFCMToken(userCredential.user!.uid);
        }
      }

      return userCredential;
    } catch (e, stackTrace) {
      AppLogger.e('Google Sign In failed', e, stackTrace);
      rethrow;
    }
  }

  Future<UserCredential?> signInWithApple() async {
    // Check if Sign in with Apple is available
    if (!Platform.isIOS) {
      throw Exception('Sign in with Apple is only available on iOS');
    }

    if (!await SignInWithApple.isAvailable()) {
      throw Exception('Sign in with Apple is not available on this device');
    }

    try {
      AppLogger.i('Starting Apple Sign In');

      // Request Apple ID credentials
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create an OAuthCredential from the Apple credentials
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with the Apple credentials
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(oauthCredential);

      AppLogger.i(
          'Apple Sign In successful for user: ${userCredential.user?.uid}');

      // Check if this is a new user (first-time sign-up)
      if (userCredential.user != null) {
        final userDoc = await _firestore
            .collection(UserModel.collectionPath)
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          AppLogger.i('New Apple user detected, will require onboarding');
          // Update the user's display name if provided by Apple
          if (appleCredential.givenName != null ||
              appleCredential.familyName != null) {
            final displayName =
                '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                    .trim();
            if (displayName.isNotEmpty) {
              await userCredential.user!.updateDisplayName(displayName);
            }
          }
        } else {
          AppLogger.i('Existing Apple user signed in');
          // Update FCM token for existing users
          await updateFCMToken(userCredential.user!.uid);
        }
      }

      return userCredential;
    } catch (e, stackTrace) {
      AppLogger.e('Apple Sign In failed', e, stackTrace);
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

      // Get FCM token
      final fcmToken = await _messaging.getToken();

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
        if (fcmToken != null) 'fcmToken': fcmToken,
      };

      await _firestore
          .collection(UserModel.collectionPath)
          .doc(user.uid)
          .set(userData);

      AppLogger.i(
          'User onboarding completed and document created for user: ${user.uid}');
      if (fcmToken != null) {
        AppLogger.i('FCM token stored during onboarding: ${fcmToken.substring(0, 20)}...');
      }
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
          // Update FCM token for existing users
          await updateFCMToken(userCredential.user!.uid);
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

  Future<void> updateUserProfile({
    Map<String, String>? socialLinks,
    File? profileImage,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.i('Updating user profile for user: ${user.uid}');

      // Prepare update data
      final updateData = <String, dynamic>{};

      if (socialLinks != null) {
        updateData['socialLinks'] = socialLinks;
      }

      // Handle profile image upload if provided
      if (profileImage != null) {
        AppLogger.i('Starting profile image upload for user: ${user.uid}');
        final imageUrl = await _uploadProfileImage(profileImage, user.uid);
        updateData['photoURL'] = imageUrl;

        // Also update Firebase Auth profile photo
        await user.updatePhotoURL(imageUrl);
        AppLogger.i('Profile image upload completed successfully');
      }

      // Update Firestore document if there's data to update
      if (updateData.isNotEmpty) {
        await _firestore
            .collection(UserModel.collectionPath)
            .doc(user.uid)
            .update(updateData);
      }

      AppLogger.i('User profile updated successfully');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to update user profile', e, stackTrace);
      rethrow;
    }
  }

  Future<String> _uploadProfileImage(File imageFile, String userId) async {
    try {
      AppLogger.i(
          'Starting image upload to Firebase Storage for user: $userId');
      AppLogger.i('Image file path: ${imageFile.path}');
      AppLogger.i('Image file exists: ${imageFile.existsSync()}');

      // Create a reference to the location where we want to upload the file
      final storageRef = _storage.ref().child('profile_images/$userId.jpg');
      AppLogger.i('Storage reference created: ${storageRef.fullPath}');

      // Upload the file
      AppLogger.i('Starting file upload...');
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      AppLogger.i('Waiting for upload to complete...');
      final snapshot = await uploadTask;
      AppLogger.i('Upload completed, getting download URL...');

      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      AppLogger.i('Profile image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e, stackTrace) {
      AppLogger.e('Failed to upload profile image', e, stackTrace);
      rethrow;
    }
  }

  // Account Deletion Methods
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      AppLogger.i('Starting account deletion for user: ${user.uid}');

      // Delete user data from Firestore
      await _deleteUserData(user.uid);

      // Delete user's profile image from Storage
      await _deleteUserStorage(user.uid);

      // Finally, delete the Firebase Auth account
      await user.delete();

      AppLogger.i('Account deletion completed successfully');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to delete account', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _deleteUserData(String userId) async {
    try {
      AppLogger.i('Deleting user data from Firestore for user: $userId');

      // Delete user document
      await _firestore
          .collection(UserModel.collectionPath)
          .doc(userId)
          .delete();

      // This would require querying collections where the user has data
      // For now, we're just deleting the main user document

      AppLogger.i('User data deleted from Firestore');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to delete user data from Firestore', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _deleteUserStorage(String userId) async {
    try {
      AppLogger.i('Deleting user storage files for user: $userId');

      // Delete profile image
      final profileImageRef =
          _storage.ref().child('profile_images/$userId.jpg');
      try {
        await profileImageRef.delete();
        AppLogger.i('Profile image deleted successfully');
      } catch (e) {
        AppLogger.w('Profile image not found or already deleted: $e');
      }

      // This could include submission images, etc.

      AppLogger.i('User storage files deletion completed');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to delete user storage files', e, stackTrace);
      // Don't rethrow here as storage deletion is not critical
    }
  }

  Future<void> updateFCMToken(String userId) async {
    try {
      AppLogger.i('Updating FCM token for user: $userId');

      // Get FCM token
      final fcmToken = await _messaging.getToken();

      if (fcmToken == null) {
        AppLogger.w('FCM token is null, skipping update');
        return;
      }

      // Update the user document with FCM token
      await _firestore
          .collection(UserModel.collectionPath)
          .doc(userId)
          .set({
        'fcmToken': fcmToken,
      }, SetOptions(merge: true));

      AppLogger.i('FCM token updated successfully: ${fcmToken.substring(0, 20)}...');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to update FCM token', e, stackTrace);
      // Don't rethrow - FCM token update failure shouldn't block login
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
    storage: FirebaseStorage.instance,
    messaging: FirebaseMessaging.instance,
  );
});
