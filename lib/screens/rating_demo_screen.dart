import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/rating_banner.dart';

/// Rating Demo Screen
///
/// This screen demonstrates the actual rating banner in action.
/// In demo mode, the banner is always shown regardless of usage conditions.
/// This lets you see and test the real user experience.

class RatingDemoScreen extends StatefulWidget {
  const RatingDemoScreen({super.key});

  @override
  State<RatingDemoScreen> createState() => _RatingDemoScreenState();
}

class _RatingDemoScreenState extends State<RatingDemoScreen> {
  bool _demoModeActive = false;
  String _demoStatus = 'Demo not started';
  final GlobalKey _demoRatingBannerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _activateDemoMode();
  }

  @override
  void dispose() {
    _deactivateDemoMode();
    super.dispose();
  }

  Future<void> _activateDemoMode() async {
    final prefs = await SharedPreferences.getInstance();

    // Store original values to restore later
    await prefs.setBool(
      'demo_mode_backup_has_rated',
      prefs.getBool('has_rated_app') ?? false,
    );
    await prefs.setInt(
      'demo_mode_backup_dismissed',
      prefs.getInt('rating_banner_dismissed') ?? 0,
    );
    await prefs.setInt(
      'demo_mode_backup_timestamp',
      prefs.getInt('last_dismissed_timestamp') ?? 0,
    );
    await prefs.setInt(
      'demo_mode_backup_launches',
      prefs.getInt('app_launch_count') ?? 0,
    );
    await prefs.setInt(
      'demo_mode_backup_first_launch',
      prefs.getInt('first_launch_time') ?? 0,
    );

    // Set demo conditions - banner should show
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setBool('has_rated_app', false);
    await prefs.setInt('rating_banner_dismissed', 0);
    await prefs.remove('last_dismissed_timestamp');
    await prefs.setInt('app_launch_count', 5);
    await prefs.setInt(
      'first_launch_time',
      now - (7 * 24 * 60 * 60 * 1000),
    ); // 7 days ago
    await prefs.setBool('demo_mode_active', true);

    setState(() {
      _demoModeActive = true;
      _demoStatus = 'Demo active - banner should appear above';
    });
  }

  Future<void> _deactivateDemoMode() async {
    final prefs = await SharedPreferences.getInstance();

    // Restore original values
    final originalRated = prefs.getBool('demo_mode_backup_has_rated') ?? false;
    final originalDismissed = prefs.getInt('demo_mode_backup_dismissed') ?? 0;
    final originalTimestamp = prefs.getInt('demo_mode_backup_timestamp') ?? 0;
    final originalLaunches = prefs.getInt('demo_mode_backup_launches') ?? 0;
    final originalFirstLaunch =
        prefs.getInt('demo_mode_backup_first_launch') ?? 0;

    await prefs.setBool('has_rated_app', originalRated);
    await prefs.setInt('rating_banner_dismissed', originalDismissed);
    if (originalTimestamp > 0) {
      await prefs.setInt('last_dismissed_timestamp', originalTimestamp);
    } else {
      await prefs.remove('last_dismissed_timestamp');
    }
    if (originalLaunches > 0) {
      await prefs.setInt('app_launch_count', originalLaunches);
    } else {
      await prefs.remove('app_launch_count');
    }
    if (originalFirstLaunch > 0) {
      await prefs.setInt('first_launch_time', originalFirstLaunch);
    } else {
      await prefs.remove('first_launch_time');
    }

    // Clean up demo mode
    await prefs.remove('demo_mode_active');
    await prefs.remove('demo_mode_backup_has_rated');
    await prefs.remove('demo_mode_backup_dismissed');
    await prefs.remove('demo_mode_backup_timestamp');
    await prefs.remove('demo_mode_backup_launches');
    await prefs.remove('demo_mode_backup_first_launch');
  }

  Future<void> _resetDemo() async {
    await _deactivateDemoMode();
    await Future.delayed(const Duration(milliseconds: 100));
    await _activateDemoMode();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rating System Demo'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _deactivateDemoMode().then((_) {
              Navigator.pop(context);
            });
          },
        ),
      ),
      body: Column(
        children: [
          // This is where the real rating banner appears in DEMO MODE
          RatingBanner(key: _demoRatingBannerKey, isDemoMode: true),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Demo Status Card
                  Card(
                    color:
                        _demoModeActive
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _demoModeActive
                                    ? Icons.play_circle
                                    : Icons.pause_circle,
                                color:
                                    _demoModeActive
                                        ? Colors.green
                                        : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'LIVE RATING DEMO',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _demoModeActive
                                          ? Colors.green.shade800
                                          : Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(_demoStatus),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _resetDemo,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reset Demo Banner'),
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

                  const SizedBox(height: 16),

                  // Instructions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🎯 How to Test the Rating System',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),

                          _buildInstructionStep(
                            '1',
                            'Rating Banner Appears',
                            'The banner should appear at the top of this screen. If not, press "Reset Demo Banner".',
                            Colors.blue,
                          ),

                          _buildInstructionStep(
                            '2',
                            'Test "Share Your Feedback"',
                            'Press the button in the banner. It will first try the platform\'s in-app review (Google Play on Android, App Store on iOS), then fall back to opening the respective store if needed.',
                            Colors.green,
                          ),

                          _buildInstructionStep(
                            '3',
                            'Test Dismiss Behavior',
                            'Press the X button to dismiss. The banner disappears and enters a cooldown period.',
                            Colors.orange,
                          ),

                          _buildInstructionStep(
                            '4',
                            'Reset and Repeat',
                            'Use "Reset Demo Banner" to bring it back and test different scenarios.',
                            Colors.purple,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Behavior explanation
                  Card(
                    color:
                        kDebugMode
                            ? Colors.orange.shade50
                            : Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                kDebugMode
                                    ? Icons.bug_report
                                    : Icons.rocket_launch,
                                color:
                                    kDebugMode ? Colors.orange : Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                kDebugMode
                                    ? 'DEBUG MODE BEHAVIOR'
                                    : 'PRODUCTION MODE BEHAVIOR',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      kDebugMode
                                          ? Colors.orange.shade800
                                          : Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (kDebugMode) ...[
                            const Text(
                              '🔧 In-app review is attempted first (App Store/Play Store compliant)',
                            ),
                            const Text(
                              '🔧 Falls back to App Store/Play Store if in-app review unavailable',
                            ),
                            const Text('🔧 Check console for debug logs'),
                            const Text(
                              '🔧 In-app review may not show in debug/sideloaded apps',
                            ),
                          ] else ...[
                            const Text(
                              '🚀 "Share Your Feedback" shows native rating dialog',
                            ),
                            const Text(
                              '🚀 User can rate 1-5 stars directly in the app',
                            ),
                            const Text(
                              '🚀 Real rating submission to App Store/Play Store',
                            ),
                            const Text(
                              '🚀 This is the actual user experience!',
                            ),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  kDebugMode
                                      ? Colors.orange.shade100
                                      : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              kDebugMode
                                  ? 'Demo shows App Store/Play Store compliant behavior (in-app review first)'
                                  : 'You are seeing the real user experience!',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color:
                                    kDebugMode
                                        ? Colors.orange.shade800
                                        : Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sample content to make it feel like the real app
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sample Reading',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'This demo screen simulates the main app experience where the rating banner would appear. The banner above is the real banner component that users will see.',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'In the actual app, the banner appears on the main readings screen after users have used the app for several days and multiple launches.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(
    String number,
    String title,
    String description,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
