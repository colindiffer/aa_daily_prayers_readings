# Voice Gender Filtering Guide

## Overview

The voice selection screen now properly filters voices by gender according to the specific voice mapping provided. Each dropdown only shows voices of the correct gender.

## Implementation Details

### Voice Gender Mapping

The voices are mapped by their index position in the voice list:

**USA Voices:**
- **Female Voices:** 1, 2, 3, 4, 6, 7, 11, 13, 14, 15, 16
- **Male Voices:** 5, 8, 9, 10, 12, 17

**UK Voices:**
- **Female Voices:** 1, 4, 8, 10, 11, 13
- **Male Voices:** 2, 3, 5, 6, 7, 9, 12

### Default Voice Selections

The system now uses these preferred default voices:

- **USA Male:** Voice 12 (previously Voice 5)
- **USA Female:** Voice 6 (previously Voice 1)
- **UK Male:** Voice 7 (previously Voice 2)
- **UK Female:** Voice 10 (previously Voice 1)

### Key Changes Made

1. **Index-Based Gender Detection:**
   - Replaced complex voice name pattern matching with simple index-based mapping
   - Uses the exact voice positions from your provided list

2. **Simplified Voice Names:**
   - Removed gender labels from voice names to avoid confusion
   - Voice names are now simply "US Voice 1", "US Voice 2", etc.
   - No "Male" or "Female" suffixes in the display names

3. **Gender-Specific Dropdowns:**
   - USA Male dropdown only shows voices 5, 8, 9, 10, 12, 17
   - USA Female dropdown only shows voices 1, 2, 3, 4, 6, 7, 11, 13, 14, 15, 16
   - UK Male dropdown only shows voices 2, 3, 5, 6, 7, 9, 12
   - UK Female dropdown only shows voices 1, 4, 8, 10, 11, 13

4. **Index-Based Default Selection:**
   - System automatically selects the preferred voice by index when available
   - Falls back to technical voice names if index is out of range

### Code Structure

```dart
// Voice gender mapping by index position
static const Map<String, List<int>> voiceGenderByIndex = {
  'us_female_indices': [1, 2, 3, 4, 6, 7, 11, 13, 14, 15, 16],
  'us_male_indices': [5, 8, 9, 10, 12, 17],
  'uk_female_indices': [1, 4, 8, 10, 11, 13],
  'uk_male_indices': [2, 3, 5, 6, 7, 9, 12],
};

// Default voice preferences by index
static const Map<String, int> defaultVoiceIndices = {
  'us_male_voice': 12,   // US Voice 12
  'us_female_voice': 6,  // US Voice 6
  'uk_male_voice': 7,    // UK Voice 7
  'uk_female_voice': 10, // UK Voice 10
};
```

### User Experience

1. **Clear Voice Selection:**
   - Users see only relevant voices for each gender
   - No confusion about which voices are male or female

2. **Consistent Naming:**
   - All voices follow the same naming pattern: "Region Voice Number"
   - Example: "US Voice 12", "UK Voice 7"

3. **Proper Filtering:**
   - Each dropdown is pre-filtered to show only voices of the correct gender
   - Default voices are automatically selected based on preferred indices

4. **Improved Defaults:**
   - US Male defaults to Voice 12 (higher quality)
   - US Female defaults to Voice 6 (better quality)
   - UK Male defaults to Voice 7 (improved sound)
   - UK Female defaults to Voice 10 (enhanced quality)

## Testing

To verify the implementation:

1. Go to Voice Settings from the main menu
2. Check that USA Male dropdown only shows the correct male voices
3. Check that USA Female dropdown only shows the correct female voices
4. Check that UK Male dropdown only shows the correct male voices
5. Check that UK Female dropdown only shows the correct female voices
6. Verify that voice names don't include gender labels
7. Test voice playback to confirm gender matches expectations

## Troubleshooting

**Issue:** Wrong voices showing in gender dropdowns
**Solution:** Check that the voiceGenderByIndex mapping matches your voice list exactly

**Issue:** Voice names still showing gender labels
**Solution:** Verify that _assignFriendlyNames only uses prefix and number

**Issue:** Dropdowns showing no voices
**Solution:** Check that voice indices in the mapping exist in the actual voice list

## Future Updates

To update the voice gender mapping:

1. Update the `voiceGenderByIndex` constant in `voice_selection_screen_new.dart`
2. Add or remove voice indices as needed
3. Test all dropdowns to ensure correct filtering
