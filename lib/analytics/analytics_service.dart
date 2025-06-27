import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'consent_manager.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final ConsentManager _consentManager = ConsentManager();
  bool _enabled = true;

  factory AnalyticsService() {
    return _instance;
  }

  AnalyticsService._internal();

  /// Initialize the analytics service
  Future<void> initialize() async {
    await _consentManager.initialize();
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('analytics_consent') ?? true;
  }

  /// Log event with consent consideration
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    if (_enabled) {
      try {
        await _analytics.logEvent(name: name, parameters: parameters);
      } catch (e) {
        print('Analytics error: $e');
      }
    }
  }

  /// Get the Firebase Analytics instance
  FirebaseAnalytics get analytics => _analytics;

  /// Get the ConsentManager instance
  ConsentManager get consentManager => _consentManager;

  /// Set user properties with consent consideration
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    // Only set user property if analytics consent is granted
    if (_consentManager.getConsentState(ConsentType.analytics) ==
        ConsentState.granted) {
      await _analytics.setUserProperty(name: name, value: value);
    }
  }

  /// Show consent dialog (implement UI in your app)
  Future<void> showConsentUI() async {
    // Implement your consent UI here
    // After user choice, update consent states:
    // Example:
    // await _consentManager.updateAllConsent({
    //   ConsentType.analytics: userChoice ? ConsentState.granted : ConsentState.denied,
    //   ConsentType.adStorage: userChoice ? ConsentState.granted : ConsentState.denied,
    // });
  }

  Future<void> setCurrentScreen(String screenName) async {
    if (_enabled) {
      await _analytics.setCurrentScreen(screenName: screenName);
    }
  }

  Future<void> enableAnalytics() async {
    _enabled = true;
    await _analytics.setAnalyticsCollectionEnabled(true);
  }

  Future<void> disableAnalytics() async {
    _enabled = false;
    await _analytics.setAnalyticsCollectionEnabled(false);
  }
}
