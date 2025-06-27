import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../analytics/consent_manager.dart';

class AnalyticsConsentService {
  static final AnalyticsConsentService _instance =
      AnalyticsConsentService._internal();
  factory AnalyticsConsentService() => _instance;
  AnalyticsConsentService._internal();

  static const String _consentKey = 'analytics_consent_given';
  static const String _consentDateKey = 'analytics_consent_date';

  /// Set user's analytics consent preference
  Future<void> setAnalyticsConsent(bool consent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, consent);
    await prefs.setString(_consentDateKey, DateTime.now().toIso8601String());

    // Use the main consent manager for Google Consent Mode compliance
    final consentManager = ConsentManager();
    await consentManager.initialize();

    // Update consent through the main consent manager
    await consentManager.updateAllConsent({
      ConsentType.analytics:
          consent ? ConsentState.granted : ConsentState.denied,
      // Keep marketing/ads as denied unless explicitly set elsewhere
      ConsentType.adPersonalization: ConsentState.denied,
      ConsentType.adStorage: ConsentState.denied,
      ConsentType.adUserData: ConsentState.denied,
    });

    // Also configure Firebase Analytics directly (legacy support)
    await _configureAnalytics(consent);
  }

  /// Get user's analytics consent preference
  Future<bool> getAnalyticsConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentKey) ?? false;
  }

  /// Check if user has previously given consent (for showing banner)
  Future<bool> hasConsentBeenRequested() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_consentKey);
  }

  /// Get the date when consent was given
  Future<DateTime?> getConsentDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_consentDateKey);
    if (dateString != null) {
      return DateTime.tryParse(dateString);
    }
    return null;
  }

  /// Configure Firebase Analytics based on consent
  Future<void> _configureAnalytics(bool consent) async {
    try {
      final analytics = FirebaseAnalytics.instance;

      if (consent) {
        // Enable analytics collection
        await analytics.setAnalyticsCollectionEnabled(true);

        // Log consent given event
        await analytics.logEvent(
          name: 'analytics_consent_given',
          parameters: {'consent_date': DateTime.now().toIso8601String()},
        );
      } else {
        // Disable analytics collection
        await analytics.setAnalyticsCollectionEnabled(false);

        // Note: We can't log an event if analytics is disabled,
        // but we can store this preference locally
      }
    } catch (e) {
      print('Error configuring analytics: $e');
    }
  }

  /// Initialize analytics based on stored consent
  Future<void> initializeAnalytics() async {
    // Use the main consent manager for initialization
    final consentManager = ConsentManager();
    await consentManager.initialize();

    // Legacy support: also check our simple consent preference
    final consent = await getAnalyticsConsent();
    await _configureAnalytics(consent);
  }

  /// Show consent banner if needed (returns true if banner should be shown)
  Future<bool> shouldShowConsentBanner() async {
    final hasBeenRequested = await hasConsentBeenRequested();
    return !hasBeenRequested;
  }

  /// Reset all consent preferences (for testing or user request)
  Future<void> resetConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_consentKey);
    await prefs.remove(_consentDateKey);

    // Disable analytics
    await _configureAnalytics(false);
  }
}
