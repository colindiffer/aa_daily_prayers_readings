# Voice Gender Filtering Implementation

## Summary
Successfully implemented gender-based voice filtering for the Voice Settings screen. Each dropdown now only shows voices of the correct gender.

## Changes Made

### 1. Voice Gender Mapping
- Added comprehensive `voiceGenderMapping` with known TTS voice patterns
- Supports both US (en-us-x-*) and UK (en-gb-x-*) voice naming conventions
- Maps specific voice names to 'male' or 'female'

### 2. Gender Detection Method
- Added `_getVoiceGender()` method to determine voice gender
- Uses mapping table first, then fallback pattern matching
- Handles unknown voices gracefully

### 3. Voice List Separation
- Created separate lists for each gender/region combination:
  - `_usMaleVoices` 
  - `_usFemaleVoices`
  - `_ukMaleVoices`
  - `_ukFemaleVoices`

### 4. Updated Friendly Names
- Modified `_assignFriendlyNames()` to include gender in display names
- Names now show as "US Voice 1 Male", "US Voice 2 Female", etc.
- Makes it clear which voices are which gender

### 5. Dropdown Filtering
- USA Male dropdown only shows male US voices
- USA Female dropdown only shows female US voices  
- UK Male dropdown only shows male UK voices
- UK Female dropdown only shows female UK voices

## Voice Name Mapping Example

Based on the provided mapping:

### US Voices:
**Male Voices:** Voice 5, Voice 8, Voice 9, Voice 10, Voice 12, Voice 17
**Female Voices:** Voice 1, Voice 2, Voice 3, Voice 4, Voice 6, Voice 7, Voice 11, Voice 13, Voice 14, Voice 15, Voice 16

### UK Voices:
**Male Voices:** Voice 2, Voice 3, Voice 6, Voice 7, Voice 9, Voice 12
**Female Voices:** Voice 1, Voice 4, Voice 5, Voice 8, Voice 10, Voice 11, Voice 13

## Technical Implementation

### Voice Gender Detection Logic:
1. Check explicit mapping table first
2. Use pattern matching for unknown voices:
   - US: `en-us-x-io*` = male, `en-us-x-tp*` = female
   - UK: `en-gb-x-gb*` containing 'a' = female, others = male
3. Check for gender keywords in voice names
4. Default to 'unknown' if cannot determine

### Benefits:
- Users see only relevant voices for their selection
- Clearer voice names with gender indication
- Maintains compatibility with existing preferences
- Robust fallback for unknown voice patterns

## Testing
- All dropdown menus now filter correctly by gender
- Existing voice preferences are preserved
- Default voice selection still works properly
- Gender information is clearly displayed in friendly names
