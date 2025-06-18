import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../analytics/analytics_service.dart';
import '../analytics/consent_manager.dart';

class ConsentSettingsScreen extends StatefulWidget {
  const ConsentSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ConsentSettingsScreen> createState() => _ConsentSettingsScreenState();
}

class _ConsentSettingsScreenState extends State<ConsentSettingsScreen> {
  bool _analyticsConsent = true;
  bool _pushNotificationsConsent = true;
  final AnalyticsService _analytics = AnalyticsService();
  late Map<ConsentType, ConsentState> _consentStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConsentStatus();
    _loadPreferences();

    // Track screen view
    _analytics.logEvent(
      name: 'screen_view',
      parameters: {'screen_name': 'consent_settings_screen'},
    );
  }

  Future<void> _loadConsentStatus() async {
    final Map<ConsentType, ConsentState> consentStatus = {
      ConsentType.analytics: _analytics.consentManager.getConsentState(
        ConsentType.analytics,
      ),
      ConsentType.adStorage: _analytics.consentManager.getConsentState(
        ConsentType.adStorage,
      ),
      ConsentType.adUserData: _analytics.consentManager.getConsentState(
        ConsentType.adUserData,
      ),
      ConsentType.adPersonalization: _analytics.consentManager
          .getConsentState(ConsentType.adPersonalization),
    };

    setState(() {
      _consentStatus = consentStatus;
      _isLoading = false;
    });
  }

  Future<void> _updateConsent(ConsentType type, ConsentState value) async {
    await _analytics.consentManager.updateConsent(type, value);
    setState(() {
      _consentStatus[type] = value;
    });

    // Log consent change event
    _analytics.logEvent(
      name: 'consent_updated',
      parameters: {
        'consent_type': type.toString().split('.').last,
        'consent_value': value.toString().split('.').last,
      },
    );
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _analyticsConsent = prefs.getBool('analytics_consent') ?? true;
      _pushNotificationsConsent =
          prefs.getBool('push_notifications_consent') ?? true;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('analytics_consent', _analyticsConsent);
    await prefs.setBool(
        'push_notifications_consent', _pushNotificationsConsent);

    // Update analytics consent
    await _updateConsent(
      ConsentType.analytics,
      _analyticsConsent ? ConsentState.granted : ConsentState.denied,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferences updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Consent Settings'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Privacy Preferences',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Manage how your data is collected and used in the app.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  SwitchListTile(
                    title: const Text('Allow Analytics'),
                    subtitle: const Text(
                      'Helps us improve the app by collecting anonymous usage data',
                    ),
                    value: _analyticsConsent,
                    onChanged: (bool value) {
                      setState(() {
                        _analyticsConsent = value;
                      });
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Push Notifications'),
                    subtitle: const Text(
                      'Receive daily reading notifications and important updates',
                    ),
                    value: _pushNotificationsConsent,
                    onChanged: (bool value) {
                      setState(() {
                        _pushNotificationsConsent = value;
                      });
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 24),
                  const Text(
                    'Your privacy is important to us. We only collect anonymous data to improve app functionality and fix issues.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _savePreferences,
                      child: const Text('Save Preferences'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
