import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class RatingBanner extends StatefulWidget {
  final Key? widgetKey;
  final bool isDemoMode;

  const RatingBanner({super.key, this.widgetKey, this.isDemoMode = false});

  @override
  State<RatingBanner> createState() => _RatingBannerState();
}

// Global key for main app instance (only one should exist at a time)
final GlobalKey<_RatingBannerState> ratingBannerKey =
    GlobalKey<_RatingBannerState>();

class _RatingBannerState extends State<RatingBanner> {
  bool _isVisible = false; // Default to hidden until conditions are met

  @override
  void initState() {
    super.initState();
    _checkIfShouldShow();
  }

  // Method to force refresh the banner state (can be called externally)
  void refreshBannerState() {
    _checkIfShouldShow();
  }

  Future<void> _checkIfShouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    final hasRated = prefs.getBool('has_rated_app') ?? false;
    final dismissedCount = prefs.getInt('rating_banner_dismissed') ?? 0;
    final lastDismissed = prefs.getInt('last_dismissed_timestamp') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (kDebugMode) {
      print('RatingBanner: Checking if should show...');
      print('  hasRated: $hasRated');
      print('  dismissedCount: $dismissedCount');
      print('  lastDismissed: $lastDismissed');
      print('  isDemoMode: ${widget.isDemoMode}');
    }

    // In demo mode, always show the banner for testing
    if (widget.isDemoMode) {
      if (kDebugMode) print('RatingBanner: Demo mode - always showing');
      setState(() {
        _isVisible = true;
      });
      return;
    }

    // Don't show if user has already rated
    if (hasRated) {
      if (kDebugMode)
        print('RatingBanner: Not showing - user has already rated');
      setState(() {
        _isVisible = false;
      });
      return;
    }

    // Don't show if dismissed more than 3 times
    if (dismissedCount >= 3) {
      if (kDebugMode)
        print(
          'RatingBanner: Not showing - dismissed too many times ($dismissedCount)',
        );
      setState(() {
        _isVisible = false;
      });
      return;
    }

    // If dismissed recently (less than 7 days), don't show
    if (lastDismissed > 0 &&
        (now - lastDismissed) < (7 * 24 * 60 * 60 * 1000)) {
      if (kDebugMode) print('RatingBanner: Not showing - dismissed recently');
      setState(() {
        _isVisible = false;
      });
      return;
    }

    // USAGE-BASED LOGIC: Only show after user has used the app sufficiently
    final appLaunchCount = prefs.getInt('app_launch_count') ?? 0;
    final firstLaunchTime = prefs.getInt('first_launch_time') ?? 0;

    if (kDebugMode) {
      print('  appLaunchCount: $appLaunchCount');
      print('  firstLaunchTime: $firstLaunchTime');
    }

    // If this is first launch, record it and don't show banner
    if (firstLaunchTime == 0) {
      if (kDebugMode)
        print(
          'RatingBanner: First launch detected - recording and not showing',
        );
      await prefs.setInt('first_launch_time', now);
      await prefs.setInt('app_launch_count', 1);
      setState(() {
        _isVisible = false;
      });
      return;
    }

    // Increment launch count (safe increment with null check)
    final newLaunchCount = (appLaunchCount) + 1;
    await prefs.setInt('app_launch_count', newLaunchCount);

    // Don't show banner until user has:
    // - Used app at least 3 times AND
    // - Had app for at least 2 days
    final daysSinceFirstLaunch =
        (now - firstLaunchTime) / (24 * 60 * 60 * 1000);

    if (kDebugMode) {
      print('  daysSinceFirstLaunch: $daysSinceFirstLaunch');
      print('  newLaunchCount: $newLaunchCount');
    }

    if (newLaunchCount < 3 || daysSinceFirstLaunch < 2) {
      if (kDebugMode)
        print(
          'RatingBanner: Not showing - usage conditions not met (launches: $newLaunchCount, days: $daysSinceFirstLaunch)',
        );
      setState(() {
        _isVisible = false;
      });
      return;
    }

