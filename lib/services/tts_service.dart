import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum VoiceGender { male, female, unknown }

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  bool _isInitialized = false; // Track initialization state

  double _speechRate = 0.5;
  String _currentContent = '';
  int _currentPosition = 0;
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<double> progressNotifier = ValueNotifier<double>(0.0);

  // Timer for smooth progress animation
  Timer? _progressTimer;
  DateTime? _startTime;
  Duration _expectedDuration = Duration.zero;

  String? currentLanguage;
  VoiceGender? preferredGender;
  String _currentTitle = '';

  final Map<String, List<String>> genderPatterns = {
    'male': [
      // Specifically requested UK male voice - highest priority
      'en-gb-x-gbb-network', 'gbb',
      // Original patterns
      'iom', 'tpf', 'tpc', 'sfg', 'iog', 'iob', 'iol', 'bmg', 'ism', 'kod',
      // UK English specific male patterns
      'gbc', 'gbd', 'gbg',
      // Add refined UK voice patterns for male
      'en-gb-x-gbc-local', 'en-gb-x-gbd-network', 'en-gb-x-gbg-network',
      'voice iii', 'voice 3',
    ],
    'female': [
      // Specifically confirmed UK female voice - highest priority
      'en-gb-x-gba-local', 'gba',
      // Original patterns
      'ena', 'ene', 'end', 'enc', 'aua', 'aub', 'auc', 'aud',
      // UK English specific female patterns
      'gbe', 'gbf',
      // Add refined UK voice patterns for female
      'en-gb-x-gbe-local', 'en-gb-x-gbf-local',
      'voice ii', 'voice 2',
    ],
  }; // Callback for when a single reading completes (for multiple reading sequences)
  VoidCallback? _onSingleReadingComplete;

  TTSService() {
    _initTTS();

    // Initialize progress notifier to 0
    progressNotifier.value = 0.0;
  }

  Future<void> _initTTS() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    _flutterTts.setCompletionHandler(() {
      debugPrint('TTS completion handler triggered');
      _isSpeaking = false;
      isPlayingNotifier.value = false;

      // Reset current content and position to prevent issues with sequential reading
      _currentPosition = 0;
      // Clear the content after completion to prevent it from affecting next reading
      _currentContent = '';

      // Reset the TTS engine for next reading
      _flutterTts.stop().then((_) {
        debugPrint('TTS engine explicitly stopped in completion handler');
      }).catchError((e) {
        debugPrint('Error stopping TTS in completion handler: $e');
      });

      // Update progress to 100% with a smooth animation
      // This creates a satisfying completion visual effect
      if (_progressTimer != null) {
        // Cancel the current timer but don't reset progress yet
        _progressTimer?.cancel();
        _progressTimer = null;

        // Create a smooth animation to 100% over 300ms
        final startProgress = progressNotifier.value;
        final startTime = DateTime.now();
        final animDuration = Duration(milliseconds: 300);

        Timer.periodic(Duration(milliseconds: 16), (timer) {
          final elapsed = DateTime.now().difference(startTime);

          if (elapsed >= animDuration) {
            // Animation complete
            progressNotifier.value = 1.0;
            timer.cancel();
            _startTime = null;
            debugPrint('TTS Progress: 100% (completion animation finished)');

            // Only now call the completion callback after progress reaches 100%
            if (_onSingleReadingComplete != null) {
              debugPrint('Calling single reading completion callback');
              // Small delay after the progress bar reaches 100%
              Future.delayed(const Duration(milliseconds: 100), () {
                if (_onSingleReadingComplete != null) {
                  debugPrint(
                      'Executing completion callback after progress completion');
                  _onSingleReadingComplete!();
                }
              });
            }
          } else {
            // Animation in progress
            final progress = startProgress +
                (1.0 - startProgress) *
                    (elapsed.inMilliseconds / animDuration.inMilliseconds);
            progressNotifier.value = progress;
          }
        });
      } else {
        // No timer was running, just set to 100%
        progressNotifier.value = 1.0;
        debugPrint('TTS Progress: 100% (immediate completion)');

        // Call completion callback if needed
        if (_onSingleReadingComplete != null) {
          debugPrint('Calling single reading completion callback');
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_onSingleReadingComplete != null) {
              debugPrint('Executing completion callback');
              _onSingleReadingComplete!();
            }
          });
        }
      }
    });

    // We're not using the standard progress handler anymore since we're implementing
    // our own time-based progress tracking for a smoother experience
    if (!kIsWeb) {
      _flutterTts.setProgressHandler((text, start, end, word) {
        // Just track position for resume functionality
        _currentPosition = start;
      });
    }

    // Load saved settings
    try {
      final prefs = await SharedPreferences.getInstance();
      final isMaleVoice = prefs.getBool('is_male_voice') ?? true;

      // First set the language - always use UK English
      await _flutterTts.setLanguage('en-GB');

      // Check if we need to initialize voice preferences
      bool needsVoiceReset = false;
      String? maleVoiceName = prefs.getString('preferred_male_voice_name');
      String? femaleVoiceName = prefs.getString('preferred_female_voice_name');
      String? maleVoiceLocale = prefs.getString('preferred_male_voice_locale');
      String? femaleVoiceLocale =
          prefs.getString('preferred_female_voice_locale');

      // Reset if voices are not set or are US voices
      if (maleVoiceName == null ||
          femaleVoiceName == null ||
          (maleVoiceLocale?.toLowerCase().contains('us') == true) ||
          (femaleVoiceLocale?.toLowerCase().contains('us') == true)) {
        debugPrint(
            'Voice preferences need initialization or are using US voices - will reset');
        needsVoiceReset = true;
      }

      if (needsVoiceReset) {
        await _resetVoicePreferences(); // This will set UK voices
      }

      // Then apply gender preference
      await setVoiceGender(
        isMaleVoice ? VoiceGender.male : VoiceGender.female,
        language: 'en-GB', // Always use UK English
      );
    } catch (e) {
      debugPrint('Error loading voice settings: $e');
    }

    // Warm up the TTS engine to prevent stuttering on first use
    await _warmUpTTS();
    _isInitialized = true;
  }

  Future<void> _warmUpTTS() async {
    try {
      debugPrint('Starting comprehensive TTS warm-up...');

      // Store original settings
      double originalVolume = 1.0;
      double originalRate = _speechRate;
      double originalPitch = 1.0;

      // Phase 1: Initialize with minimal audio (very quiet but audible)
      await _flutterTts.setVolume(
        0.005,
      ); // Very quiet but not completely silent
      await _flutterTts.setSpeechRate(
        0.8,
      ); // Slightly slower for initialization
      await _flutterTts.setPitch(1.0); // Standard pitch

      // Phase 2: Speak multiple short initialization phrases to fully prime the engine
      const List<String> warmupPhrases = ["Test", "Ready", "Start"];

      for (String phrase in warmupPhrases) {
        await _flutterTts.speak(phrase);
        // Wait for completion or timeout
        await Future.delayed(const Duration(milliseconds: 200));
        await _flutterTts.stop();
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Phase 3: Test different speech parameters to ensure engine flexibility
      await _flutterTts.setSpeechRate(1.2);
      await _flutterTts.speak("Fast");
      await Future.delayed(const Duration(milliseconds: 150));
      await _flutterTts.stop();

      await _flutterTts.setSpeechRate(0.6);
      await _flutterTts.speak("Slow");
      await Future.delayed(const Duration(milliseconds: 200));
      await _flutterTts.stop();

      // Phase 4: Test voice engine with a realistic sentence structure
      await _flutterTts.setSpeechRate(1.0);
      await _flutterTts.speak("Warming up text to speech engine.");
      await Future.delayed(const Duration(milliseconds: 300));
      await _flutterTts.stop();

      // Phase 5: Clear any potential engine state
      await Future.delayed(const Duration(milliseconds: 100));
      await _flutterTts.stop(); // Ensure completely stopped

      // Phase 6: Restore original settings
      await _flutterTts.setVolume(originalVolume);
      await _flutterTts.setSpeechRate(originalRate);
      await _flutterTts.setPitch(originalPitch);

      // Phase 7: Final preparation delay
      await Future.delayed(const Duration(milliseconds: 200));

      debugPrint('TTS warm-up completed successfully');
    } catch (e) {
      debugPrint('TTS warm-up failed: $e');
      // Ensure volume is restored even if warm-up fails
      try {
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setSpeechRate(_speechRate);
        await _flutterTts.setPitch(1.0);
      } catch (restoreError) {
        debugPrint(
          'Failed to restore TTS settings after warm-up error: $restoreError',
        );
      }
    }
  }

  double get speechRate => _speechRate;

  Future<void> setSpeechRate(double rate) async {
    if (rate >= 0.1 && rate <= 2.0) {
      _speechRate = rate;
      await _flutterTts.setSpeechRate(rate);
    }
  }

  Future<void> setVoice(String voice) async {
    try {
      await _flutterTts.setLanguage(voice);
      final voices = await _flutterTts.getVoices;
      if (voices != null && voices.isNotEmpty) {
        final matchingVoices = voices
            .where(
              (dynamic v) =>
                  v['locale'].toString().startsWith(voice) ||
                  v['name'].toString().contains(voice),
            )
            .toList();

        if (matchingVoices.isNotEmpty) {
          await _flutterTts.setVoice({
            "name": matchingVoices[0]["name"],
            "locale": matchingVoices[0]["locale"],
          });
        }
      }
    } catch (e) {
      debugPrint("Error setting voice: $e");
    }
  }

  Future<bool> setVoiceGender(
    VoiceGender gender, {
    String language = 'en-GB',
  }) async {
    try {
      // Set language preference to UK English for better voice quality
      String preferredLanguage = "en-GB"; // Prefer UK English voices
      await _flutterTts.setLanguage(preferredLanguage);

      // Check if we have a saved preference for this gender
      Map<String, String>? savedVoice = await getSavedVoicePreference(gender);
      if (savedVoice != null) {
        String? savedName = savedVoice['name'];
        String? savedLocale = savedVoice['locale'];

        // Special handling for voices - ensure we're using the correct voices
        if (gender == VoiceGender.male) {
          if (!(savedName?.toLowerCase().contains('rjs') ?? false)) {
            print("Male voice isn't using rjs voice, will attempt to find it");
          } else if (savedName != null && savedLocale != null) {
            print("Using saved male voice: $savedName");
            try {
              await _flutterTts.setVoice({
                "name": savedName,
                "locale": savedLocale,
              });
              await _flutterTts
                  .setPitch(1.0); // Reset pitch when using saved voice
              return true;
            } catch (e) {
              print(
                  "Saved voice no longer available, searching for new one: $e");
            }
          }
        } else {
          // Female voice
          if (!(savedName?.toLowerCase().contains('gba') ?? false)) {
            print(
                "Female voice isn't using gba voice, will attempt to find it");
          } else if (savedName != null && savedLocale != null) {
            print("Using saved female voice: $savedName");
            try {
              await _flutterTts.setVoice({
                "name": savedName,
                "locale": savedLocale,
              });
              await _flutterTts
                  .setPitch(1.0); // Reset pitch when using saved voice
              return true;
            } catch (e) {
              print(
                  "Saved voice no longer available, searching for new one: $e");
            }
          }
        }
      }

      // Get available voices
      List<dynamic>? voices = await _flutterTts.getVoices;
      if (voices != null && voices.isNotEmpty) {
        // Print all voices for debugging
        print("Total voices available: ${voices.length}");

        // For male voice, directly check for en-gb-x-rjs-local which is required for male
        if (gender == VoiceGender.male) {
          final specificVoice = voices.where((dynamic voice) {
            final Map<String, dynamic> voiceMap =
                Map<String, dynamic>.from(voice);
            final String voiceName =
                voiceMap['name']?.toString().toLowerCase() ?? '';
            return voiceName.contains('en-gb-x-gbb-network') ||
                voiceName.contains('gbb');
          }).toList();

          if (specificVoice.isNotEmpty) {
            final Map<String, dynamic> voiceMap =
                Map<String, dynamic>.from(specificVoice.first);
            final String voiceName = voiceMap['name'] ?? '';
            final String voiceLocale = voiceMap['locale'] ?? '';

            print("Found required male voice: $voiceName ($voiceLocale)");
            await _flutterTts.setVoice({
              "name": voiceName,
              "locale": voiceLocale,
            });
            await _flutterTts.setPitch(1.0);
            await saveVoicePreference(gender, voiceName, voiceLocale);
            await preloadVoice();
            return true;
          }
        }
        // For female voice, directly check for en-gb-x-gba-local which is confirmed working
        else if (gender == VoiceGender.female) {
          final specificVoice = voices.where((dynamic voice) {
            final Map<String, dynamic> voiceMap =
                Map<String, dynamic>.from(voice);
            final String voiceName =
                voiceMap['name']?.toString().toLowerCase() ?? '';
            return voiceName.contains('en-gb-x-gba-local');
          }).toList();

          if (specificVoice.isNotEmpty) {
            final Map<String, dynamic> voiceMap =
                Map<String, dynamic>.from(specificVoice.first);
            final String voiceName = voiceMap['name'] ?? '';
            final String voiceLocale = voiceMap['locale'] ?? '';

            print("Found required female voice: $voiceName ($voiceLocale)");
            await _flutterTts.setVoice({
              "name": voiceName,
              "locale": voiceLocale,
            });
            await _flutterTts.setPitch(1.0);
            await saveVoicePreference(gender, voiceName, voiceLocale);
            await preloadVoice();
            return true;
          }
        }

        // First try to get UK English voices
        final ukVoices = voices.where((dynamic voice) {
          final Map<String, dynamic> voiceMap =
              Map<String, dynamic>.from(voice);
          final String voiceLocale = voiceMap['locale']?.toString() ?? '';
          return voiceLocale.toLowerCase().startsWith('en-gb');
        }).toList();

        // If no UK voices, fall back to US or other English voices
        final languageVoices = ukVoices.isNotEmpty
            ? ukVoices
            : voices.where((dynamic voice) {
                final Map<String, dynamic> voiceMap =
                    Map<String, dynamic>.from(voice);
                final String voiceLocale = voiceMap['locale']?.toString() ?? '';
                return voiceLocale.toLowerCase().startsWith('en');
              }).toList();

        print("Voices available for $language: ${languageVoices.length}");

        // Define comprehensive voice patterns for different TTS engines
        List<String> malePatterns = [
          // Specifically requested UK male voice
          'en-gb-x-gbb-network', 'gbb',
          // Google TTS patterns
          'voice iii', 'voice 3',
          // Common male voice patterns
          'male', 'man', 'masculine',
          // Specific male names
          'david', 'alex', 'daniel', 'michael', 'john', 'james', 'thomas',
          'william',
          'robert', 'christopher', 'matthew', 'anthony', 'mark', 'donald',
          'steven',
          // Voice engine specific
          'guy', 'dude', 'gentleman',
          // Pattern-based (some engines use patterns like en-us-x-iom-local, etc.)
          'iom', 'iog', 'iob', 'iol', 'gbb', 'gbd', 'bmg', 'tpf', 'tpc',
        ];

        List<String> femalePatterns = [
          // Google TTS patterns
          'voice ii', 'voice 2',
          // Common female voice patterns
          'female', 'woman', 'feminine',
          // Specific female names
          'susan', 'mary', 'patricia', 'jennifer', 'linda', 'elizabeth',
          'barbara',
          'sarah', 'karen', 'nancy', 'lisa', 'betty', 'helen', 'sandra',
          'donna',
          'carol', 'ruth', 'sharon', 'michelle', 'laura', 'emily', 'kimberly',
          // Voice engine specific
          'lady', 'girl', 'gal',
          // Pattern-based
          'gba', 'ena', 'ene', 'end', 'enc', 'aua', 'aub', 'auc', 'aud',
        ];

        // Sort voices by preference - put more specific patterns first
        List<dynamic> preferredVoices = [];
        List<dynamic> fallbackVoices = [];

        for (var voice in languageVoices) {
          final Map<String, dynamic> voiceMap = Map<String, dynamic>.from(
            voice,
          );
          final String voiceName =
              voiceMap['name']?.toString().toLowerCase() ?? '';

          print("Analyzing voice: $voiceName");

          bool matchesGender = false;
          bool isPreferred = false;

          if (gender == VoiceGender.male) {
            // Check for specifically requested UK male voice first
            if (voiceName.contains('en-gb-x-gbb-network') ||
                voiceName.contains('gbb')) {
              matchesGender = true;
              isPreferred = true;
              print("Found requested UK male voice match: $voiceName");
            }
            // Then check for exact matches with high-quality voices
            else if (voiceName.contains('voice iii') ||
                voiceName.contains('voice 3')) {
              matchesGender = true;
              isPreferred = true;
              print("Found perfect male voice match: $voiceName");
            } else if (voiceName.contains('david') ||
                voiceName.contains('alex')) {
              matchesGender = true;
              isPreferred = true;
            } else {
              // Check other male patterns
              for (String pattern in malePatterns) {
                if (voiceName.contains(pattern) &&
                    !voiceName.contains('female') &&
                    !voiceName.contains('woman')) {
                  matchesGender = true;
                  break;
                }
              }
            }
          } else {
            // Check for specifically requested UK female voice first
            if (voiceName.contains('en-gb-x-gba-local')) {
              matchesGender = true;
              isPreferred = true;
              print("Found requested UK female voice match: $voiceName");
            }
            // Then check for exact matches with high-quality voices
            else if (voiceName.contains('voice ii') ||
                voiceName.contains('voice 2')) {
              matchesGender = true;
              isPreferred = true;
              print("Found perfect female voice match: $voiceName");
            } else if (voiceName.contains('susan') ||
                voiceName.contains('sarah')) {
              matchesGender = true;
              isPreferred = true;
            } else if (voiceName.contains('gba')) {
              // Any other voice with gba pattern is likely female
              matchesGender = true;
              isPreferred = true;
              print("Found female voice with gba pattern: $voiceName");
            } else {
              // Check other female patterns
              for (String pattern in femalePatterns) {
                if (voiceName.contains(pattern) &&
                    !voiceName.contains('male') &&
                    !voiceName.contains('man')) {
                  matchesGender = true;
                  break;
                }
              }
            }
          }

          if (matchesGender) {
            if (isPreferred) {
              preferredVoices.add(voice);
            } else {
              fallbackVoices.add(voice);
            }
          }
        }

        print(
          "Found ${preferredVoices.length} preferred ${gender == VoiceGender.male ? 'male' : 'female'} voices",
        );
        print(
          "Found ${fallbackVoices.length} fallback ${gender == VoiceGender.male ? 'male' : 'female'} voices",
        );

        // Try preferred voices first, then fallback voices
        List<dynamic> voicesToTry = [...preferredVoices, ...fallbackVoices];

        if (voicesToTry.isNotEmpty) {
          final selectedVoice = voicesToTry.first;
          final Map<String, dynamic> voiceMap = Map<String, dynamic>.from(
            selectedVoice,
          );
          final String voiceName = voiceMap['name'] ?? '';
          final String voiceLocale = voiceMap['locale'] ?? '';

          print("Selected voice: $voiceName, locale: $voiceLocale");
          await _flutterTts.setVoice({
            "name": voiceName,
            "locale": voiceLocale,
          });

          // Reset pitch to neutral when using actual voice selection
          await _flutterTts.setPitch(1.0);

          // Save this selection as preference
          await saveVoicePreference(gender, voiceName, voiceLocale);

          // Preload the selected voice for smoother operation
          await preloadVoice();

          return true;
        }

        // If no gender-specific voices found, try to select different voices for male/female
        // This ensures we get different voices even if we can't detect gender
        if (languageVoices.length >= 2) {
          print("No gender-specific voices found, selecting by position");
          // FIXED: Use proper positioning - first voice for male, second voice for female
          // This avoids the issue where both might select the same voice
          final selectedVoice = gender == VoiceGender.male
              ? languageVoices[0] // First voice for male
              : languageVoices[languageVoices.length > 1
                  ? 1
                  : 0]; // Second voice for female if available

          final Map<String, dynamic> voiceMap = Map<String, dynamic>.from(
            selectedVoice,
          );
          final String voiceName = voiceMap['name'] ?? '';
          final String voiceLocale = voiceMap['locale'] ?? '';

          print("Selected positional voice: $voiceName, locale: $voiceLocale");
          await _flutterTts.setVoice({
            "name": voiceName,
            "locale": voiceLocale,
          });

          // Use slight pitch adjustment as secondary differentiation
          if (gender == VoiceGender.female) {
            await _flutterTts.setPitch(1.1);
          } else {
            await _flutterTts.setPitch(0.9);
          }

          // Save this selection as preference
          await saveVoicePreference(gender, voiceName, voiceLocale);

          // Preload the selected voice for smoother operation
          await preloadVoice();

          return true;
        }
      }

      // Last resort - use pitch adjustment only
      print(
        "No alternative voices found. Using pitch adjustment for ${gender == VoiceGender.male ? 'male' : 'female'} voice",
      );
      if (gender == VoiceGender.female) {
        await _flutterTts.setPitch(1.3);
      } else {
        await _flutterTts.setPitch(0.8);
      }

      return false;
    } catch (e) {
      print("Error setting voice gender: $e");
      return false;
    }
  }

  // Add these new methods for better voice management
  Future<void> saveVoicePreference(
    VoiceGender gender,
    String voiceName,
    String voiceLocale,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save the new preference
      if (gender == VoiceGender.male) {
        await prefs.setString('preferred_male_voice_name', voiceName);
        await prefs.setString('preferred_male_voice_locale', voiceLocale);

        // Check if female voice is using a different locale variant
        String? femaleLocale = prefs.getString('preferred_female_voice_locale');
        if (femaleLocale != null &&
            femaleLocale.toLowerCase().startsWith('en-') &&
            !femaleLocale
                .toLowerCase()
                .startsWith(voiceLocale.toLowerCase().substring(0, 5))) {
          // Different variants - clear female voice to force consistency
          print(
              "Clearing female voice preference to maintain language consistency");
          await prefs.remove('preferred_female_voice_name');
          await prefs.remove('preferred_female_voice_locale');
        }
      } else {
        // Female voice
        await prefs.setString('preferred_female_voice_name', voiceName);
        await prefs.setString('preferred_female_voice_locale', voiceLocale);

        // Check if male voice is using a different locale variant
        String? maleLocale = prefs.getString('preferred_male_voice_locale');
        if (maleLocale != null &&
            maleLocale.toLowerCase().startsWith('en-') &&
            !maleLocale
                .toLowerCase()
                .startsWith(voiceLocale.toLowerCase().substring(0, 5))) {
          // Different variants - clear male voice to force consistency
          print(
              "Clearing male voice preference to maintain language consistency");
          await prefs.remove('preferred_male_voice_name');
          await prefs.remove('preferred_male_voice_locale');
        }
      }

      print(
        "Saved ${gender == VoiceGender.male ? 'male' : 'female'} voice preference: $voiceName ($voiceLocale)",
      );
    } catch (e) {
      print("Error saving voice preference: $e");
    }
  }

  Future<Map<String, String>?> getSavedVoicePreference(
    VoiceGender gender,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String nameKey = gender == VoiceGender.male
          ? 'preferred_male_voice_name'
          : 'preferred_female_voice_name';
      String localeKey = gender == VoiceGender.male
          ? 'preferred_male_voice_locale'
          : 'preferred_female_voice_locale';

      String? voiceName = prefs.getString(nameKey);
      String? voiceLocale = prefs.getString(localeKey);

      if (voiceName != null && voiceLocale != null) {
        return {'name': voiceName, 'locale': voiceLocale};
      }
    } catch (e) {
      print("Error loading voice preference: $e");
    }
    return null;
  }

  Future<void> logAvailableVoices() async {
    try {
      List<dynamic>? voices = await _flutterTts.getVoices;
      if (voices != null && voices.isNotEmpty) {
        print("\n=== AVAILABLE VOICES DEBUG INFO ===");
        print("Total voices available: ${voices.length}");

        // Group by locale
        Map<String, List<Map<String, dynamic>>> voicesByLocale = {};

        for (var voice in voices) {
          final Map<String, dynamic> voiceMap = Map<String, dynamic>.from(
            voice,
          );
          final String voiceLocale = voiceMap['locale'] ?? 'Unknown';

          if (!voicesByLocale.containsKey(voiceLocale)) {
            voicesByLocale[voiceLocale] = [];
          }
          voicesByLocale[voiceLocale]!.add(voiceMap);
        }

        // Print organized by locale
        for (String locale in voicesByLocale.keys) {
          print("\n--- $locale ---");
          for (var voiceMap in voicesByLocale[locale]!) {
            String currentVoiceName = voiceMap['name'] ?? 'Unknown';
            print("  • $currentVoiceName");

            // Analyze potential gender markers
            String lowerName = currentVoiceName.toLowerCase();
            List<String> genderHints = [];

            // Check for explicit gender indicators
            if (lowerName.contains('male') && !lowerName.contains('female')) {
              genderHints.add('MALE');
            }
            if (lowerName.contains('female')) {
              genderHints.add('FEMALE');
            }
            if (lowerName.contains('voice ii') ||
                lowerName.contains('voice 2')) {
              genderHints.add('LIKELY_FEMALE');
            }
            if (lowerName.contains('voice iii') ||
                lowerName.contains('voice 3')) {
              genderHints.add('LIKELY_MALE');
            }

            // Check for common names
            List<String> maleNames = [
              'david',
              'alex',
              'daniel',
              'michael',
              'john',
              'james',
            ];
            List<String> femaleNames = [
              'susan',
              'mary',
              'sarah',
              'karen',
              'lisa',
              'emily',
            ];

            for (String name in maleNames) {
              if (lowerName.contains(name)) {
                genderHints.add('MALE_NAME');
                break;
              }
            }
            for (String name in femaleNames) {
              if (lowerName.contains(name)) {
                genderHints.add('FEMALE_NAME');
                break;
              }
            }

            if (genderHints.isNotEmpty) {
              print("    → Gender hints: ${genderHints.join(', ')}");
            }
          }
        }

        // Highlight specific voices we're looking for
        print("\n=== VOICE MATCHING ANALYSIS ===");
        var enUSVoices = voices.where((dynamic voice) {
          final Map<String, dynamic> voiceMap = Map<String, dynamic>.from(
            voice,
          );
          final String voiceLocale = voiceMap['locale']?.toString() ?? '';
          return voiceLocale.startsWith('en-US');
        }).toList();

        print("English (US) voices found: ${enUSVoices.length}");

        if (enUSVoices.length >= 2) {
          print("✓ Multiple voices available - can differentiate male/female");
          print("  First voice (male): ${enUSVoices.first['name']}");
          print("  Last voice (female): ${enUSVoices.last['name']}");
        } else {
          print("⚠ Limited voices - will use pitch adjustment");
        }

        print("=====================================\n");
      } else {
        print("No voices available or could not retrieve voices");
      }
    } catch (e) {
      print("Error getting available voices: $e");
    }
  }

  Future<void> playReading(String title, String content) async {
    try {
      // Ensure TTS is initialized before playing
      if (!_isInitialized) {
        debugPrint('TTS not initialized, performing initialization...');
        await _initTTS();
      }

      // Make sure any previous speech is completely stopped first
      debugPrint('Ensuring TTS is stopped before starting new reading');
      _isSpeaking = false;
      isPlayingNotifier.value = false;

      // First stop the TTS engine
      try {
        await _flutterTts.stop();
        debugPrint('TTS stop command successful');
      } catch (e) {
        debugPrint("Error stopping TTS: $e");
      } // Reset current position and content to avoid issues with sequential readings
      _currentPosition = 0;
      _currentContent = content;
      _currentTitle = title;

      // Reset progress notifier to 0
      progressNotifier.value = 0.0;
      debugPrint('TTS Progress: 0% (starting new reading)');

      // Minimal delay to ensure the engine is fully reset
      debugPrint('Waiting for TTS engine to fully reset...');
      await Future.delayed(const Duration(milliseconds: 100));
      debugPrint('TTS engine reset wait complete');

      // Ensure the correct voice gender is applied before speaking
      // This fixes the issue where both male and female voices sound the same
      await _ensureCorrectVoiceBeforeSpeaking();

      // Additional double-check for ongoing speech
      if (_isSpeaking) {
        debugPrint(
            'WARNING: TTS still marked as speaking after reset, forcing stop');
        // First set flags then call stop to avoid recursion issues
        _isSpeaking = false;
        isPlayingNotifier.value = false;
        try {
          await _flutterTts.stop();
        } catch (e) {
          debugPrint("Error on second stop attempt: $e");
        }
        // Longer delay to ensure stop is processed
        await Future.delayed(const Duration(milliseconds: 500));
        debugPrint('Completed second stop attempt');
      }

      debugPrint('Starting playReading for: $title');

      // Enhanced readiness verification for first use
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify TTS engine responsiveness before speaking actual content
      try {
        // Quick engine test - speak empty string to verify responsiveness
        await _flutterTts.setVolume(0.01);
        await _flutterTts.speak("");
        await Future.delayed(const Duration(milliseconds: 50));
        await _flutterTts.stop();
        await _flutterTts.setVolume(1.0);

        // Additional delay to ensure engine has processed the test
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        debugPrint("TTS readiness test failed: $e");
        // Continue anyway, but with extra delay
        await Future.delayed(const Duration(milliseconds: 200));
      }

      _isSpeaking = true;
      isPlayingNotifier.value = true;
      _currentContent = content;

      // Handle title and content separately to prevent issues
      // This approach ensures more reliable playback across multiple readings

      // Prepare content text only
      String contentText = content.trim();
      if (contentText.isEmpty) {
        debugPrint('No content to speak, stopping');
        _isSpeaking = false;
        isPlayingNotifier.value = false;
        return;
      }

      // Make sure the title and content are properly separated
      // Use a more distinct separation to ensure TTS engine treats them properly
      String fullText;
      if (title.isNotEmpty) {
        // Add explicit punctuation and pause between title and content
        fullText = "$title.\n\n$contentText";
      } else {
        fullText = contentText;
      }

      // Start the progress timer for smooth progress updates
      _startProgressTimer(fullText);

      // Log what we're about to speak
      debugPrint(
        'Starting TTS playback: ${fullText.substring(0, fullText.length > 50 ? 50 : fullText.length)}...',
      );

      if (fullText.length > 4000) {
        debugPrint('Long text detected, splitting into chunks');
        final chunks = _splitTextIntoChunks(fullText);
        for (int i = 0; i < chunks.length; i++) {
          if (!_isSpeaking) {
            debugPrint('TTS stopped during chunk processing');
            break;
          }

          var chunk = chunks[i];
          debugPrint('Speaking chunk ${i + 1}/${chunks.length}');

          // Use special first speech handling for the first chunk if this is the first speech
          if (_isFirstSpeech && i == 0) {
            await _handleFirstSpeech(chunk);
            _isFirstSpeech = false; // Mark that first speech has been handled
          } else {
            await _speakWithCorrectVoice(chunk);
          }

          // Wait for this chunk to complete before moving to next
          while (_isSpeaking && isPlayingNotifier.value) {
            await Future.delayed(const Duration(milliseconds: 100));
          }

          // If manually stopped, don't continue
          if (!_isSpeaking) {
            debugPrint('TTS manually stopped during chunks');
            break;
          }

          // Reset speaking flag for next chunk
          _isSpeaking = true;
        }
      } else {
        // Use special first speech handling if this is the first speech
        if (_isFirstSpeech) {
          debugPrint('Using first speech handling');
          await _handleFirstSpeech(fullText);
          _isFirstSpeech = false; // Mark that first speech has been handled
        } else {
          debugPrint('Speaking text normally with enforced voice');
          await _speakWithCorrectVoice(fullText);
        }

        // DO NOT manually update state or trigger completion handlers here
        // Let the main TTS completion handler do its job naturally
        debugPrint(
            'Speech method completed - letting TTS engine handle completion');
      }

      debugPrint('playReading method completed');
    } catch (e) {
      debugPrint("TTS error: $e");
      _isSpeaking = false;
      isPlayingNotifier.value = false;
      rethrow;
    }
  }

  List<String> _splitTextIntoChunks(String text, {int chunkSize = 3000}) {
    List<String> chunks = [];
    for (int i = 0; i < text.length; i += chunkSize) {
      int end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      chunks.add(text.substring(i, end));
    }
    return chunks;
  }

  Future<void> pause() async {
    try {
      if (_isSpeaking) {
        _isSpeaking = false;
        isPlayingNotifier.value = false;
        await _flutterTts
            .stop(); // Use stop instead of pause to avoid issues with some TTS engines
      }
    } catch (e) {
      debugPrint("Error pausing TTS: $e");
    }
    return Future.value();
  }

  Future<void> resume() async {
    if (!_isSpeaking && _currentContent.isNotEmpty) {
      _isSpeaking = true;
      isPlayingNotifier.value = true;
      await _speakWithCorrectVoice(_currentContent.substring(_currentPosition));
    }
    return Future.value();
  }

  Future<void> togglePlayPause({String? title, String? content}) async {
    // This method supports a play/pause toggle button
    if (_isSpeaking) {
      await pause();
    } else {
      // If there's active content, resume it
      if (_currentContent.isNotEmpty) {
        await resume();
      }
      // If new content is provided, play it
      else if (content != null) {
        await playReading(title ?? '', content);
      }
    }
  }

  Future<void> stop() async {
    // This method supports a stop button
    _isSpeaking = false;
    isPlayingNotifier.value = false;
    _currentPosition = 0;

    // Stop the progress timer
    _stopProgressTimer();

    // Animate progress back to 0 for a smoother visual effect
    // Only animate if we have significant progress (>5%)
    if (progressNotifier.value > 0.05) {
      final startProgress = progressNotifier.value;
      final startTime = DateTime.now();
      final animDuration = Duration(milliseconds: 300);

      Timer.periodic(Duration(milliseconds: 16), (timer) {
        final elapsed = DateTime.now().difference(startTime);

        if (elapsed >= animDuration) {
          // Animation complete
          progressNotifier.value = 0.0;
          timer.cancel();
        } else {
          // Animate progress downward
          final completion =
              elapsed.inMilliseconds / animDuration.inMilliseconds;
          final progress = startProgress * (1.0 - completion);
          progressNotifier.value = progress;
        }
      });
    } else {
      // Just reset progress immediately for small values
      progressNotifier.value = 0.0;
    }

    return _flutterTts.stop();
  }

  Future<void> skipForward() async {
    // This method supports a skip forward button
    if (_currentContent.isNotEmpty &&
        _currentPosition < _currentContent.length) {
      int nextPosition = _currentContent.indexOf('. ', _currentPosition);
      if (nextPosition != -1) {
        _currentPosition = nextPosition + 2;

        if (_isSpeaking) {
          await stop();
          await _speakWithCorrectVoice(
              _currentContent.substring(_currentPosition));
          _isSpeaking = true;
          isPlayingNotifier.value = true;
        }
      }
    }
  }

  // Keep the original skip method for backward compatibility
  // but have it call skipForward internally
  Future<void> skip() async {
    return skipForward();
  }

  Future<void> speak(String text) async {
    // Ensure the correct voice is applied before speaking
    await _ensureCorrectVoiceBeforeSpeaking();
    await playReading('', text);
  }

  // Custom speak method that ensures the correct voice is used
  Future<void> _speakWithCorrectVoice(String text) async {
    if (text.isEmpty) {
      debugPrint("Empty text provided, nothing to speak");
      return;
    }

    try {
      debugPrint("Using custom speak method with enforced voice selection");

      // Get current gender preference
      final prefs = await SharedPreferences.getInstance();
      final isMaleVoice = prefs.getBool('is_male_voice') ?? true;

      // Set voice based on gender directly before speaking
      if (isMaleVoice) {
        // Use en-gb-x-gbb-network for male (as originally agreed)
        debugPrint("Setting voice to male (gbb-network) before speaking");
        await _flutterTts.setVoice({
          "name": "en-gb-x-gbb-network",
          "locale": "en-GB",
        });
      } else {
        // Use en-gb-x-gba-local for female
        debugPrint("Setting voice to female (gba) before speaking");
        await _flutterTts.setVoice({
          "name": "en-gb-x-gba-local",
          "locale": "en-GB",
        });
      }

      // Reset pitch to ensure it's not affecting the voice
      await _flutterTts.setPitch(1.0);

      debugPrint("Starting to speak text of length ${text.length}");

      // Start speaking the text and let the natural completion handler work
      await _flutterTts.speak(text);

      debugPrint(
          "Custom speak method initiated speech - letting TTS handle completion naturally");
    } catch (e) {
      debugPrint("Error using custom speak method: $e");

      // Fall back to regular speak if there's an error
      await _flutterTts.speak(text);
      debugPrint("Fallback speak initiated");
    }
  }

  void dispose() {
    _flutterTts.stop();
    _stopProgressTimer();
    isPlayingNotifier.dispose();
    progressNotifier.dispose();
  }

  // Public method to ensure TTS is fully ready for use
  Future<void> ensureReady() async {
    if (!_isInitialized) {
      await _initTTS();
    }

    // Additional readiness check - test engine responsiveness
    try {
      await _flutterTts.setVolume(0.01);
      await _flutterTts.speak("");
      await Future.delayed(const Duration(milliseconds: 100));
      await _flutterTts.stop();
      await _flutterTts.setVolume(1.0);
      debugPrint('TTS readiness verified');
    } catch (e) {
      debugPrint('TTS readiness test failed: $e');
    }
  }

  // Method to preload TTS after voice selection for smooth operation
  Future<void> preloadVoice() async {
    try {
      debugPrint('Preloading selected voice...');

      // Store current volume
      double currentVolume = 1.0;

      // Speak a brief phrase with the selected voice at very low volume
      await _flutterTts.setVolume(0.01);
      await _flutterTts.speak("Voice loaded and ready.");

      // Wait for completion
      await Future.delayed(const Duration(milliseconds: 400));
      await _flutterTts.stop();

      // Restore volume
      await _flutterTts.setVolume(currentVolume);

      debugPrint('Voice preloading completed');
    } catch (e) {
      debugPrint('Voice preloading failed: $e');
    }
  }

  // Special method for first-time speech to ensure smooth delivery
  Future<void> _handleFirstSpeech(String text) async {
    try {
      debugPrint('Handling first speech with extra preparation...');

      // Ensure complete initialization
      if (!_isInitialized) {
        await _initTTS();
      }

      // Make sure the correct voice is being used
      await _ensureCorrectVoiceBeforeSpeaking();

      // Additional engine preparation for first speech
      await Future.delayed(const Duration(milliseconds: 200));

      // Test engine with very short phrase first
      await _flutterTts.setVolume(0.01);
      await _flutterTts.speak(".");
      await Future.delayed(const Duration(milliseconds: 100));
      await _flutterTts.stop();
      await _flutterTts.setVolume(1.0);

      // Additional delay before actual speech
      await Future.delayed(const Duration(milliseconds: 150));

      // Use our custom speak method to ensure correct voice
      await _speakWithCorrectVoice(text);

      debugPrint('First speech delivered with enforced voice selection');
    } catch (e) {
      debugPrint(
        'First speech handling failed, falling back to normal speech: $e',
      );
      // Even in fallback case, use our custom speak method
      await _speakWithCorrectVoice(text);
    }
  }

  // Track if this is the first speech since app start
  bool _isFirstSpeech = true;

  // Methods to set completion callbacks
  void setOnSingleReadingComplete(VoidCallback? callback) {
    _onSingleReadingComplete = callback;
  }

  void clearCompletionCallbacks() {
    _onSingleReadingComplete = null;
  }

  // Enhanced debugging for voice selection issues
  Future<void> debugVoiceSelection() async {
    try {
      print("\n=== VOICE SELECTION DEBUG ===");
      List<dynamic>? voices = await _flutterTts.getVoices;

      if (voices != null && voices.isNotEmpty) {
        print("Total voices available: ${voices.length}");

        // Filter UK English voices
        var ukVoices = voices.where((dynamic voice) {
          final Map<String, dynamic> voiceMap =
              Map<String, dynamic>.from(voice);
          final String voiceLocale = voiceMap['locale']?.toString() ?? '';
          return voiceLocale.toLowerCase().startsWith('en-gb');
        }).toList();

        print("\nUK English voices: ${ukVoices.length}");
        for (int i = 0; i < ukVoices.length; i++) {
          final voice = ukVoices[i];
          final Map<String, dynamic> voiceMap =
              Map<String, dynamic>.from(voice);
          final String voiceName = voiceMap['name'] ?? 'Unknown';
          final String voiceLocale = voiceMap['locale'] ?? 'Unknown';
          print("  [$i] $voiceName ($voiceLocale)");
        }

        // Filter US English voices
        var usVoices = voices.where((dynamic voice) {
          final Map<String, dynamic> voiceMap =
              Map<String, dynamic>.from(voice);
          final String voiceLocale = voiceMap['locale']?.toString() ?? '';
          return voiceLocale.toLowerCase().startsWith('en-us');
        }).toList();

        print("\nUS English voices: ${usVoices.length}");
        for (int i = 0; i < usVoices.length; i++) {
          final voice = usVoices[i];
          final Map<String, dynamic> voiceMap =
              Map<String, dynamic>.from(voice);
          final String voiceName = voiceMap['name'] ?? 'Unknown';
          final String voiceLocale = voiceMap['locale'] ?? 'Unknown';
          print("  [$i] $voiceName ($voiceLocale)");
        }

        // Test voice selection for both genders
        print("\nTesting MALE voice selection:");
        await setVoiceGender(VoiceGender.male);

        print("\nTesting FEMALE voice selection:");
        await setVoiceGender(VoiceGender.female);

        // Check current voice settings
        Map<String, String>? maleVoice =
            await getSavedVoicePreference(VoiceGender.male);
        Map<String, String>? femaleVoice =
            await getSavedVoicePreference(VoiceGender.female);

        print("\nCurrent saved voice preferences:");
        print(
            "  Male: ${maleVoice != null ? '${maleVoice['name']} (${maleVoice['locale']})' : 'None'}");
        print(
            "  Female: ${femaleVoice != null ? '${femaleVoice['name']} (${femaleVoice['locale']})' : 'None'}");

        print("\nVoice selection testing completed");
      } else {
        print("No voices available");
      }
      print("=== END DEBUG ===\n");
    } catch (e) {
      print("Voice debug error: $e");
    }
  }

  // Initialize voice preferences with appropriate voices (used internally only)
  Future<void> _resetVoicePreferences() async {
    try {
      print("Resetting voice preferences...");

      // Clear saved preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('preferred_male_voice_name');
      await prefs.remove('preferred_male_voice_locale');
      await prefs.remove('preferred_female_voice_name');
      await prefs.remove('preferred_female_voice_locale');

      // Force UK English language first
      await _flutterTts.setLanguage('en-GB');

      // Get all available voices
      List<dynamic>? voices = await _flutterTts.getVoices;
      if (voices == null || voices.isEmpty) {
        print("No voices available for reset");
        return;
      }

      print("Total voices available for reset: ${voices.length}");

      // First filter for UK voices specifically
      final ukVoices = voices.where((dynamic voice) {
        final Map<String, dynamic> voiceMap = Map<String, dynamic>.from(voice);
        final String voiceLocale = voiceMap['locale']?.toString() ?? '';
        return voiceLocale.toLowerCase().startsWith('en-gb');
      }).toList();

      print("UK English voices found: ${ukVoices.length}");

      // Use UK voices if available, otherwise use all voices
      List<dynamic> searchVoices = ukVoices.isNotEmpty ? ukVoices : voices;

      // Debug UK voices
      if (ukVoices.isNotEmpty) {
        print("Available UK English voices:");
        for (int i = 0; i < ukVoices.length; i++) {
          final Map<String, dynamic> voiceMap =
              Map<String, dynamic>.from(ukVoices[i]);
          final String voiceName = voiceMap['name'] ?? 'Unknown';
          print("  [$i] $voiceName (${voiceMap['locale']})");
        }
      }

      // Define explicit pattern matches for identifying UK male and female voices
      List<String> ukMalePatterns = [
        'gbc',
        'gbd',
        'gbg',
        'voice iii',
        'voice 3'
      ];
      List<String> ukFemalePatterns = [
        'gba',
        'gbe',
        'gbf',
        'voice ii',
        'voice 2'
      ];

      // Try to find a male voice using improved UK pattern detection
      dynamic maleVoice;
      for (var voice in searchVoices) {
        final Map<String, dynamic> voiceMap = Map<String, dynamic>.from(voice);
        final String voiceName =
            voiceMap['name']?.toString().toLowerCase() ?? '';

        // New approach: look specifically for the Voice III pattern first
        if (voiceName.contains('voice iii') || voiceName.contains('voice 3')) {
          print("Found Voice III male voice: $voiceName");
          maleVoice = voice;
          break;
        }

        // Check for UK-specific male voice patterns in the name
        for (String pattern in ukMalePatterns) {
          if (voiceName.contains(pattern)) {
            print("Found male voice with pattern '$pattern': $voiceName");
            maleVoice = voice;
            break;
          }
        }

        // If found a voice, break out of the outer loop too
        if (maleVoice != null) break;
      }

      // If still no male voice, try using the 'en-gb-x-gbb-network' voice specifically
      // This is the preferred male voice per requirements
      if (maleVoice == null) {
        for (var voice in searchVoices) {
          final Map<String, dynamic> voiceMap =
              Map<String, dynamic>.from(voice);
          final String voiceName =
              voiceMap['name']?.toString().toLowerCase() ?? '';

          // Look specifically for the requested en-gb-x-rjs-local which should be male
          if (voiceName.contains('rjs') ||
              voiceName.contains('en-gb-x-rjs-local')) {
            print("Using requested rjs pattern for male voice: $voiceName");
            maleVoice = voice;
            break;
          }
        }

        // If still no voice found, fallback to gbb pattern
        if (maleVoice == null) {
          for (var voice in searchVoices) {
            final Map<String, dynamic> voiceMap =
                Map<String, dynamic>.from(voice);
            final String voiceName =
                voiceMap['name']?.toString().toLowerCase() ?? '';

            if (voiceName.contains('gbb')) {
              print("Falling back to gbb pattern for male voice: $voiceName");
              maleVoice = voice;
              break;
            }
          }
        }
      }

      // Try to find a female voice using improved UK pattern detection
      dynamic femaleVoice;
      for (var voice in searchVoices) {
        final Map<String, dynamic> voiceMap = Map<String, dynamic>.from(voice);
        final String voiceName =
            voiceMap['name']?.toString().toLowerCase() ?? '';

        // New approach: look specifically for the Voice II pattern first
        if (voiceName.contains('voice ii') || voiceName.contains('voice 2')) {
          print("Found Voice II female voice: $voiceName");
          femaleVoice = voice;
          break;
        }

        // Check for UK-specific female voice patterns in the name
        for (String pattern in ukFemalePatterns) {
          if (voiceName.contains(pattern)) {
            print("Found female voice with pattern '$pattern': $voiceName");
            femaleVoice = voice;
            break;
          }
        }

        // If found a voice, break out of the outer loop too
        if (femaleVoice != null) break;
      }

      // If still no female voice, try using the local voice with 'gba' pattern
      if (femaleVoice == null) {
        for (var voice in searchVoices) {
          final Map<String, dynamic> voiceMap =
              Map<String, dynamic>.from(voice);
          final String voiceName =
              voiceMap['name']?.toString().toLowerCase() ?? '';

          // Look specifically for en-gb-x-gba-local which should be female
          if (voiceName.contains('gba')) {
            print("Using gba pattern for female voice: $voiceName");
            femaleVoice = voice;
            break;
          }
        }
      }

      // Set male voice
      if (maleVoice != null) {
        final Map<String, dynamic> voiceMap =
            Map<String, dynamic>.from(maleVoice);
        final String voiceName = voiceMap['name'] ?? '';
        final String voiceLocale = voiceMap['locale'] ?? '';
        print("Setting male voice: $voiceName ($voiceLocale)");
        await saveVoicePreference(VoiceGender.male, voiceName, voiceLocale);
      } else {
        print("No suitable male voice found, will use default");
      }

      // Set female voice
      if (femaleVoice != null) {
        final Map<String, dynamic> voiceMap =
            Map<String, dynamic>.from(femaleVoice);
        final String voiceName = voiceMap['name'] ?? '';
        final String voiceLocale = voiceMap['locale'] ?? '';
        print("Setting female voice: $voiceName ($voiceLocale)");
        await saveVoicePreference(VoiceGender.female, voiceName, voiceLocale);
      } else {
        print("No suitable female voice found, will use default");
      }

      print("Voice preferences reset completed");
    } catch (e) {
      print("Error resetting voice preferences: $e");
    }
  } // Ensure the correct voice gender is applied before speaking

  Future<void> _ensureCorrectVoiceBeforeSpeaking() async {
    try {
      // Get current gender preference
      final prefs = await SharedPreferences.getInstance();
      final isMaleVoice = prefs.getBool('is_male_voice') ?? true;

      print(
          "Ensuring correct voice before speaking: ${isMaleVoice ? 'Male' : 'Female'}");

      // Get available voices
      List<dynamic>? voices = await _flutterTts.getVoices;
      if (voices == null || voices.isEmpty) {
        print("No voices available for selection");
        return;
      }

      // Filter for UK English voices
      var ukVoices = voices.where((dynamic voice) {
        final Map<String, dynamic> voiceMap = Map<String, dynamic>.from(voice);
        final String voiceLocale = voiceMap['locale']?.toString() ?? '';
        return voiceLocale.toLowerCase().startsWith('en-gb');
      }).toList();

      if (ukVoices.isEmpty) {
        print("No UK English voices available");
        return;
      }

      // Explicitly find and apply the correct voice based on gender
      if (isMaleVoice) {
        // Look for en-gb-x-gbb-network for male (as originally agreed)
        dynamic maleVoice;
        for (var voice in ukVoices) {
          final Map<String, dynamic> voiceMap =
              Map<String, dynamic>.from(voice);
          final String voiceName =
              voiceMap['name']?.toString().toLowerCase() ?? '';

          if (voiceName.contains('en-gb-x-gbb-network') ||
              voiceName.contains('gbb')) {
            print("Found required male voice: $voiceName");
            maleVoice = voice;
            break;
          }
        }

        // If found, apply it
        if (maleVoice != null) {
          final Map<String, dynamic> voiceMap =
              Map<String, dynamic>.from(maleVoice);
          final String voiceName = voiceMap['name'] ?? '';
          final String voiceLocale = voiceMap['locale'] ?? '';

          print("Forcing male voice: $voiceName ($voiceLocale)");
          await _flutterTts.setVoice({
            "name": voiceName,
            "locale": voiceLocale,
          });
        } else {
          print("Required male voice not found");
        }
      } else {
        // Look for en-gb-x-gba-local for female
        dynamic femaleVoice;
        for (var voice in ukVoices) {
          final Map<String, dynamic> voiceMap =
              Map<String, dynamic>.from(voice);
          final String voiceName =
              voiceMap['name']?.toString().toLowerCase() ?? '';

          if (voiceName.contains('en-gb-x-gba-local')) {
            print("Found required female voice: $voiceName");
            femaleVoice = voice;
            break;
          }
        }

        // If found, apply it
        if (femaleVoice != null) {
          final Map<String, dynamic> voiceMap =
              Map<String, dynamic>.from(femaleVoice);
          final String voiceName = voiceMap['name'] ?? '';
          final String voiceLocale = voiceMap['locale'] ?? '';

          print("Forcing female voice: $voiceName ($voiceLocale)");
          await _flutterTts.setVoice({
            "name": voiceName,
            "locale": voiceLocale,
          });
        } else {
          print("Required female voice not found");
        }
      }

      // Reset pitch to default
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      print("Error ensuring correct voice: $e");
    }
  } // Get the progress notifier for tracking reading progress

  ValueNotifier<double> get progress => progressNotifier;

  // Get the current reading title
  String get currentReadingTitle => _currentTitle;

  // Helper methods for managing the progress timer
  void _startProgressTimer(String content) {
    // Cancel any existing timer
    _stopProgressTimer();

    // Calculate expected duration based on a more accurate algorithm
    // Count words properly with a regex to handle punctuation better
    int wordCount = RegExp(r'\b\w+\b').allMatches(content).length;

    // Extract the title (assuming format "Title. Content...")
    String title = "";
    String mainContent = content;
    if (content.contains(". ")) {
      int firstDotIndex = content.indexOf(". ");
      if (firstDotIndex > 0 && firstDotIndex < content.length / 3) {
        // Only consider it a title if the period is near the beginning
        title = content.substring(0, firstDotIndex);
        mainContent = content.substring(firstDotIndex + 2);
      }
    }

    // Get reading metrics
    int titleWordCount =
        title.isEmpty ? 0 : RegExp(r'\b\w+\b').allMatches(title).length;
    int mainContentWordCount =
        RegExp(r'\b\w+\b').allMatches(mainContent).length;

    // Calculate speech rate more precisely for different parts
    double baseRate = (130.0 / 60.0) * _speechRate; // Base words per second

    // Title is usually read slightly slower
    double titleWordsPerSecond = baseRate * 0.85;
    double contentWordsPerSecond = baseRate;

    // Count sentences for pauses
    int sentenceCount = RegExp(r'[.!?]+').allMatches(content).length;

    // Calculate duration components
    int titleDurationSeconds =
        title.isEmpty ? 0 : (titleWordCount / titleWordsPerSecond).ceil();
    int contentDurationSeconds =
        (mainContentWordCount / contentWordsPerSecond).ceil();

    // Add time for sentence pauses
    double pauseTimePerSentence = 0.3; // seconds
    int pausesSeconds = (sentenceCount * pauseTimePerSentence).ceil();

    // Calculate raw duration
    int rawDurationSeconds =
        titleDurationSeconds + contentDurationSeconds + pausesSeconds;

    // Add additional buffer based on content length and device characteristics
    double bufferMultiplier;

    // Short readings need proportionally more buffer time due to TTS engine startup overhead
    if (wordCount < 30) {
      bufferMultiplier = 1.4; // 40% buffer for very short readings
    } else if (wordCount < 100) {
      bufferMultiplier = 1.25; // 25% buffer for short readings
    } else if (wordCount < 300) {
      bufferMultiplier = 1.18; // 18% buffer for medium readings
    } else {
      bufferMultiplier = 1.15; // 15% buffer for long readings
    }

    // Apply buffer
    int expectedDurationSeconds =
        (rawDurationSeconds * bufferMultiplier).ceil();

    _expectedDuration = Duration(seconds: expectedDurationSeconds);

    debugPrint(
        'Estimated reading duration: $_expectedDuration for $wordCount words and $sentenceCount sentences');
    debugPrint(
        'Reading speed: ${contentWordsPerSecond.toStringAsFixed(2)} words/sec, buffer factor: ${bufferMultiplier.toStringAsFixed(2)}');

    // Start the timer to update progress
    _startTime = DateTime.now();

    // Update progress every 100ms for smooth animation
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      // Safety check to prevent crashes if speaking state changes unexpectedly
      if (_startTime == null || !_isSpeaking) {
        _stopProgressTimer();
        return;
      }

      try {
        final elapsedTime = DateTime.now().difference(_startTime!);

        // Safety check for zero or negative duration
        if (_expectedDuration.inMilliseconds <= 0) {
          debugPrint('Warning: Invalid expected duration, using fallback');
          _expectedDuration = Duration(seconds: 30); // Fallback duration
        }

        // Calculate progress as a percentage of expected duration
        double progress =
            elapsedTime.inMilliseconds / _expectedDuration.inMilliseconds;

        // Check for abnormal values (caused by time adjustments or device sleep)
        if (progress < 0) progress = 0;
        if (progress.isNaN || !progress.isFinite) {
          progress = 0.5; // Use middle value if calculation fails
        }

        // Use an adaptive non-linear progress curve for more natural movement
        // For short readings (<30s), use a more linear curve
        // For longer readings, use a curve that accelerates slightly at start and end
        if (_expectedDuration.inSeconds > 30) {
          if (progress < 0.2) {
            // Slightly faster at beginning to show immediate feedback
            progress = progress * 1.1;
          } else if (progress > 0.8 && progress < 0.95) {
            // Slightly slower in the final stretch (feels more natural)
            progress = progress * 0.98;
          }
        }

        // Cap at 0.99 to leave room for completion handler
        progress = progress.clamp(0.0, 0.99);

        // Only update if value has changed significantly (reduces UI updates)
        if ((progress - progressNotifier.value).abs() > 0.001) {
          progressNotifier.value = progress;
        }

        // Debug log less frequently to avoid flooding
        if (timer.tick % 30 == 0 || progress > 0.95) {
          debugPrint(
              'TTS Progress: ${(progress * 100).toStringAsFixed(1)}% (elapsed: ${elapsedTime.inSeconds}s)');
        }

        // Safety check if we've gone significantly beyond estimated duration
        // but TTS is still running (this can happen due to TTS engine variations)
        if (progress > 0.95 && _isSpeaking && elapsedTime > _expectedDuration) {
          debugPrint(
              'Warning: Reading taking longer than expected, adjusting duration');
          // Extend expected duration by 30% but never exceed 1.0 progress
          _expectedDuration = Duration(
              milliseconds: (elapsedTime.inMilliseconds * 1.3).toInt());
        }
      } catch (e) {
        debugPrint('Error in progress timer: $e');
        // Continue timer but avoid crashing
      }
    });
  }

  void _stopProgressTimer() {
    // Only cancel the timer, don't reset progress value
    // This allows proper handling of stop/pause actions
    _progressTimer?.cancel();
    _progressTimer = null;
    _startTime = null;
  }

  // Calculate a more accurate reading speed based on content characteristics
}
