import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

/// A service class to manage onboarding state
/// 
/// SharedPreferences is used to track whether the user has previously opened the app or whether
/// this is their first time.
class OnboardingService {

  // Name of key that stores whether user is a first-time user or not.
  static const _isNotFirstKey = 'isNotFirst';

  /// Checks if the user is opening the app for the first time.
  static Future<bool> isFirstTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      //Uncommenting the line below simulates a first time user.
      //await prefs.clear();
      return !(prefs.getBool(_isNotFirstKey) ?? false);
    } catch (e) {
      log("Error accessing SharedPreferences: $e");
      return true; // **Assume first-time user if SharedPreferences fails**
    }
  }


  /// Marks that the user has seen the onboarding screen.
  /// 
  /// Returns:
  /// `true` if saving of onboarding was succcessful
  /// `false` if saving failed.
  static Future<bool> markFirstTimeComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setBool(_isNotFirstKey, true);
      if (!success) {
        log("Failed to save onboarding status.");
      }
      return success; 
    } catch (e) {
      log("Error saving onboarding status: $e");
      return false; 
    }
  }
}

