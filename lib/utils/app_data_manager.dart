import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppDataManager {
  static Future<Map<String, dynamic>> loadAppData() async {
    final prefs = await SharedPreferences.getInstance();

    final String selectedVoice = 'en-GB'; // Always use UK English
    final String? sobrietyDateStr = prefs.getString('sobrietyDate');
    final DateTime? sobrietyDate =
        sobrietyDateStr != null ? DateTime.parse(sobrietyDateStr) : null;

    final savedReadings = prefs.getString('readings');
    final List<Map<String, dynamic>> userReadings = savedReadings != null
        ? List<Map<String, dynamic>>.from(json.decode(savedReadings))
        : [];

    return {
      'selectedVoice': selectedVoice,
      'sobrietyDate': sobrietyDate,
      'userReadings': userReadings,
    };
  }

  static Future<void> saveAppData({
    required List<Map<String, dynamic>> userReadings,
    required String selectedVoice,
    required DateTime? sobrietyDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedVoice', selectedVoice);
    if (sobrietyDate != null) {
      prefs.setString('sobrietyDate', sobrietyDate.toIso8601String());
    }
    prefs.setString('readings', json.encode(userReadings));
  }
}
