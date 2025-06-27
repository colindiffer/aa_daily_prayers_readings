import 'package:flutter/material.dart';

class SobrietyTimer extends StatelessWidget {
  final DateTime? sobrietyDate;
  final VoidCallback? onNavigateToSettings;

  const SobrietyTimer({
    required this.sobrietyDate,
    this.onNavigateToSettings,
    super.key,
  });

  String _calculateSobrietyDuration() {
    if (sobrietyDate == null) {
      return 'Set your sobriety date in Settings';
    }

    final now = DateTime.now();
    final duration = now.difference(sobrietyDate!);
    final years = duration.inDays ~/ 365;
    final months = (duration.inDays % 365) ~/ 30;
    final days = (duration.inDays % 365) % 30;

    return '$years Years, $months Months, $days Days';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade300,
      padding: const EdgeInsets.all(8.0),
      width: double.infinity,
      child:
          sobrietyDate == null && onNavigateToSettings != null
              ? GestureDetector(
                onTap: onNavigateToSettings,
                child: Text(
                  'Set your sobriety date in Settings',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
              : Text(
                _calculateSobrietyDuration(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
    );
  }
}
