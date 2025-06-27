import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class RatingBanner extends StatefulWidget {
  const RatingBanner({super.key});

  @override
  State<RatingBanner> createState() => _RatingBannerState();
}

class _RatingBannerState extends State<RatingBanner> {
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _checkIfShouldShow();
  }

  Future<void> _checkIfShouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    final hasRated = prefs.getBool('has_rated_app') ?? false;
    final dismissedCount = prefs.getInt('rating_banner_dismissed') ?? 0;
    final lastDismissed = prefs.getInt('last_dismissed_timestamp') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Don't show if user has already rated
    if (hasRated) {
      setState(() {
        _isVisible = false;
      });
      return;
    }

    // Don't show if dismissed more than 3 times
    if (dismissedCount >= 3) {
      setState(() {
        _isVisible = false;
      });
      return;
    }

    // If dismissed recently (less than 7 days), don't show
    if (lastDismissed > 0 &&
        (now - lastDismissed) < (7 * 24 * 60 * 60 * 1000)) {
      setState(() {
        _isVisible = false;
      });
      return;
    }
  }

  // Debug method to reset rating state (only visible in debug mode)
  Future<void> _resetRatingState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('has_rated_app');
    await prefs.remove('rating_banner_dismissed');
    await prefs.remove('last_dismissed_timestamp');
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

    // Simple approach: Just open the Play Store directly
    if (kDebugMode) {
      print('Rating Debug: Opening Play Store directly...');
    }

    try {
      await _openPlayStoreDirectly();

      // Mark as rated after successful store opening
      await prefs.setBool('has_rated_app', true);
      setState(() {
        _isVisible = false;
      });

      // Show confirmation message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you! Play Store opened for rating.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Rating Debug: Error opening Play Store: $e');
      }

      // Show error message with manual instructions
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Please search for "AA Daily Readings and Prayers" in the Play Store app to rate us.',
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

  Future<void> _openPlayStoreDirectly() async {
    const String packageName = 'com.aareadingsandprayers.app';

    if (kDebugMode) {
      print(
        'Rating Debug: Attempting to open Play Store for package: $packageName',
      );
    }

    try {
      // Try market:// protocol first (opens Play Store app directly)
      final Uri marketUri = Uri.parse('market://details?id=$packageName');

      if (await canLaunchUrl(marketUri)) {
        if (kDebugMode) {
          print('Rating Debug: Opening with market:// protocol');
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
          'Rating Debug: market:// not available, trying HTTPS URL: $playStoreUrl',
        );
      }

      await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (kDebugMode) {
        print('Rating Debug: URL launching failed with error: $e');
      }

      // Re-throw to let the calling method handle the error
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
                    'Rate on Play Store',
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
