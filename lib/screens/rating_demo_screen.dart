import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Rating Demo Screen
///
/// This screen demonstrates the complete app rating system behavior:
///
/// **DEBUG MODE (flutter run):**
/// - In-app review requests complete silently without showing UI
/// - Store links are logged but may not actually open
/// - Perfect for testing logic without user interruption
///
/// **PRODUCTION MODE (release APK/AAB):**
/// - In-app review shows native Android rating dialog
/// - User can rate 1-5 stars directly in the app
/// - Store links open Google Play Store for full reviews
/// - Real user experience with actual rating submission
///
/// **How to test production behavior:**
/// 1. Build release APK: `flutter build apk --release`
/// 2. Install on device: `flutter install`
/// 3. Use this demo screen to test real rating behavior
///
/// **Rating Logic:**
/// - Banner shows after certain app usage patterns
/// - User can dismiss up to 3 times (then hidden for 7 days each time)
/// - Once rated, banner never shows again
/// - Graceful fallbacks if in-app review fails
///
/// **COMMON PRODUCTION ISSUES & FIXES:**
/// - App not published on Play Store: Will show error message
/// - Google Play Store not installed: Falls back to browser
/// - Network issues: Provides manual instructions
/// - In-app review not available: Direct Play Store link used
///
/// **REQUIRED PERMISSIONS (AndroidManifest.xml):**
/// - INTERNET: Required for Play Store links
/// - No special permissions needed for in-app review

class RatingDemoScreen extends StatefulWidget {
  const RatingDemoScreen({super.key});

  @override
  State<RatingDemoScreen> createState() => _RatingDemoScreenState();
}

class _RatingDemoScreenState extends State<RatingDemoScreen> {
  final InAppReview _inAppReview = InAppReview.instance;
  Map<String, dynamic> _ratingState = {};
  List<String> _demoLog = [];

  @override
  void initState() {
    super.initState();
    _loadRatingState();
  }

