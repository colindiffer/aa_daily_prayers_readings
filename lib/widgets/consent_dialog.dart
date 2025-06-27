import 'package:flutter/material.dart';
import '../analytics/consent_manager.dart';
import '../analytics/analytics_service.dart';

class ConsentDialog extends StatefulWidget {
  final Function(bool analyticsConsent, bool marketingConsent)?
  onConsentChanged;
  final VoidCallback? onCompleted;

  const ConsentDialog({Key? key, this.onConsentChanged, this.onCompleted})
    : super(key: key);

  @override
  State<ConsentDialog> createState() => _ConsentDialogState();
}

class _ConsentDialogState extends State<ConsentDialog> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final Map<ConsentType, ConsentState> _consentSettings = {
    ConsentType.analytics: ConsentState.denied,
    ConsentType.adStorage: ConsentState.denied,
    ConsentType.adUserData: ConsentState.denied,
    ConsentType.adPersonalization: ConsentState.denied,
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentConsent();
  }

  Future<void> _loadCurrentConsent() async {
    // Load current consent settings
    for (var type in ConsentType.values) {
      final state = _analyticsService.consentManager.getConsentState(type);
      if (state != ConsentState.notSet) {
        setState(() {
          _consentSettings[type] = state;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Preferences',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              'Please select which types of data you allow us to collect:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildConsentOptions(),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _buildPrivacyLinks(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentOptions() {
    return Column(
      children: [
        _buildConsentSwitch(
          title: 'Analytics',
          description:
              'Collect anonymous usage data to improve app functionality',
          type: ConsentType.analytics,
        ),
        const SizedBox(height: 16),
        _buildConsentSwitch(
          title: 'Ad Storage',
          description: 'Store information for advertising purposes',
          type: ConsentType.adStorage,
        ),
        const SizedBox(height: 16),
        _buildConsentSwitch(
          title: 'Ad User Data',
          description: 'Use data to show relevant ads based on your profile',
          type: ConsentType.adUserData,
        ),
        const SizedBox(height: 16),
        _buildConsentSwitch(
          title: 'Ad Personalization',
          description: 'Personalize ads based on your interests',
          type: ConsentType.adPersonalization,
        ),
      ],
    );
  }

  Widget _buildConsentSwitch({
    required String title,
    required String description,
    required ConsentType type,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Switch(
          value: _consentSettings[type] == ConsentState.granted,
          onChanged: (value) {
            setState(() {
              _consentSettings[type] =
                  value ? ConsentState.granted : ConsentState.denied;
            });
          },
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () {
            // Navigate to privacy policy
          },
          child: const Text('Privacy Policy'),
        ),
        const SizedBox(width: 16),
        TextButton(
          onPressed: () {
            // Navigate to terms of service
          },
          child: const Text('Terms of Service'),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {
            // Reject all and close dialog
            _updateAllConsent(false);
            Navigator.of(context).pop();
          },
          child: const Text('Reject All'),
        ),
        const SizedBox(width: 16),
        TextButton(
          onPressed: () {
            // Accept all and close dialog
            _updateAllConsent(true);
            Navigator.of(context).pop();
          },
          child: const Text('Accept All'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () {
            // Save current selections
            _saveConsent();
            Navigator.of(context).pop();
          },
          child: const Text('Save Preferences'),
        ),
      ],
    );
  }

  void _updateAllConsent(bool granted) {
    final consentState = granted ? ConsentState.granted : ConsentState.denied;
    Map<ConsentType, ConsentState> settings = {};

    for (var type in ConsentType.values) {
      settings[type] = consentState;
    }

    _analyticsService.consentManager.updateAllConsent(settings);

    // Call the onConsentChanged callback
    widget.onConsentChanged?.call(
      granted, // analytics
      granted, // marketing
    );

    widget.onCompleted?.call();
  }

  void _saveConsent() {
    // Update the consent manager with current settings
    _analyticsService.consentManager.updateAllConsent(_consentSettings);

    // Call the onConsentChanged callback
    widget.onConsentChanged?.call(
      _consentSettings[ConsentType.analytics] == ConsentState.granted,
      _consentSettings[ConsentType.adPersonalization] == ConsentState.granted,
    );

    widget.onCompleted?.call();
  }
}
