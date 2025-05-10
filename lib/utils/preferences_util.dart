import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class PreferencesUtil {
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyFirstLaunch = 'first_launch';

  // Check if onboarding has been completed
  static Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completed = prefs.getBool(_keyOnboardingCompleted) ?? false;
      debugPrint('PreferencesUtil: Onboarding completed: $completed');
      return completed;
    } catch (e) {
      debugPrint('PreferencesUtil: Error checking onboarding status: $e');
      return false;
    }
  }

  // Mark onboarding as completed
  static Future<void> setOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyOnboardingCompleted, true);
      debugPrint('PreferencesUtil: Onboarding marked as completed');
    } catch (e) {
      debugPrint('PreferencesUtil: Error setting onboarding completed: $e');
    }
  }

  // Check if this is the first launch of the app
  static Future<bool> isFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirst = prefs.getBool(_keyFirstLaunch) ?? true;

      // If it's the first launch, set it to false for next time
      if (isFirst) {
        await prefs.setBool(_keyFirstLaunch, false);
        debugPrint('PreferencesUtil: First launch detected');
      }

      return isFirst;
    } catch (e) {
      debugPrint('PreferencesUtil: Error checking first launch: $e');
      return true;
    }
  }

  // Reset all preferences (for testing)
  static Future<void> resetAllPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('PreferencesUtil: All preferences reset');
    } catch (e) {
      debugPrint('PreferencesUtil: Error resetting preferences: $e');
    }
  }
}
