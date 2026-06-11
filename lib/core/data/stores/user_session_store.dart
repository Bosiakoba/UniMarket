import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../api/api_client.dart';
import '../../models/app_user.dart';
import '../../services/firebase_auth_service.dart';

class UserSessionStore extends ChangeNotifier {
  AppUser? currentUser;
  bool isSigningIn = false;
  String? lastAuthError;

  bool get isLoggedIn => currentUser != null;

  static const demoEmail = 'alex.morgan@university.edu';
  static const jordanDemoEmail = 'jordan@university.edu';

  bool get isDemoAccount =>
      currentUser?.email.toLowerCase() == demoEmail.toLowerCase();

  String devUserIdForEmail(String email) {
    final normalized = email.trim().toLowerCase();
    if (normalized == demoEmail) return 'alex-demo';
    if (normalized == jordanDemoEmail) return 'seller-jordan';
    return 'user-${normalized.hashCode.abs()}';
  }

  Future<String?> signInWithApi({
    required ApiClient client,
    required String email,
    required String password,
  }) async {
    final validationError = _validateCredentials(email, password);
    if (validationError != null) return validationError;

    isSigningIn = true;
    lastAuthError = null;
    notifyListeners();

    try {
      await FirebaseAuthService.signInWithEmailPassword(
        email: email,
        password: password,
      );
      return await _completeApiSession(client);
    } on FirebaseAuthException catch (error) {
      return FirebaseAuthService.mapAuthError(error);
    } catch (error) {
      lastAuthError = error.toString();
      return _offlineFallback(client, email);
    } finally {
      isSigningIn = false;
      notifyListeners();
    }
  }

  Future<String?> signUpWithApi({
    required ApiClient client,
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedEmail.isEmpty) return 'Enter your university email.';
    if (!_isCampusEmail(trimmedEmail)) {
      return 'Use your campus email address.';
    }
    if (password.trim().length < 6) {
      return 'Password must be at least 6 characters.';
    }

    isSigningIn = true;
    lastAuthError = null;
    notifyListeners();

    try {
      await FirebaseAuthService.signUpWithEmailPassword(
        email: trimmedEmail,
        password: password,
      );
      return await _completeApiSession(client);
    } on FirebaseAuthException catch (error) {
      return FirebaseAuthService.mapAuthError(error);
    } catch (error) {
      lastAuthError = error.toString();
      return error.toString();
    } finally {
      isSigningIn = false;
      notifyListeners();
    }
  }

  Future<bool> restoreFromFirebase({required ApiClient client}) async {
    if (FirebaseAuthService.currentUser == null) return false;

    try {
      await _completeApiSession(client);
      return currentUser != null;
    } catch (_) {
      await FirebaseAuthService.signOut();
      client
        ..idToken = null
        ..devUserId = null;
      currentUser = null;
      notifyListeners();
      return false;
    }
  }

  Future<String?> _completeApiSession(ApiClient client) async {
    final idToken = await FirebaseAuthService.getIdToken();
    if (idToken == null) {
      return 'Could not obtain a sign-in token.';
    }

    try {
      final profile = await client.bootstrapSession(firebaseIdToken: idToken);
      currentUser = ListingMapper.userFromJson(profile);
      client
        ..idToken = idToken
        ..devUserId = null;
      lastAuthError = null;
      return null;
    } catch (error) {
      lastAuthError = error.toString();
      rethrow;
    }
  }

  String? _offlineFallback(ApiClient client, String email) {
    currentUser = _userFromEmail(email.trim().toLowerCase(), isNew: false);
    client
      ..devUserId = currentUser!.id
      ..idToken = null;
    return null;
  }

  Future<void> signOut() async {
    await FirebaseAuthService.signOut();
    currentUser = null;
    lastAuthError = null;
    notifyListeners();
  }

  void completeProfile({
    required String fullName,
    required String university,
    required String campus,
    String? phone,
  }) {
    final user = currentUser;
    if (user == null) return;
    currentUser = user.copyWith(
      fullName: fullName.trim().isEmpty ? user.fullName : fullName.trim(),
      university:
          university.trim().isEmpty ? user.university : university.trim(),
      campus: campus.trim().isEmpty ? user.campus : campus.trim(),
      phone: phone?.trim().isEmpty ?? true ? user.phone : phone?.trim(),
    );
    notifyListeners();
  }

  void setInterestCategories(Set<String> categories) {
    final user = currentUser;
    if (user == null) return;
    currentUser = user.copyWith(interestCategories: categories);
    notifyListeners();
  }

  void updateProfile({
    String? fullName,
    String? university,
    String? campus,
    String? phone,
  }) {
    final user = currentUser;
    if (user == null) return;
    currentUser = user.copyWith(
      fullName: fullName ?? user.fullName,
      university: university ?? user.university,
      campus: campus ?? user.campus,
      phone: phone ?? user.phone,
    );
    notifyListeners();
  }

  String? _validateCredentials(String email, String password) {
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedEmail.isEmpty) return 'Enter your university email.';
    if (!_isCampusEmail(trimmedEmail)) {
      return 'Use your campus email address.';
    }
    if (password.trim().isEmpty) return 'Enter your password.';
    return null;
  }

  bool _isCampusEmail(String email) {
    return email.contains('@') && email.split('@').last.contains('.');
  }

  AppUser _userFromEmail(String email, {required bool isNew}) {
    final localPart = email.split('@').first;
    final nameParts = localPart.split(RegExp(r'[._-]+'));
    final fullName = nameParts
        .where((p) => p.isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');

    return AppUser(
      id: devUserIdForEmail(email),
      email: email,
      fullName: fullName.isEmpty ? 'Campus User' : fullName,
      university: 'State University',
      campus: 'Main Campus',
      createdAt: DateTime.now(),
      firebaseUid: null,
      isSeller: email == demoEmail,
    );
  }
}