  Future<void> _loadRatingState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ratingState = {
        'has_rated_app': prefs.getBool('has_rated_app') ?? false,
        'rating_banner_dismissed': prefs.getInt('rating_banner_dismissed') ?? 0,
        'last_dismissed_timestamp':
            prefs.getInt('last_dismissed_timestamp') ?? 0,
        'is_review_available': false,
      };
    });

    // Check if in-app review is available
    final isAvailable = await _inAppReview.isAvailable();
    setState(() {
      _ratingState['is_review_available'] = isAvailable;
    });
  }

  void _addToLog(String message) {
    setState(() {
      _demoLog.insert(
        0,
        '${DateTime.now().toString().substring(11, 19)}: $message',
      );
      if (_demoLog.length > 10) {
        _demoLog.removeLast();
      }
    });
  }

  Future<void> _testInAppReview() async {
    _addToLog('Testing simplified rating system...');

    try {
      // Direct store opening approach - simple and reliable
      const String packageName = 'com.aareadingsandprayers.app';

      // Try market:// protocol first
      final Uri marketUri = Uri.parse('market://details?id=$packageName');

      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
        _addToLog('✅ Opened Play Store with market:// protocol');
      } else {
        // Fallback to HTTPS URL
        const String playStoreUrl =
            'https://play.google.com/store/apps/details?id=$packageName';
        final Uri playStoreUri = Uri.parse(playStoreUrl);

        await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
        _addToLog('✅ Opened Play Store with HTTPS URL');
      }

      // Mark as rated for demo purposes
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_rated_app', true);
      await _loadRatingState();
    } catch (e) {
      _addToLog('❌ Error: $e');
      _addToLog('💡 Check INTERNET permission in AndroidManifest.xml');
      _addToLog('💡 Ensure device has internet connection');
    }
  }

  Future<void> _testOpenStore() async {
    _addToLog('Testing direct store opening...');

    try {
      const String packageName = 'com.aareadingsandprayers.app';

      // Try market:// protocol first
      final Uri marketUri = Uri.parse('market://details?id=$packageName');

      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
        _addToLog('✅ Opened Play Store with market:// protocol');
        return;
      }

      // Fallback to HTTPS URL
      const String playStoreUrl =
          'https://play.google.com/store/apps/details?id=$packageName';
      final Uri playStoreUri = Uri.parse(playStoreUrl);

      await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
      _addToLog('✅ Opened Play Store with HTTPS URL');
    } catch (e) {
      _addToLog('❌ Error opening store: $e');
      _addToLog('💡 Check INTERNET permission in AndroidManifest.xml');
      _addToLog('💡 Ensure Google Play Store is installed');
      _addToLog('💡 Verify device has internet connection');
    }
  }

  Future<void> _resetRatingState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('has_rated_app');
    await prefs.remove('rating_banner_dismissed');
    await prefs.remove('last_dismissed_timestamp');
    await _loadRatingState();
    _addToLog('🔄 Rating state reset');
  }

  Future<void> _simulateDismiss() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedCount = prefs.getInt('rating_banner_dismissed') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    await prefs.setInt('rating_banner_dismissed', dismissedCount + 1);
    await prefs.setInt('last_dismissed_timestamp', now);
    await _loadRatingState();
    _addToLog('👋 Simulated dismiss (count: ${dismissedCount + 1})');
  }

  Widget _buildStateCard() {
    final lastDismissed = _ratingState['last_dismissed_timestamp'] as int;
    final daysSinceDismiss =
        lastDismissed > 0
            ? (DateTime.now().millisecondsSinceEpoch - lastDismissed) /
                (24 * 60 * 60 * 1000)
            : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Rating State',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStateRow(
              'Has Rated App',
              _ratingState['has_rated_app'],
              _ratingState['has_rated_app'] ? Colors.green : Colors.red,
            ),
            _buildStateRow(
              'Banner Dismissed Count',
              _ratingState['rating_banner_dismissed'].toString(),
              _ratingState['rating_banner_dismissed'] >= 3
                  ? Colors.orange
                  : Colors.blue,
            ),
            _buildStateRow(
              'Days Since Last Dismiss',
              daysSinceDismiss.toStringAsFixed(1),
              daysSinceDismiss < 7 ? Colors.orange : Colors.green,
            ),
            _buildStateRow(
              'In-App Review Available',
              _ratingState['is_review_available'],
              _ratingState['is_review_available'] ? Colors.green : Colors.red,
            ),
            _buildStateRow(
              'Current Mode',
              kDebugMode ? 'DEBUG' : 'PRODUCTION',
              kDebugMode ? Colors.orange : Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateRow(String label, dynamic value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                value.toString(),
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Card(
      color: kDebugMode ? Colors.orange.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  kDebugMode ? Icons.bug_report : Icons.rocket_launch,
                  color: kDebugMode ? Colors.orange : Colors.green,
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
                '🔧 In-app review requests complete immediately without UI',
              ),
              const Text('🔧 No actual Play Store rating dialog appears'),
              const Text('🔧 Store links are logged but may not open'),
              const Text(
                '🔧 Perfect for testing logic without user interruption',
              ),
            ] else ...[
              const Text('🚀 In-app review shows native Android rating dialog'),
              const Text('🚀 User can rate directly without leaving the app'),
              const Text('🚀 Store links open Google Play Store'),
              const Text('🚀 Real user rating experience'),
            ],
            const SizedBox(height: 8),
            Text(
              kDebugMode
                  ? 'Build a release APK to test production behavior!'
                  : 'This is the real user experience!',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color:
                    kDebugMode ? Colors.orange.shade700 : Colors.green.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔍 What You\'ll See',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Debug Mode
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bug_report,
                        color: Colors.orange.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'DEBUG MODE (Current)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('• Button press → immediate completion'),
                  const Text('• No visible rating dialog'),
                  const Text('• Console logs show what would happen'),
                  const Text('• Perfect for testing logic'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Production Mode
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.rocket_launch,
                        color: Colors.green.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'PRODUCTION MODE (Release APK)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('• Button press → native rating dialog appears'),
                  const Text('• User sees 1-5 star rating interface'),
                  const Text('• Can submit rating without leaving app'),
                  const Text('• Real rating goes to Google Play Store'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Run build_release.bat to create a production APK and see the real rating experience!',
                      style: TextStyle(fontWeight: FontWeight.w500),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rating System Demo'),
        backgroundColor: kDebugMode ? Colors.orange : Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExplanationCard(),
            const SizedBox(height: 16),
            _buildComparisonCard(),
            const SizedBox(height: 16),
            _buildStateCard(),
            const SizedBox(height: 16),

            // Action Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Rating Actions',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _testInAppReview,
                        icon: const Icon(Icons.star_rate),
                        label: const Text('Test Store Link'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _testOpenStore,
                        icon: const Icon(Icons.store),
                        label: const Text('Test Direct Store Opening'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _simulateDismiss,
                            icon: const Icon(Icons.close),
                            label: const Text('Simulate Dismiss'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _resetRatingState,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset State'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Log
            if (_demoLog.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.terminal, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Demo Log',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:
                              _demoLog
                                  .map(
                                    (log) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Text(
                                        log,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Visual Comparison
            _buildComparisonCard(),
          ],
        ),
      ),
    );
  }
}
