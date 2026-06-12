import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  FirebaseAuthService._();

  static FirebaseAuth get _auth => FirebaseAuth.instance;

  static User? get currentUser {
    try {
      return _auth.currentUser;
    } on FirebaseException {
      return null;
    }
  }

  static bool get isAnonymous => currentUser?.isAnonymous ?? false;

  static Future<UserCredential> signInAnonymously() {
    return _auth.signInAnonymously();
  }

  static Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = currentUser;
    if (user == null) return null;
    return user.getIdToken(forceRefresh);
  }

  static Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (error) {
      return mapAuthError(error);
    } catch (error) {
      return error.toString();
    }
  }

  static Future<void> sendEmailVerification() async {
    final user = currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  static Future<bool> reloadEmailVerified() async {
    final user = currentUser;
    if (user == null) return false;
    await user.reload();
    return currentUser?.emailVerified ?? false;
  }

  static bool get emailVerified => currentUser?.emailVerified ?? false;

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseException {
      return;
    }
  }

  static String? mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }
}
