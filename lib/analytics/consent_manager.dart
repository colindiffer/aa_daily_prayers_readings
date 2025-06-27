import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Define consent types matching Google's consent mode categories
enum ConsentType {
  analytics, // analytics_storage
  adStorage, // ad_storage
  adUserData, // ad_user_data
  adPersonalization, // ad_personalization
}

// Define consent states
enum ConsentState { granted, denied, notSet }

class ConsentManager {
  static final ConsentManager _instance = ConsentManager._internal();
  static const String _consentPreferenceKeyPrefix = 'consent_mode_';

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final Map<ConsentType, ConsentState> _consentSettings = {};
  bool _initialized = false;

  factory ConsentManager() {
    return _instance;
  }

  ConsentManager._internal();

  /// Initialize consent manager and load saved preferences
  Future<void> initialize() async {
    if (_initialized) return;

    // Set default consent mode (before user interaction)
    await _setDefaultConsentMode();

    // Load saved consent states
    final prefs = await SharedPreferences.getInstance();

    for (var type in ConsentType.values) {
      final key = _getPreferenceKey(type);
      final value = prefs.getString(key);

      if (value == null) {
        _consentSettings[type] = ConsentState.notSet;
      } else {
        _consentSettings[type] =
            value == 'granted' ? ConsentState.granted : ConsentState.denied;
      }
    }

    // Apply consent settings to Firebase
    await _applyConsentSettingsToFirebase();
    _initialized = true;
  }

  /// Set default consent mode for Google Consent Mode (before user choice)
  Future<void> _setDefaultConsentMode() async {
    try {
      // Set default consent to denied for all types (GDPR compliant)
      final Map<String, Object> defaultConsent = {
        'analytics_storage': 'denied',
        'ad_storage': 'denied',
        'ad_user_data': 'denied',
        'ad_personalization': 'denied',
        'functionality_storage': 'granted', // Functional is always granted
        'security_storage': 'granted', // Security is always granted
      };

      await _analytics.setDefaultEventParameters(defaultConsent);
      debugPrint('Default Google Consent Mode set: $defaultConsent');
    } catch (e) {
      debugPrint('Error setting default consent mode: $e');
    }
  }

  /// Get consent state for a specific consent type
  ConsentState getConsentState(ConsentType type) {
    return _consentSettings[type] ?? ConsentState.notSet;
  }

  /// Update consent state for a specific type
  Future<void> setConsentState(ConsentType type, ConsentState state) async {
    _consentSettings[type] = state;

    // Save consent state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _getPreferenceKey(type),
      state == ConsentState.granted ? 'granted' : 'denied',
    );

