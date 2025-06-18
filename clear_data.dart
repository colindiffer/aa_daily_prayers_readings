import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('Clearing saved readings data...');
  final prefs = await SharedPreferences.getInstance();

  // Clear all readings data
  await prefs.remove('readings');
  await prefs.remove('userReadings');

  print('✅ Cleared saved readings data');
  print('App should now load default readings on next launch');
}
