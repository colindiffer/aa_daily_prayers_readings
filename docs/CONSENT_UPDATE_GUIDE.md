# 🍪 Updated Consent Screen - Quick Test Guide

## What Changed
The onboarding consent screen now has a cleaner bottom navigation with:
- **"Accept & Get Started"** - Accepts all cookies and completes onboarding
- **"Customize"** - Shows detailed consent options

## How to Test

### 1. Reset Onboarding (if needed)
If you've already completed onboarding, you'll need to reset it to see the new consent screen:

```dart
// Option 1: Add this debug button temporarily
// Or use the Rating Demo screen to reset preferences

// Option 2: Manually clear shared preferences
SharedPreferences prefs = await SharedPreferences.getInstance();
await prefs.remove('onboarding_completed');
```

### 2. Navigate to Consent Step
1. Launch the app (should show onboarding if reset)
2. Go through steps: Welcome → Notifications → Alarms → Background → **Privacy & Analytics**
3. On the Privacy step, you'll see the new layout

### 3. Test Both Flows

**"Accept & Get Started" Flow:**
- Click the primary green button
- Should accept all analytics and marketing consent
- Should complete onboarding and navigate to main app
- Loading spinner should appear during processing

**"Customize" Flow:**
- Click the secondary "Customize" button  
- Should show detailed consent toggles
- Can toggle Analytics and Marketing individually
- "Save & Continue" button to complete onboarding
- "Back to simple view" to return to quick choice

## UI Changes Summary
✅ Moved consent buttons to bottom navigation area
✅ "Accept & Get Started" prominently displayed as primary action
✅ "Customize" as secondary action next to it
✅ Removed duplicate buttons from content area
✅ Added visual info cards explaining both options
✅ Privacy policy note at bottom
✅ Consistent loading states and error handling

The consent experience is now more intuitive with clear primary/secondary actions! 🎉
