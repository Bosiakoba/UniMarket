import 'package:flutter/foundation.dart';

class AppPreferencesStore extends ChangeNotifier {
  bool onboardingComplete = false;
  bool profileSetupComplete = false;

  void completeOnboarding() {
    onboardingComplete = true;
    notifyListeners();
  }

  void completeProfileSetup() {
    profileSetupComplete = true;
    notifyListeners();
  }

  void reset() {
    onboardingComplete = false;
    profileSetupComplete = false;
    notifyListeners();
  }
}
