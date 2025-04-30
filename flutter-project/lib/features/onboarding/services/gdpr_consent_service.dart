import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

/// A service class to manage GDPR consent state
/// 
/// SharedPreferences is used to track whether the user has given GDPR consent
class GDPRConsentService {
  // Name of key that stores whether user has given GDPR consent
  static const _hasGivenConsentKey = 'hasGivenGDPRConsent';

  /// Checks if the user has given GDPR consent
  static Future<bool> hasGivenConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_hasGivenConsentKey) ?? false;
    } catch (e) {
      log("Error accessing SharedPreferences for GDPR consent: $e");
      return false; // Assume no consent if SharedPreferences fails
    }
  }

  /// Marks that the user has given GDPR consent
  /// 
  /// Returns:
  /// `true` if saving consent status was successful
  /// `false` if saving failed
  static Future<bool> markConsentGiven() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setBool(_hasGivenConsentKey, true);
      if (!success) {
        log("Failed to save GDPR consent status.");
      }
      return success;
    } catch (e) {
      log("Error saving GDPR consent status: $e");
      return false;
    }
  }
} 