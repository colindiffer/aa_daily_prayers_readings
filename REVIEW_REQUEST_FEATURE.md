# Review Request Feature Documentation

## Overview
The review request feature encourages users to leave a review on Google Play Store to help promote the AA Readings & Prayers app. The feature is designed to be non-intrusive and respectful of user preferences.

## Timing Logic

### Initial Delay
- **24 hours** after the user first opens the app
- This ensures users have time to experience the app before being asked to review

### Decline Handling
- If user clicks "Maybe Later", the banner won't appear for **14 days**
- This prevents spam and respects user choice

### Permanent Dismissal
- Once user clicks "Rate App" and is taken to Google Play, the banner never appears again
- User preference is permanently stored

## Implementation Details

### Files Created

1. **`lib/services/review_request_service.dart`**
   - Core service managing timing logic and preferences
   - Handles SharedPreferences storage
   - Opens Google Play Store for reviews
   - Provides statistics and debug functions

2. **`lib/widgets/review_request_banner.dart`**
   - Animated banner widget with smooth slide-in/fade animations
   - Professional design with star icon and clear call-to-action
   - Two action buttons: "Maybe Later" and "Rate App"

3. **`lib/screens/review_request_debug_screen.dart`**
   - Debug interface for testing review request functionality
   - Shows current statistics and timing information
   - Allows resetting data for testing purposes
   - Only accessible in debug builds

### Integration Points

1. **Main App (`lib/main.dart`)**
   - ReviewRequestService.initialize() called on app startup
   - Sets first open date if not already recorded

2. **Readings Screen (`lib/screens/readings_screen.dart`)**
   - ReviewRequestBanner widget added to the UI Stack
   - Positioned at the top of the screen
   - Appears over content but below scroll arrows

3. **Settings Page (`lib/screens/settings_page.dart`)**
   - Debug option added for development/testing
   - Only visible in debug builds

## User Experience

### Banner Appearance
- Slides in from top with smooth animation
- Professional blue gradient design
- Star icon for visual appeal
- Clear, friendly messaging

### User Actions
1. **"Maybe Later"**
   - Records decline timestamp
   - Hides banner with reverse animation
   - Sets 14-day cooldown period

2. **"Rate App"**
   - Opens Google Play Store app page
   - Records user has reviewed (permanent)
   - Hides banner permanently

## Technical Features

### Data Storage
- Uses SharedPreferences for persistent storage
- Stores timestamps as ISO8601 strings
- Tracks review status and request count

### Error Handling
- All operations wrapped in try-catch blocks
- Graceful degradation if storage fails
- Logging integration for debugging

### URL Handling
- Uses url_launcher package to open Google Play
- Fallback handling if store can't be opened
- External application launch mode

## Testing

### Debug Screen Features
- View current timing statistics
- Test review page opening
- Reset all data for fresh testing
- Initialize service manually

### Testing Scenarios
1. **Fresh Install**: Banner should not appear for 24 hours
2. **After 24 Hours**: Banner should appear on app open
3. **Decline Action**: Banner should not appear for 14 days
4. **Review Action**: Banner should never appear again
5. **Multiple Declines**: Banner continues to respect 14-day periods

## Configuration

### Timing Constants
```dart
static const int initialDelayHours = 24; // 24 hours after first open
static const int declineDelayDays = 14; // 14 days after decline
```

### Google Play URL
```dart
static const String googlePlayUrl = 'https://play.google.com/store/apps/details?id=com.aareadingsandprayers.app';
```

## Analytics Integration

### Logged Events
- Review request shown
- User declined review
- User chose to review
- Review page opened successfully

### Statistics Tracked
- First open date
- Last decline date
- Review completion status
- Total request count

## Best Practices Implemented

1. **Respectful Timing**: 24-hour delay allows users to experience the app
2. **Non-Spam**: 14-day cooldown prevents harassment
3. **Permanent Choice**: Once reviewed, never asks again
4. **Graceful Animations**: Smooth slide-in/out animations
5. **Error Resilience**: Robust error handling throughout
6. **Debug Support**: Comprehensive testing tools
7. **Analytics Ready**: Built-in event tracking
8. **Professional Design**: Polished UI matching app theme

## Future Enhancements

### Potential Improvements
- A/B testing different messaging
- Variable timing based on app usage
- Integration with app rating APIs
- Localization for different languages
- Custom analytics dashboard

### Customization Options
- Adjustable timing constants
- Custom banner designs
- Different messaging strategies
- Platform-specific implementations

## Deployment Notes

### Production Checklist
- [x] Review request service initialized in main.dart
- [x] Banner integrated into main screen
- [x] Google Play URL configured correctly
- [x] Error handling implemented
- [x] Debug tools available for testing
- [x] Analytics events ready
- [x] User preferences respected

### App Store Considerations
- Review requests comply with Google Play policies
- No manipulation or incentivization
- User can permanently dismiss
- Natural integration with app flow

---

The review request feature is now fully implemented and ready for production use. It follows platform best practices and provides a respectful way to encourage user reviews while maintaining a positive user experience.
