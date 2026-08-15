import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesStore extends ChangeNotifier {
  bool onboardingComplete = false;
  bool profileSetupComplete = false;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      onboardingComplete = prefs.getBool('onboardingComplete') ?? false;
      profileSetupComplete = prefs.getBool('profileSetupComplete') ?? false;
      notifyListeners();
    } catch (_) {}
  }

  void completeOnboarding() {
    onboardingComplete = true;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('onboardingComplete', true);
    }).catchError((_) {});
  }

  void completeProfileSetup() {
    profileSetupComplete = true;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('profileSetupComplete', true);
    }).catchError((_) {});
  }

  void reset() {
    onboardingComplete = false;
    profileSetupComplete = false;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.clear();
    }).catchError((_) {});
  }
}
