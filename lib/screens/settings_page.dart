import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tts_service.dart';
import '../services/notification_service.dart';

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
  bool _notificationsEnabled = true;
  TimeOfDay _notificationTime =
      const TimeOfDay(hour: 9, minute: 0); // Default 9:00 AM

  @override
  void initState() {
    super.initState();
    _selectedSobrietyDate = widget.sobrietyDate;
    _loadVoiceGenderPreference();
    _loadNotificationPreference();
    _loadNotificationTime();
  }

  Future<void> _loadVoiceGenderPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isMaleVoice = prefs.getBool('is_male_voice') ?? true;
      });
    } catch (e) {
      debugPrint('Error loading voice gender preference: $e');
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
      debugPrint('Error loading notification preference: $e');
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
      debugPrint('Error loading notification time: $e');
    }
  }

  Future<void> _saveNotificationPreference(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('push_notifications_consent', enabled);
      debugPrint('Notification preference saved: $enabled');

      // Schedule or cancel notifications based on preference
      await NotificationService().scheduleDailyNotifications();
    } catch (e) {
      debugPrint('Error saving notification preference: $e');
    }
  }

  Future<void> _saveNotificationTime(TimeOfDay time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_hour', time.hour);
      await prefs.setInt('notification_minute', time.minute);
      debugPrint('Notification time saved: ${time.format(context)}');

      // Reschedule notifications with new time
      await NotificationService().scheduleDailyNotifications();
    } catch (e) {
      debugPrint('Error saving notification time: $e');
    }
  }

  Future<void> _saveVoiceGenderPreference(bool isMale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_male_voice', isMale);
      await widget.ttsService.setVoiceGender(
        isMale ? VoiceGender.male : VoiceGender.female,
        language: 'en-GB', // Always use UK English
      );
      debugPrint('Voice gender saved: ${isMale ? 'Male' : 'Female'}');
    } catch (e) {
      debugPrint('Error saving voice gender: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    // Add voice debug logging
                    await widget.ttsService.debugVoiceSelection();

                    String testText =
                        "This is a test of the ${_isMaleVoice ? 'male' : 'female'} voice.";
                    await widget.ttsService.speak(testText);
                  },
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Test Voice'),
                ),
                const SizedBox(width: 16), // Reset button removed
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
                  final permissionGranted = await NotificationService()
                      .requestNotificationPermission();
                  if (!permissionGranted) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Please enable notifications in your device settings for reminders to work.'),
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
                        fontSize: 16, fontWeight: FontWeight.w500),
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
                        ? DateFormat('dd MMM yyyy')
                            .format(_selectedSobrietyDate!)
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
