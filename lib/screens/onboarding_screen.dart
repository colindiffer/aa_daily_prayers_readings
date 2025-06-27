import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/notification_service.dart';
import '../analytics/consent_manager.dart';
import 'readings_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentStep = 0;
  bool isLoading = false;
  bool showDetailedConsent = false;

  // Voice preferences
  String selectedVoiceRegion = 'US'; // Default to US
  String selectedVoiceGender = 'Female'; // Default to Female

  // TTS for voice testing
  final FlutterTts _testTts = FlutterTts();
  bool _isTestingVoice = false;

  // Consent preferences
  Map<String, bool> consentOptions = {
    "functional": true, // Always required
    "analytics": false,
    "marketing": false,
  };

  final List<OnboardingStep> steps = [
    OnboardingStep(
      title: 'Welcome to AA Daily Readings',
      description: 'Your daily companion for spiritual growth and recovery.',
      icon: Icons.book_outlined,
      color: Colors.blue,
    ),
    OnboardingStep(
      title: 'Daily Notifications',
      description:
          'Receive gentle reminders for your daily readings and prayers.',
      icon: Icons.notifications_outlined,
      color: Colors.orange,
    ),
    OnboardingStep(
      title: 'Alarms & Reminders',
      description:
          'Allow the app to schedule exact alarms for your daily routine.',
      icon: Icons.alarm,
      color: Colors.green,
    ),
    OnboardingStep(
      title: 'Background Access',
      description:
          'Keep the app working in the background for timely notifications.',
      icon: Icons.settings_backup_restore,
      color: Colors.purple,
    ),
    OnboardingStep(
      title: 'Voice Settings',
      description:
          'Choose your preferred voice for reading the daily content aloud.',
      icon: Icons.record_voice_over,
      color: Colors.indigo,
    ),
    OnboardingStep(
      title: 'Privacy & Analytics',
      description: 'Help us improve the app by sharing anonymous usage data.',
      icon: Icons.privacy_tip_outlined,
      color: Colors.teal,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Fixed header with progress indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: (currentStep + 1) / steps.length,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      steps[currentStep].color,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Step ${currentStep + 1} of ${steps.length}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: steps[currentStep].color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        steps[currentStep].icon,
                        size: 60,
                        color: steps[currentStep].color,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Title
                    Text(
                      steps[currentStep].title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    // Description
                    Text(
                      steps[currentStep].description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // Additional content based on step
                    if (currentStep == 4) _buildVoiceSelectionContent(),
                    if (currentStep == 5) _buildPrivacyContent(),

                    // Add some bottom spacing to ensure buttons don't overlap
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Fixed navigation buttons at bottom
            Padding(
              padding: const EdgeInsets.all(24.0),
              child:
                  currentStep == 5 && !showDetailedConsent
                      ? _buildConsentBottomButtons()
                      : Row(
                        children: [
                          if (currentStep > 0)
                            TextButton(
                              onPressed:
                                  isLoading
                                      ? null
                                      : () {
                                        setState(() => currentStep--);
                                      },
                              child: const Text('Back'),
                            ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: isLoading ? null : _handleNextStep,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: steps[currentStep].color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child:
                                isLoading
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                    : Text(
                                      currentStep == steps.length - 1
                                          ? 'Get Started'
                                          : 'Next',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                          ),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyContent() {
    return Column(
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'What we collect:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• App usage patterns',
                  style: TextStyle(fontSize: 14),
                ),
                const Text(
                  '• Feature usage statistics',
                  style: TextStyle(fontSize: 14),
                ),
                const Text(
                  '• Crash reports (anonymous)',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.block, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'We never collect:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Personal information',
                  style: TextStyle(fontSize: 14),
                ),
                const Text('• Reading content', style: TextStyle(fontSize: 14)),
                const Text('• Location data', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.shield, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Your privacy is protected',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Consent Options
        if (showDetailedConsent) ...[
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customize Your Preferences',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose what data you\'re comfortable sharing with us',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                  _buildConsentOption(
                    title: '🔒 Functional (Required)',
                    description:
                        'Essential features like notifications and app functionality',
                    value: true,
                    enabled: false,
                  ),
                  _buildConsentOption(
                    title: '📊 Analytics',
                    description:
                        'Help us improve the app by sharing anonymous usage statistics',
                    value: consentOptions["analytics"] ?? false,
                    enabled: true,
                    onChanged: (value) {
                      setState(() {
                        consentOptions["analytics"] = value;
                      });
                    },
                  ),
                  _buildConsentOption(
                    title: '🎯 Marketing',
                    description:
                        'Personalized content, recommendations, and promotional updates',
                    value: consentOptions["marketing"] ?? false,
                    enabled: true,
                    onChanged: (value) {
                      setState(() {
                        consentOptions["marketing"] = value;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  // Save and Continue button for detailed view
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () async {
                                setState(() {
                                  isLoading = true;
                                });

                                // Save consent and proceed
                                try {
                                  await _handleAnalyticsConsent();
                                  await _completeOnboarding();
                                } catch (e) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                  _showErrorDialog(
                                    'Error',
                                    'Unable to save preferences. Please try again.',
                                  );
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child:
                          isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Save & Continue',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Back to simple view button
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  showDetailedConsent = false;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back, size: 16),
                  const SizedBox(width: 4),
                  const Text('Back to simple view'),
                ],
              ),
            ),
          ),
        ] else ...[
          // Information about the choice - removed buttons since they're now at the bottom
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    'Choose your privacy preferences',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can change these settings anytime in the app',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Quick info about options
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.teal.shade600,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Accept All',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const Text(
                                'Quick setup with all features',
                                style: TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.tune, color: Colors.blue.shade600),
                              const SizedBox(height: 4),
                              const Text(
                                'Customize',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const Text(
                                'Choose specific options',
                                style: TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConsentOption({
    required String title,
    required String description,
    required bool value,
    required bool enabled,
    ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: Colors.teal,
          ),
        ],
      ),
    );
  }

  Future<void> _handleNextStep() async {
    setState(() => isLoading = true);

    try {
      switch (currentStep) {
        case 0:
          // Welcome step - just proceed
          break;
        case 1:
          // Request notification permissions
          await _requestNotificationPermissions();
          break;
        case 2:
          // Request alarm permissions
          await _requestAlarmPermissions();
          break;
        case 3:
          // Request background permissions
          await _requestBackgroundPermissions();
          break;
        case 4:
          // Handle voice preferences
          await _saveVoicePreferences();
          break;
        case 5:
          // Handle analytics consent and finish
          await _handleAnalyticsConsent();
          await _completeOnboarding();
          return;
      }

      // Move to next step
      if (currentStep < steps.length - 1) {
        setState(() => currentStep++);
      }
    } catch (e) {
      _showErrorDialog(
        'Permission Error',
        'Unable to request permissions. You can change these later in Settings.',
      );
      if (currentStep < steps.length - 1) {
        setState(() => currentStep++);
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _requestNotificationPermissions() async {
    // Initialize notification service
    await NotificationService().initNotification();

    // Request notification permission
    final status = await Permission.notification.request();
    print('Notification permission status: $status');
  }

  Future<void> _requestAlarmPermissions() async {
    // Request schedule exact alarm permission (Android 12+)
    if (await Permission.scheduleExactAlarm.isDenied) {
      final status = await Permission.scheduleExactAlarm.request();
      print('Schedule exact alarm permission status: $status');
    }
  }

  Future<void> _requestBackgroundPermissions() async {
    // Request ignore battery optimizations
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      final status = await Permission.ignoreBatteryOptimizations.request();
      print('Battery optimization permission status: $status');
    }
  }

  Future<void> _handleAnalyticsConsent() async {
    // Save consent using the main consent manager
    final consentManager = ConsentManager();
    await consentManager.initialize();

    await consentManager.updateAllConsent({
      ConsentType.analytics:
          consentOptions["analytics"] == true
              ? ConsentState.granted
              : ConsentState.denied,
      ConsentType.adPersonalization:
          consentOptions["marketing"] == true
              ? ConsentState.granted
              : ConsentState.denied,
      ConsentType.adStorage:
          consentOptions["marketing"] == true
              ? ConsentState.granted
              : ConsentState.denied,
      ConsentType.adUserData:
          consentOptions["marketing"] == true
              ? ConsentState.granted
              : ConsentState.denied,
    });
  }

  Future<void> _completeOnboarding() async {
    // Mark onboarding as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    // Navigate to main app
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ReadingsScreen()),
      );
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConsentBottomButtons() {
    return Column(
      children: [
        // Back button (if needed)
        if (currentStep > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed:
                  isLoading
                      ? null
                      : () {
                        setState(() => currentStep--);
                      },
              child: const Text('Back'),
            ),
          ),

        const SizedBox(height: 16),

        // Main consent action buttons
        Row(
          children: [
            // Customize button
            Expanded(
              child: OutlinedButton(
                onPressed:
                    isLoading
                        ? null
                        : () {
                          setState(() {
                            showDetailedConsent = true;
                          });
                        },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.teal, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.tune, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Customize',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Accept All and Get Started button
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed:
                    isLoading
                        ? null
                        : () async {
                          setState(() {
                            consentOptions["analytics"] = true;
                            consentOptions["marketing"] = true;
                            isLoading = true;
                          });

                          // Automatically save consent and proceed
                          try {
                            await _handleAnalyticsConsent();
                            await _completeOnboarding();
                          } catch (e) {
                            setState(() {
                              isLoading = false;
                            });
                            _showErrorDialog(
                              'Error',
                              'Unable to save preferences. Please try again.',
                            );
                          }
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child:
                    isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Accept & Get Started',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Privacy policy note
        Text(
          'By continuing, you agree to our Privacy Policy',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildVoiceSelectionContent() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          'Choose Your Voice Preference',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Select your preferred accent and gender for reading the daily content aloud.',
          style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.3),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Region Selection - More compact
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Accent Preference',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedVoiceRegion = 'US';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              selectedVoiceRegion == 'US'
                                  ? Colors.indigo.shade100
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                selectedVoiceRegion == 'US'
                                    ? Colors.indigo
                                    : Colors.grey[300]!,
                            width: selectedVoiceRegion == 'US' ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text('🇺🇸', style: TextStyle(fontSize: 28)),
                            const SizedBox(height: 6),
                            Text(
                              'USA',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color:
                                    selectedVoiceRegion == 'US'
                                        ? Colors.indigo.shade700
                                        : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedVoiceRegion = 'UK';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              selectedVoiceRegion == 'UK'
                                  ? Colors.indigo.shade100
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                selectedVoiceRegion == 'UK'
                                    ? Colors.indigo
                                    : Colors.grey[300]!,
                            width: selectedVoiceRegion == 'UK' ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text('🇬🇧', style: TextStyle(fontSize: 28)),
                            const SizedBox(height: 6),
                            Text(
                              'UK',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color:
                                    selectedVoiceRegion == 'UK'
                                        ? Colors.indigo.shade700
                                        : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Gender Selection - More compact
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voice Gender',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedVoiceGender = 'Male';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              selectedVoiceGender == 'Male'
                                  ? Colors.indigo.shade100
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                selectedVoiceGender == 'Male'
                                    ? Colors.indigo
                                    : Colors.grey[300]!,
                            width: selectedVoiceGender == 'Male' ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.person,
                              size: 28,
                              color:
                                  selectedVoiceGender == 'Male'
                                      ? Colors.indigo.shade700
                                      : Colors.grey[600],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Male',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color:
                                    selectedVoiceGender == 'Male'
                                        ? Colors.indigo.shade700
                                        : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedVoiceGender = 'Female';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              selectedVoiceGender == 'Female'
                                  ? Colors.indigo.shade100
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                selectedVoiceGender == 'Female'
                                    ? Colors.indigo
                                    : Colors.grey[300]!,
                            width: selectedVoiceGender == 'Female' ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 28,
                              color:
                                  selectedVoiceGender == 'Female'
                                      ? Colors.indigo.shade700
                                      : Colors.grey[600],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Female',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color:
                                    selectedVoiceGender == 'Female'
                                        ? Colors.indigo.shade700
                                        : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Selected preference summary - More compact
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.indigo.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.indigo.shade700, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Selected: ${selectedVoiceRegion == 'US' ? '🇺🇸 USA' : '🇬🇧 UK'} $selectedVoiceGender Voice',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Test Voice Button - More compact
        Center(
          child: ElevatedButton.icon(
            onPressed: _isTestingVoice ? null : _testSelectedVoice,
            icon:
                _isTestingVoice
                    ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Icon(Icons.play_arrow, size: 18),
            label: Text(
              _isTestingVoice ? 'Testing Voice...' : 'Test This Voice',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveVoicePreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Map the user's selection to the actual voice preferences used by the voice selection screen
    String voiceKey;
    if (selectedVoiceRegion == 'US' && selectedVoiceGender == 'Male') {
      voiceKey = 'us_male_voice';
    } else if (selectedVoiceRegion == 'US' && selectedVoiceGender == 'Female') {
      voiceKey = 'us_female_voice';
    } else if (selectedVoiceRegion == 'UK' && selectedVoiceGender == 'Male') {
      voiceKey = 'uk_male_voice';
    } else {
      // UK Female
      voiceKey = 'uk_female_voice';
    }

    // Get the default voice for the selected preference
    // These will be updated by the voice selection screen with the correct index-based voices
    const Map<String, String> defaultVoices = {
      'us_male_voice':
          'en-us-x-iol-local', // Will be set to US Voice 12 by voice selection screen
      'us_female_voice':
          'en-us-x-tpc-local', // Will be set to US Voice 6 by voice selection screen
      'uk_male_voice':
          'en-gb-x-gbb-network', // Will be set to UK Voice 7 by voice selection screen
      'uk_female_voice':
          'en-gb-x-gba-local', // Will be set to UK Voice 10 by voice selection screen
    };

    // Save the selected voice preference
    await prefs.setString(voiceKey, defaultVoices[voiceKey]!);

    // Save the language preference that the TTS service uses
    String languageCode = selectedVoiceRegion == 'US' ? 'en-us' : 'en-gb';
    await prefs.setString('voice_language', languageCode);

    // Save the gender preference that the TTS service uses
    bool isMaleVoice = selectedVoiceGender == 'Male';
    await prefs.setBool('is_male_voice', isMaleVoice);

    // Also save the onboarding selection for future reference
    await prefs.setString('onboarding_voice_region', selectedVoiceRegion);
    await prefs.setString('onboarding_voice_gender', selectedVoiceGender);
    print(
      'Voice preferences saved: $selectedVoiceRegion $selectedVoiceGender ($voiceKey = ${defaultVoices[voiceKey]}, language = $languageCode, is_male_voice = $isMaleVoice)',
    );
  }

  Future<void> _testSelectedVoice() async {
    if (_isTestingVoice) return; // Prevent multiple simultaneous tests

    setState(() {
      _isTestingVoice = true;
    });

    try {
      // Map user selection to voice configuration
      String voiceName;
      String locale;
      String displayText;

      if (selectedVoiceRegion == 'US' && selectedVoiceGender == 'Male') {
        voiceName = 'en-us-x-iol-local';
        locale = 'en-US';
        displayText = 'USA Male Voice';
      } else if (selectedVoiceRegion == 'US' &&
          selectedVoiceGender == 'Female') {
        voiceName = 'en-us-x-tpc-local';
        locale = 'en-US';
        displayText = 'USA Female Voice';
      } else if (selectedVoiceRegion == 'UK' && selectedVoiceGender == 'Male') {
        voiceName = 'en-gb-x-gbb-network';
        locale = 'en-GB';
        displayText = 'UK Male Voice';
      } else {
        // UK Female
        voiceName = 'en-gb-x-gba-local';
        locale = 'en-GB';
        displayText = 'UK Female Voice';
      }

      // Configure TTS with selected voice
      await _testTts.setLanguage(locale);
      await _testTts.setVoice({'name': voiceName, 'locale': locale});

      // Speak test message
      await _testTts.speak(
        'Hello! This is your selected $displayText. I will be reading your daily Alcoholics Anonymous readings and prayers. You can change this voice at any point in the settings',
      );
    } catch (e) {
      print('Error testing voice: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to test voice: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      // Reset testing state after a delay to prevent rapid clicking
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isTestingVoice = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _testTts.stop();
    super.dispose();
  }
}

class OnboardingStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
