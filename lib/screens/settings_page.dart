import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tts_service.dart';
import '../services/notification_service.dart';
import '../widgets/rating_banner.dart';
import 'voice_selection_screen_new.dart';
import 'rating_demo_screen.dart';

class SettingsPage extends StatefulWidget {
  final DateTime? sobrietyDate;
  final Function(DateTime?) onSettingsChanged;
  final TTSService ttsService;

  const SettingsPage({
    required this.sobrietyDate,
    required this.onSettingsChanged,
    required this.ttsService,
    super.key,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  DateTime? _selectedSobrietyDate;
  bool _isMaleVoice = true;
  String _selectedLanguage = 'en-gb'; // Default to UK English
  bool _notificationsEnabled = true;
  TimeOfDay _notificationTime = const TimeOfDay(
    hour: 9,
    minute: 0,
  ); // Default 9:00 AM

  @override
  void initState() {
    super.initState();
    _selectedSobrietyDate = widget.sobrietyDate;
    _loadVoiceGenderPreference();
    _loadLanguagePreference();
    _loadNotificationPreference();
    _loadNotificationTime();
  }

  Future<void> _loadVoiceGenderPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isMaleVoice = prefs.getBool('is_male_voice') ?? true;
      });

      // Apply the loaded voice preference to TTS service
      await widget.ttsService.setVoiceGender(
        _isMaleVoice ? VoiceGender.male : VoiceGender.female,
        language: _selectedLanguage,
      );
    } catch (e) {
      // Error loading voice gender preference
    }
  }

  Future<void> _loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _selectedLanguage = prefs.getString('voice_language') ?? 'en-gb';
      });
    } catch (e) {
      // Error loading language preference
    }
  }

  Future<void> _loadNotificationPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationsEnabled =
            prefs.getBool('push_notifications_consent') ?? true;
      });
    } catch (e) {
      // Error loading notification preference
    }
  }

  Future<void> _loadNotificationTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hour = prefs.getInt('notification_hour') ?? 9;
      final minute = prefs.getInt('notification_minute') ?? 0;
      setState(() {
        _notificationTime = TimeOfDay(hour: hour, minute: minute);
      });
    } catch (e) {
      // Error loading notification time
    }
  }

  Future<void> _saveNotificationPreference(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('push_notifications_consent', enabled);

      // Schedule or cancel notifications based on preference
      await NotificationService().scheduleDailyNotifications();
    } catch (e) {
      // Error saving notification preference
    }
  }

  Future<void> _saveNotificationTime(TimeOfDay time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_hour', time.hour);
      await prefs.setInt('notification_minute', time.minute);

      // Reschedule notifications with new time
      await NotificationService().scheduleDailyNotifications();
    } catch (e) {
      // Error saving notification time
    }
  }

  Future<void> _saveVoiceGenderPreference(bool isMale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_male_voice', isMale);

      await widget.ttsService.setVoiceGender(
        isMale ? VoiceGender.male : VoiceGender.female,
        language: _selectedLanguage,
      );
    } catch (e) {
      // Error saving voice gender preference
    }
  }

  Future<void> _saveLanguagePreference(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('voice_language', language);

      setState(() {
        _selectedLanguage = language;
      });

      await widget.ttsService.setVoiceGender(
        _isMaleVoice ? VoiceGender.male : VoiceGender.female,
        language: language,
      );
    } catch (e) {
      // Error saving language preference
    }
  }

  Future<void> _triggerRatingBannerDemo() async {
    try {
      if (kDebugMode) print('Demo: Resetting rating banner state...');

      // Reset rating state to make banner appear
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('has_rated_app');
      await prefs.remove('rating_banner_dismissed');
      await prefs.remove('last_dismissed_timestamp');

      // Set usage conditions to trigger banner display
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(
        'first_launch_time',
        now - (3 * 24 * 60 * 60 * 1000),
      ); // 3 days ago
      await prefs.setInt(
        'app_launch_count',
        5,
      ); // 5 launches (triggers display)

      if (kDebugMode) {
        print('Demo: Reset complete');
        print('  first_launch_time set to 3 days ago');
        print('  app_launch_count set to 5');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Rating banner state reset! Navigate back to main screen to see the banner.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );

        // Automatically navigate back to show the banner
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop();
            // Trigger refresh of the rating banner
            Future.delayed(const Duration(milliseconds: 100), () {
              if (kDebugMode)
                print('Demo: Triggering rating banner refresh...');
              ratingBannerKey.currentState?.refreshBannerState();
            });
          }
        });
      }
    } catch (e) {
      if (kDebugMode) print('Demo: Error resetting rating state: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting rating state: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Voice Accent',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('🇺🇸 US English'),
                    value: 'en-us',
                    groupValue: _selectedLanguage,
                    onChanged: (String? value) async {
                      if (value != null) {
                        await _saveLanguagePreference(value);
                      }
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('🇬🇧 UK English'),
                    value: 'en-gb',
                    groupValue: _selectedLanguage,
                    onChanged: (String? value) async {
                      if (value != null) {
                        await _saveLanguagePreference(value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Voice Gender',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Male'),
                    value: true,
                    groupValue: _isMaleVoice,
                    onChanged: (bool? value) async {
                      if (value != null) {
                        setState(() {
                          _isMaleVoice = value;
                        });
                        await _saveVoiceGenderPreference(value);
                      }
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Female'),
                    value: false,
                    groupValue: _isMaleVoice,
                    onChanged: (bool? value) async {
                      if (value != null) {
                        setState(() {
                          _isMaleVoice = value;
                        });
                        await _saveVoiceGenderPreference(value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    String accent =
                        _selectedLanguage == 'en-us' ? 'American' : 'British';
                    String gender = _isMaleVoice ? 'male' : 'female';
                    String testText =
                        "This is a test of the $accent $gender voice.";
                    await widget.ttsService.speak(testText);
                  },
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Test Voice'),
                ),
                const SizedBox(width: 16),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VoiceSelectionScreenNew(),
                      ),
                    );

                    if (result != null && result is Map<String, String>) {
                      // Save the selected voice names for future use
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString(
                        'selected_male_voice',
                        result['maleVoice'] ?? '',
                      );
                      await prefs.setString(
                        'selected_female_voice',
                        result['femaleVoice'] ?? '',
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Voice preferences saved!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.settings_voice),
                  label: const Text('Voice Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text(
                'Receive daily reading notifications and important updates',
              ),
              value: _notificationsEnabled,
              onChanged: (bool value) async {
                if (value) {
                  // Request notification permission when enabling notifications
                  final permissionGranted =
                      await NotificationService()
                          .requestNotificationPermission();
                  if (!permissionGranted) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enable notifications in your device settings for reminders to work.',
                          ),
                          duration: Duration(seconds: 4),
                        ),
                      );
                    }
                  }
                }

                setState(() {
                  _notificationsEnabled = value;
                });
                await _saveNotificationPreference(value);
              },
            ),
            if (_notificationsEnabled) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notification Time',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  Text(
                    _notificationTime.format(context),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () async {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: _notificationTime,
                      );
                      if (pickedTime != null) {
                        setState(() {
                          _notificationTime = pickedTime;
                        });
                        await _saveNotificationTime(pickedTime);
                      }
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Sobriety Date',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedSobrietyDate != null
                        ? DateFormat(
                          'dd MMM yyyy',
                        ).format(_selectedSobrietyDate!)
                        : 'No date selected',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedSobrietyDate ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() => _selectedSobrietyDate = pickedDate);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Debug/Demo section (only visible in debug mode)
            if (kDebugMode) ...[
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Demo & Testing',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rating Banner Demo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Reset the rating state and trigger the banner to appear for testing.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _triggerRatingBannerDemo,
                          icon: const Icon(Icons.star_rate),
                          label: const Text('Show Rating Banner'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Rating Demo Screen Access
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Complete Rating System Testing',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Access the comprehensive rating system demo to test all features including in-app review API, Play Store links, and state management.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RatingDemoScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.science),
                          label: const Text('Open Rating Demo Screen'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            Center(
              child: ElevatedButton(
                onPressed: () {
                  widget.onSettingsChanged(_selectedSobrietyDate);
                  Navigator.pop(context);
                },
                child: const Text('Save Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
