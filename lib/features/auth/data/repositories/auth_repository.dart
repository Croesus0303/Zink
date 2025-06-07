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

      // Create or update user document in Firestore
      if (userCredential.user != null) {
        await _createOrUpdateUserDocument(userCredential.user!);
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

      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);

      AppLogger.i('Sign out successful');
    } catch (e, stackTrace) {
      AppLogger.e('Sign out failed', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _createOrUpdateUserDocument(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final userSnapshot = await userDoc.get();

      String displayName = user.displayName ??
          user.email?.split('@').first ??
          'User';

      final userData = UserModel(
        uid: user.uid,
        displayName: displayName,
        photoURL: user.photoURL,
        socialLinks: {},
        createdAt: userSnapshot.exists
            ? (userSnapshot.data()?['createdAt'] as Timestamp?)?.toDate() ??
                DateTime.now()
            : DateTime.now(),
      );

      if (userSnapshot.exists) {
        // Update existing user, preserve social links
        final existingData = userSnapshot.data() as Map<String, dynamic>;
        final existingUser = UserModel.fromFirestore(userSnapshot);

        await userDoc.update({
          'displayName': displayName,
          'photoURL': user.photoURL,
          'socialLinks': existingUser.socialLinks,
        });
      } else {
        // Create new user document
        await userDoc.set(userData.toFirestore());
      }

      AppLogger.i('User document created/updated successfully');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to create/update user document', e, stackTrace);
      rethrow;
    }
  }

  Future<UserModel?> getCurrentUserData() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      return UserModel.fromFirestore(userDoc);
    } catch (e, stackTrace) {
      AppLogger.e('Failed to get current user data', e, stackTrace);
      return null;
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