    // All conditions met - show the banner
    if (kDebugMode) print('RatingBanner: All conditions met - SHOWING BANNER!');
    setState(() {
      _isVisible = true;
    });
  }

  // Debug method to reset rating state (only visible in debug mode)
  Future<void> _resetRatingState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('has_rated_app');
    await prefs.remove('rating_banner_dismissed');
    await prefs.remove('last_dismissed_timestamp');

    // For demo purposes, also set usage conditions to show banner immediately
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(
      'first_launch_time',
      now - (3 * 24 * 60 * 60 * 1000),
    ); // 3 days ago
    await prefs.setInt('app_launch_count', 5); // 5 launches

    setState(() {
      _isVisible = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rating state reset! Banner will show again.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _handleRateApp() async {
    final prefs = await SharedPreferences.getInstance();

    if (kDebugMode) {
      print('Rating: Requesting in-app review...');
    }

    // GOOGLE PLAY COMPLIANT FLOW: Always use in-app review API first
    try {
      // STEP 1: Try Google's In-App Review API (REQUIRED by guidelines)
      final InAppReview inAppReview = InAppReview.instance;

      if (await inAppReview.isAvailable()) {
        if (kDebugMode) {
          print('Rating: In-app review available, requesting...');
        }

        // This shows the native Google Play in-app rating dialog
        await inAppReview.requestReview();

        if (kDebugMode) {
          print('Rating: In-app review request completed');
        }

        // Mark as rated and hide banner
        await prefs.setBool('has_rated_app', true);
        setState(() {
          _isVisible = false;
        });

        // Show confirmation for demo mode
        if (widget.isDemoMode && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'In-app review requested! (May not be visible in debug)',
              ),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 3),
            ),
          );
        }

        return; // Success! Don't fall back to Play Store
      }

      if (kDebugMode) {
        print(
          'Rating: In-app review not available, falling back to Play Store',
        );
      }

      // STEP 2: Only fall back to App Store/Play Store if in-app review fails
      await _openAppStoreDirectly();

      // Mark as rated after successful store opening
      await prefs.setBool('has_rated_app', true);
      setState(() {
        _isVisible = false;
      });

      // Show confirmation message
      if (mounted) {
        final storeName = Platform.isIOS ? 'App Store' : 'Play Store';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thank you! $storeName opened for rating.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Rating: Error in rating flow: $e');
      }

      // Show error message with manual instructions
      if (mounted) {
        final storeName = Platform.isIOS ? 'App Store' : 'Play Store';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please search for "AA Daily Readings and Prayers" in the $storeName app to rate us.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }

      // Still mark as "rated" to avoid repeated prompts
      await prefs.setBool('has_rated_app', true);
      setState(() {
        _isVisible = false;
      });
    }
  }

  Future<void> _openAppStoreDirectly() async {
    if (kDebugMode) {
      final storeName = Platform.isIOS ? 'App Store' : 'Play Store';
      print('Rating: Attempting to open $storeName');
    }

    try {
      if (Platform.isIOS) {
        // iOS App Store URLs
        await _openIOSAppStore();
      } else {
        // Android Play Store URLs
        await _openAndroidPlayStore();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Rating: Store opening failed with error: $e');
      }
      // Re-throw to let the calling method handle the error
      rethrow;
    }
  }

  Future<void> _openIOSAppStore() async {
    // Replace with your actual App Store ID when you publish to iOS
    const String appStoreId =
        '123456789'; // TODO: Replace with real App Store ID

    if (kDebugMode) {
      print('Rating: Opening iOS App Store for app ID: $appStoreId');
    }

    try {
      // Try App Store app:// protocol first (opens App Store app directly)
      final Uri appStoreUri = Uri.parse(
        'itms-apps://itunes.apple.com/app/id$appStoreId?action=write-review',
      );

      if (await canLaunchUrl(appStoreUri)) {
        if (kDebugMode) {
          print('Rating: Opening with itms-apps:// protocol');
        }
        await launchUrl(appStoreUri, mode: LaunchMode.externalApplication);
        return;
      }

      // Fallback to HTTPS URL (opens in Safari if App Store app not available)
      final String appStoreUrl =
          'https://apps.apple.com/app/id$appStoreId?action=write-review';
      final Uri appStoreHttpsUri = Uri.parse(appStoreUrl);

      if (kDebugMode) {
        print(
          'Rating: itms-apps:// not available, trying HTTPS URL: $appStoreUrl',
        );
      }

      await launchUrl(appStoreHttpsUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (kDebugMode) {
        print('Rating: iOS App Store opening failed: $e');
      }
      rethrow;
    }
  }

  Future<void> _openAndroidPlayStore() async {
    const String packageName = 'com.aareadingsandprayers.app';

    if (kDebugMode) {
      print('Rating: Opening Android Play Store for package: $packageName');
    }

    try {
      // Try market:// protocol first (opens Play Store app directly)
      final Uri marketUri = Uri.parse('market://details?id=$packageName');

      if (await canLaunchUrl(marketUri)) {
        if (kDebugMode) {
          print('Rating: Opening with market:// protocol');
        }
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
        return;
      }

      // Fallback to HTTPS URL (opens in browser if Play Store app not available)
      const String playStoreUrl =
          'https://play.google.com/store/apps/details?id=$packageName';
      final Uri playStoreUri = Uri.parse(playStoreUrl);

      if (kDebugMode) {
        print(
          'Rating: market:// not available, trying HTTPS URL: $playStoreUrl',
        );
      }

      await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (kDebugMode) {
        print('Rating: Android Play Store opening failed: $e');
      }
      rethrow;
    }
  }

  Future<void> _handleDismiss() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedCount = prefs.getInt('rating_banner_dismissed') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    await prefs.setInt('rating_banner_dismissed', dismissedCount + 1);
    await prefs.setInt('last_dismissed_timestamp', now);

    setState(() {
      _isVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Enjoying AA Daily Readings & Prayers?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                onPressed: _handleDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Help others discover this app by leaving a rating and review on Google Play. Your feedback helps us improve!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _handleRateApp,
                  icon: const Icon(Icons.star_rate, color: Colors.amber),
                  label: const Text(
                    'Share Your Feedback',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: _handleDismiss,
                child: const Text(
                  'Maybe Later',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Debug reset button (only in debug mode)
              if (kDebugMode)
                TextButton(
                  onPressed: _resetRatingState,
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