    // Update Firebase Analytics consent settings
    await _applyConsentSettingsToFirebase();
  }

  /// Update all consent states at once
  Future<void> updateAllConsent(
    Map<ConsentType, ConsentState> consentSettings,
  ) async {
    _consentSettings.addAll(consentSettings);

    // Save all consent states
    final prefs = await SharedPreferences.getInstance();
    for (var entry in consentSettings.entries) {
      await prefs.setString(
        _getPreferenceKey(entry.key),
        entry.value == ConsentState.granted ? 'granted' : 'denied',
      );
    }

    // Update Firebase Analytics consent settings
    await _applyConsentSettingsToFirebase();
  }

  /// Apply current consent settings to Firebase Analytics
  Future<void> _applyConsentSettingsToFirebase() async {
    // Apply Google Consent Mode parameters
    await _setGoogleConsentMode();

    // Only toggle analytics collection based on analytics consent
    final analyticsConsent =
        _consentSettings[ConsentType.analytics] ?? ConsentState.notSet;
    if (analyticsConsent != ConsentState.notSet) {
      await _analytics.setAnalyticsCollectionEnabled(
        analyticsConsent == ConsentState.granted,
      );
    }
    // We're not actually applying ad consent values to any ad services
  }

  /// Set Google Consent Mode parameters
  Future<void> _setGoogleConsentMode() async {
    try {
      // Create consent parameters map for Google Consent Mode
      final Map<String, Object> consentParams = {};

      for (var type in ConsentType.values) {
        final state = _consentSettings[type] ?? ConsentState.notSet;
        if (state != ConsentState.notSet) {
          final consentValue =
              state == ConsentState.granted ? 'granted' : 'denied';
          consentParams[_getConsentTypeString(type)] = consentValue;
        }
      }

      // Set default consent mode parameters for all events
      if (consentParams.isNotEmpty) {
        await _analytics.setDefaultEventParameters(consentParams);

        // Log consent update event
        await _analytics.logEvent(
          name: 'consent_update',
          parameters: consentParams,
        );

        debugPrint('Google Consent Mode updated: $consentParams');
      }
    } catch (e) {
      debugPrint('Error setting Google Consent Mode: $e');
    }
  }

  /// Send an event to Firebase Analytics with consent data
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    // Only send event if analytics consent is granted
    if (_consentSettings[ConsentType.analytics] == ConsentState.granted) {
      // Add consent parameters to the event
      final Map<String, dynamic> eventParams = parameters ?? {};

      // Add consent status parameters for data layer
      for (var type in ConsentType.values) {
        final state = _consentSettings[type] ?? ConsentState.notSet;
        if (state != ConsentState.notSet) {
          eventParams['consent_${_getConsentTypeString(type)}'] =
              state == ConsentState.granted ? 'granted' : 'denied';
        }
      }

      // Cast dynamic to non-nullable Object with proper type safety
      Map<String, Object>? safeParams;
      try {
        safeParams = eventParams.map<String, Object>(
          (String key, dynamic value) =>
              MapEntry<String, Object>(key, value as Object),
        );
      } catch (e) {
        debugPrint('Error casting event parameters: $e');
        safeParams = <String, Object>{};
      }

      await _analytics.logEvent(name: name, parameters: safeParams);
    }
  }

  /// Convert consent type to string representation
  String _getConsentTypeString(ConsentType type) {
    switch (type) {
      case ConsentType.analytics:
        return 'analytics_storage';
      case ConsentType.adStorage:
        return 'ad_storage';
      case ConsentType.adUserData:
        return 'ad_user_data';
      case ConsentType.adPersonalization:
        return 'ad_personalization';
    }
  }

  /// Get preference key for a specific consent type
  String _getPreferenceKey(ConsentType type) {
    return _consentPreferenceKeyPrefix + _getConsentTypeString(type);
  }

  /// Get consent parameters as a map for server-side integration
  Map<String, String> getConsentParameters() {
    final Map<String, String> params = {};

    for (var type in ConsentType.values) {
      final state = _consentSettings[type] ?? ConsentState.notSet;
      if (state != ConsentState.notSet) {
        params[_getConsentTypeString(type)] =
            state == ConsentState.granted ? 'granted' : 'denied';
      }
    }

    return params;
  }

  /// Update consent state for a specific type
  Future<void> updateConsent(ConsentType type, ConsentState value) async {
    // Store the consent value for all types, including ad-related ones
    _consentSettings[type] = value;

    // Save consent to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final String key = 'consent_${type.toString().split('.').last}';
    await prefs.setString(
      key,
      value == ConsentState.granted ? 'granted' : 'denied',
    );

    // Apply to Firebase Analytics if it's not an ad-related type
    // This prevents errors since we're not actually using ads
    if (type == ConsentType.analytics) {
      await _applyConsentSettingsToFirebase();
    }
  }

  /// Check if consent banner should be shown (if no consent has been given)
  Future<bool> shouldShowBanner() async {
    await initialize();
    // Show banner if analytics consent hasn't been set
    return _consentSettings[ConsentType.analytics] == ConsentState.notSet;
  }

  /// Check if user has given consent for specific type
  bool hasConsentFor(ConsentType type) {
    return _consentSettings[type] == ConsentState.granted;
  }

  /// Reset all consent (for testing or user request)
  Future<void> resetAllConsent() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear all stored consent preferences
    for (var type in ConsentType.values) {
      await prefs.remove(_getPreferenceKey(type));
    }

    // Reset in-memory settings
    _consentSettings.clear();

    // Reinitialize with defaults
    _initialized = false;
    await initialize();
  }
}
