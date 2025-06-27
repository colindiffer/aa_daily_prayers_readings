import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tts_service.dart';
import '../services/notification_service.dart';
import 'voice_selection_screen_new.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
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
