// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../analytics/consent_manager.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String appVersion = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getAppVersion();
  }

  Future<void> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        appVersion = 'Version information unavailable';
        isLoading = false;
      });
    }
  }

  void _openConsentManager() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const ConsentPreferencesDialog();
      },
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'aa.prayer.readings.app@gmail.com',
      query: Uri.encodeQueryComponent(
        'subject=Feedback about AA Readings & Prayers App',
      ),
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw 'Could not launch email client';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Unable to open email client. Please email us at aa.prayer.readings.app@gmail.com'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue,
                      child: Icon(
                        Icons.book,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'AA Readings & Prayers',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  Center(
                    child: Text(
                      'Version $appVersion',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'About the App',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This app provides daily readings and reflections for those in recovery. It is not affliated with Alcoholics Anonymous or any other organization, it is simply a tool to help individuals in their journey created by an alcoholic',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Contact Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'For support or feedback, please contact us at:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _launchEmail,
                    child: const Text(
                      'aa.prayer.readings.app@gmail.com',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Privacy Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _openConsentManager,
                    child: const Text('Manage Consent Preferences'),
                  ),
                ],
              ),
            ),
    );
  }
}

class ConsentPreferencesDialog extends StatefulWidget {
  const ConsentPreferencesDialog({super.key});

  @override
  State<ConsentPreferencesDialog> createState() =>
      _ConsentPreferencesDialogState();
}

class _ConsentPreferencesDialogState extends State<ConsentPreferencesDialog> {
  Map<String, bool> _consentOptions = {
    "functional": true,
    "analytics": false,
    "marketing": false
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentConsent();
  }

  Future<void> _loadCurrentConsent() async {
    final consentManager = ConsentManager();
    await consentManager.initialize();
    setState(() {
      _consentOptions = {
        "functional": true, // Always enabled
        "analytics": consentManager.getConsentState(ConsentType.analytics) ==
            ConsentState.granted,
        "marketing":
            consentManager.getConsentState(ConsentType.adPersonalization) ==
                ConsentState.granted,
      };
    });
  }

  Future<void> _saveConsent() async {
    final consentManager = ConsentManager();
    await consentManager.updateAllConsent({
      ConsentType.analytics: _consentOptions["analytics"] == true
          ? ConsentState.granted
          : ConsentState.denied,
      ConsentType.adPersonalization: _consentOptions["marketing"] == true
          ? ConsentState.granted
          : ConsentState.denied,
      ConsentType.adStorage: _consentOptions["marketing"] == true
          ? ConsentState.granted
          : ConsentState.denied,
      ConsentType.adUserData: _consentOptions["marketing"] == true
          ? ConsentState.granted
          : ConsentState.denied,
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Consent Preferences"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Manage your consent preferences below.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const CheckboxListTile(
              title: Text("Functional (Required)"),
              value: true,
              onChanged: null, // Functional consent is always enabled
            ),
            CheckboxListTile(
              title: const Text("Analytics"),
              value: _consentOptions["analytics"],
              onChanged: (value) {
                setState(() {
                  _consentOptions["analytics"] = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text("Marketing"),
              value: _consentOptions["marketing"],
              onChanged: (value) {
                setState(() {
                  _consentOptions["marketing"] = value ?? false;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _consentOptions = {
                "functional": true,
                "analytics": false,
                "marketing": false
              };
            });
            _saveConsent();
          },
          child: const Text("Reject All"),
        ),
        ElevatedButton(
          onPressed: _saveConsent,
          child: const Text("Save Preferences"),
        ),
      ],
    );
  }
}
