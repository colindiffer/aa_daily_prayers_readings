import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/logger_service.dart';

class ReviewRequestService {
  static const String _firstOpenDateKey = 'first_open_date';
  static const String _lastDeclineDateKey = 'last_decline_date';
  static const String _hasReviewedKey = 'has_reviewed';
  static const String _reviewRequestCountKey = 'review_request_count';
  
  // Timing constants
  static const int initialDelayHours = 24; // 24 hours after first open
  static const int declineDelayDays = 14; // 14 days after decline
  
  // Google Play Store URL for the app
  static const String googlePlayUrl = 'https://play.google.com/store/apps/details?id=com.aareadingsandprayers.app';

  /// Initialize the service - call this on first app launch
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Set first open date if not already set
      if (!prefs.containsKey(_firstOpenDateKey)) {
        await prefs.setString(_firstOpenDateKey, DateTime.now().toIso8601String());
        LoggerService().log('ReviewRequestService: First open date set');
      }
    } catch (e) {
      LoggerService().log('ReviewRequestService initialization error: $e');
    }
  }

  /// Check if the review request should be shown
  static Future<bool> shouldShowReviewRequest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Don't show if user has already reviewed
      if (prefs.getBool(_hasReviewedKey) ?? false) {
        return false;
      }
      
      final now = DateTime.now();
      
      // Check if 24 hours have passed since first open
      final firstOpenDateStr = prefs.getString(_firstOpenDateKey);
      if (firstOpenDateStr == null) {
        // Initialize if somehow missing
        await initialize();
        return false;
      }
      
      final firstOpenDate = DateTime.parse(firstOpenDateStr);
      final hoursSinceFirstOpen = now.difference(firstOpenDate).inHours;
      
      if (hoursSinceFirstOpen < initialDelayHours) {
        return false;
      }
      
      // Check if user declined recently
      final lastDeclineDateStr = prefs.getString(_lastDeclineDateKey);
      if (lastDeclineDateStr != null) {
        final lastDeclineDate = DateTime.parse(lastDeclineDateStr);
        final daysSinceDecline = now.difference(lastDeclineDate).inDays;
        
        if (daysSinceDecline < declineDelayDays) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      LoggerService().log('Error checking review request status: $e');
      return false;
    }
  }

  /// Record that the user declined the review request
  static Future<void> recordDecline() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastDeclineDateKey, DateTime.now().toIso8601String());
      
      // Increment request count for analytics
      final currentCount = prefs.getInt(_reviewRequestCountKey) ?? 0;
      await prefs.setInt(_reviewRequestCountKey, currentCount + 1);
      
      LoggerService().log('ReviewRequestService: User declined review request');
    } catch (e) {
      LoggerService().log('Error recording review decline: $e');
    }
  }

  /// Record that the user chose to review (so we don't ask again)
  static Future<void> recordReviewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasReviewedKey, true);
      
      // Increment request count for analytics
      final currentCount = prefs.getInt(_reviewRequestCountKey) ?? 0;
      await prefs.setInt(_reviewRequestCountKey, currentCount + 1);
      
      LoggerService().log('ReviewRequestService: User chose to review');
    } catch (e) {
      LoggerService().log('Error recording review action: $e');
    }
  }

  /// Open the Google Play Store for review
  static Future<void> openReviewPage() async {
    try {
      final uri = Uri.parse(googlePlayUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        await recordReviewed();
      } else {
        LoggerService().log('Could not launch review URL: $googlePlayUrl');
      }
    } catch (e) {
      LoggerService().log('Error opening review page: $e');
    }
  }

  /// Get statistics for debugging/analytics
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final firstOpenDateStr = prefs.getString(_firstOpenDateKey);
      final lastDeclineDateStr = prefs.getString(_lastDeclineDateKey);
      final hasReviewed = prefs.getBool(_hasReviewedKey) ?? false;
      final requestCount = prefs.getInt(_reviewRequestCountKey) ?? 0;
      
      return {
        'firstOpenDate': firstOpenDateStr,
        'lastDeclineDate': lastDeclineDateStr,
        'hasReviewed': hasReviewed,
        'requestCount': requestCount,
        'shouldShow': await shouldShowReviewRequest(),
      };
    } catch (e) {
      LoggerService().log('Error getting review request statistics: $e');
      return {};
    }
  }

  /// Reset all review request data (for testing purposes)
  static Future<void> resetData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_firstOpenDateKey);
      await prefs.remove(_lastDeclineDateKey);
      await prefs.remove(_hasReviewedKey);
      await prefs.remove(_reviewRequestCountKey);
      
      LoggerService().log('ReviewRequestService: All data reset');
    } catch (e) {
      LoggerService().log('Error resetting review request data: $e');
    }
  }
}
