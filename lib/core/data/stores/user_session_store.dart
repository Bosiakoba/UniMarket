import 'package:flutter/foundation.dart';

import '../../api/api_client.dart';
import '../../models/app_user.dart';

class UserSessionStore extends ChangeNotifier {
  AppUser? currentUser;
  bool isSigningIn = false;
  String? lastAuthError;

  bool get isLoggedIn => currentUser != null;

  static const demoEmail = 'alex.morgan@university.edu';

  bool get isDemoAccount =>
      currentUser?.email.toLowerCase() == demoEmail.toLowerCase();

  String devUserIdForEmail(String email) {
    final normalized = email.trim().toLowerCase();
    if (normalized == demoEmail) return 'alex-demo';
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
      final devUserId = devUserIdForEmail(email);
      final profile = await client.bootstrapSession(devUserId: devUserId);
      currentUser = ListingMapper.userFromJson(profile);
      return null;
    } catch (error) {
      lastAuthError = error.toString();
      currentUser = _userFromEmail(email.trim().toLowerCase(), isNew: false);
      client.devUserId = currentUser!.id;
      return null;
    } finally {
      isSigningIn = false;
      notifyListeners();
    }
  }

  String? signIn({required String email, required String password}) {
    final validationError = _validateCredentials(email, password);
    if (validationError != null) return validationError;

    currentUser = _userFromEmail(email.trim().toLowerCase(), isNew: false);
    notifyListeners();
    return null;
  }

  String? signUp({required String email, required String password}) {
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedEmail.isEmpty) return 'Enter your university email.';
    if (!_isCampusEmail(trimmedEmail)) {
      return 'Use your campus email address.';
    }
    if (password.trim().length < 6) {
      return 'Password must be at least 6 characters.';
    }

    currentUser = _userFromEmail(trimmedEmail, isNew: true);
    notifyListeners();
    return null;
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

  void signOut() {
    currentUser = null;
    lastAuthError = null;
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
