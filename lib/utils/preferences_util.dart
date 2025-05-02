// Temporary implementation without shared_preferences

class PreferencesUtil {
  static const String _keyOnboardingCompleted = 'onboarding_completed';

  // In-memory storage for preferences (temporary solution)
  static final Map<String, dynamic> _preferences = {};

  // Check if onboarding has been completed
  static Future<bool> isOnboardingCompleted() async {
    // Simulate a delay to mimic async operation
    await Future.delayed(const Duration(milliseconds: 100));
    return _preferences[_keyOnboardingCompleted] ?? false;
  }

  // Mark onboarding as completed
  static Future<void> setOnboardingCompleted() async {
    // Simulate a delay to mimic async operation
    await Future.delayed(const Duration(milliseconds: 100));
    _preferences[_keyOnboardingCompleted] = true;
  }
}
