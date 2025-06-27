import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum VoiceGender { male, female }

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);

  // Wake lock channel for background operation
  static const MethodChannel _methodChannel = MethodChannel(
    'com.aareadingsandprayers.app/keep_alive',
  );

  double _speechRate = 0.5;
  double _volume = 1.0;
  double _pitch = 1.0;
  VoiceGender _voiceGender = VoiceGender.male;
  String _language = 'en-gb'; // Default to UK English

  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _disposed = false;
  bool _testMode = false; // Flag for test environments
  bool _isMultipleReadingsMode =
      false; // Track if we're in multiple readings mode

  // Fallback timer for TTS completion detection
  Timer? _completionTimer;

  // Add storage for pause/resume functionality
  String? _pausedText;
  String? _pausedTitle;

  Function()? _onSingleReadingComplete;
  Function()? _onMultipleReadingComplete;

  // Getters
  double get speechRate => _speechRate;
  double get volume => _volume;
  double get pitch => _pitch;
  VoiceGender get voiceGender => _voiceGender;
  String get language => _language;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  bool get isInMultipleReadingsMode => _isMultipleReadingsMode;
  Future<void> _loadVoicePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isMaleVoice = prefs.getBool('is_male_voice') ?? true;
      final selectedLanguage = prefs.getString('voice_language') ?? 'en-gb';

      // Set the voice gender property
      _voiceGender = isMaleVoice ? VoiceGender.male : VoiceGender.female;
      _language = selectedLanguage;

      print(
        '🎤 Loaded voice preference: ${_voiceGender == VoiceGender.male ? 'MALE' : 'FEMALE'} ($_language) (isMaleVoice: $isMaleVoice, savedLanguage: $selectedLanguage)',
      );

      // Apply the voice selection directly without calling initialize again
      await _applyVoiceSelection();
    } catch (e) {
      print('🎤 Error loading voice preferences: $e');
      // Error loading voice preferences, use default
    }
  }

  Future<void> _applyVoiceSelection() async {
    // Prevent voice changes during multiple readings mode
    if (_isMultipleReadingsMode) {
      print('🎤 Voice selection blocked: Multiple readings in progress');
      return;
    }

    try {
      final voices = await _flutterTts.getVoices;
      if (voices == null || voices.isEmpty) {
        print('🎤 No voices available from TTS engine');
        return;
      }

      print('🎤 Found ${voices.length} available voices');
      print(
        '🎤 Looking for $_language voices with ${_voiceGender == VoiceGender.male ? 'MALE' : 'FEMALE'} gender',
      );

      // Filter voices by language first
      final languageVoices =
          voices.where((voice) {
            final voiceLocale =
                (voice['locale'] as String?)?.toLowerCase() ?? '';
            return voiceLocale == _language.toLowerCase();
          }).toList();

      print('🎤 Found ${languageVoices.length} $_language voices');

      if (languageVoices.isEmpty) {
        print('🎤 No voices found for $_language');
        return;
      }

      Map<String, dynamic>? selectedVoice;

      // Check for saved custom voice selections first
      final prefs = await SharedPreferences.getInstance();

      // Use the new specific voice preference keys
      String? targetVoiceName;

      if (_language.toLowerCase() == 'en-us') {
        if (_voiceGender == VoiceGender.male) {
          targetVoiceName = prefs.getString('us_male_voice');
        } else {
          targetVoiceName = prefs.getString('us_female_voice');
        }
      } else if (_language.toLowerCase() == 'en-gb') {
        if (_voiceGender == VoiceGender.male) {
          targetVoiceName = prefs.getString('uk_male_voice');
        } else {
          targetVoiceName = prefs.getString('uk_female_voice');
        }
      }

      if (targetVoiceName != null) {
        // Use the specifically selected voice
        dynamic foundVoice;
        for (final voice in languageVoices) {
          if (voice['name']?.toString() == targetVoiceName) {
            foundVoice = voice;
            break;
          }
        }

        if (foundVoice != null) {
          selectedVoice = {
            'name': foundVoice['name']?.toString() ?? '',
            'locale': foundVoice['locale']?.toString() ?? '',
          };
          print(
            '🎤 Using specifically selected voice: $targetVoiceName for ${_voiceGender == VoiceGender.male ? 'MALE' : 'FEMALE'} $_language',
          );
        }
      }

      // If no specific voice was selected, use fallback logic
      if (selectedVoice == null) {
        print('🎤 No specific voice selected, using fallback logic');

        if (_language.toLowerCase() == 'en-us') {
          // US English: Use fallback patterns
          if (_voiceGender == VoiceGender.male) {
            // Fallback: try male voice patterns
            for (final voice in languageVoices) {
              final name = (voice['name'] as String?)?.toLowerCase() ?? '';
              if (name.contains('tpd') ||
                  name.contains('iom') ||
                  name.contains('iog')) {
                selectedVoice = {
                  'name': voice['name']?.toString() ?? '',
                  'locale': voice['locale']?.toString() ?? '',
                };
                break;
              }
            }
            print(
              '🎤 Using US MALE fallback voice: ${selectedVoice?['name'] ?? 'None found'}',
            );
          } else {
            // Fallback: try female voice patterns
            for (final voice in languageVoices) {
              final name = (voice['name'] as String?)?.toLowerCase() ?? '';
              if (name.contains('tpc') ||
                  name.contains('tpf') ||
                  name.contains('iol')) {
                selectedVoice = {
                  'name': voice['name']?.toString() ?? '',
                  'locale': voice['locale']?.toString() ?? '',
                };
                break;
              }
            }
            print(
              '🎤 Using US FEMALE fallback voice: ${selectedVoice?['name'] ?? 'None found'}',
            );
          }
        } else if (_language.toLowerCase() == 'en-gb') {
          // UK English: Use gender-based selection
          print('🎤 Available UK voices:');
          for (final voice in languageVoices) {
            print('🎤   ${voice['name']} (${voice['locale']})');
          }

          if (_voiceGender == VoiceGender.male) {
            // Look for UK male voices
            for (final voice in languageVoices) {
              final name = (voice['name'] as String?)?.toLowerCase() ?? '';
              if (name.contains('gba') ||
                  name.contains('gbc') ||
                  name.contains('gbd') ||
                  name.contains('male') ||
                  name.contains('man')) {
                selectedVoice = {
                  'name': voice['name']?.toString() ?? '',
                  'locale': voice['locale']?.toString() ?? '',
                };
                break;
              }
            }
            print(
              '🎤 Using UK MALE fallback voice: ${selectedVoice?['name'] ?? 'None found'}',
            );
          } else {
            // Look for UK female voices
            for (final voice in languageVoices) {
              final name = (voice['name'] as String?)?.toLowerCase() ?? '';
              if (name.contains('gbb') ||
                  name.contains('gbg') ||
                  name.contains('rjs') ||
                  name.contains('female') ||
                  name.contains('woman')) {
                selectedVoice = {
                  'name': voice['name']?.toString() ?? '',
                  'locale': voice['locale']?.toString() ?? '',
                };
                break;
              }
            }
            print(
              '🎤 Using UK FEMALE fallback voice: ${selectedVoice?['name'] ?? 'None found'}',
            );
          }
        } else {
          // Other languages: Use first available voice
          if (languageVoices.isNotEmpty) {
            final firstVoice = languageVoices.first;
            selectedVoice = {
              'name': firstVoice['name']?.toString() ?? '',
              'locale': firstVoice['locale']?.toString() ?? '',
            };
            print(
              '🎤 Using first available voice for $_language: ${selectedVoice['name']}',
            );
          }
        }
      }

      // Final fallback if no gender-specific voice found
      if (selectedVoice == null && languageVoices.isNotEmpty) {
        print('🎤 No gender-specific voice found, using first available voice');
        final firstVoice = languageVoices.first;
        selectedVoice = {
          'name': firstVoice['name']?.toString() ?? '',
          'locale': firstVoice['locale']?.toString() ?? '',
        };
      }

      // Apply the selected voice
      if (selectedVoice != null && selectedVoice.isNotEmpty) {
        final voiceName = selectedVoice['name']?.toString() ?? '';
        final voiceLocale = selectedVoice['locale']?.toString() ?? '';

        print(
          '🎤 Final voice selection: $voiceName ($voiceLocale) for ${_voiceGender == VoiceGender.male ? 'MALE' : 'FEMALE'} $_language',
        );

        await _flutterTts.setVoice({'name': voiceName, 'locale': voiceLocale});

        print('🎤 Voice applied successfully');
      } else {
        print(
          '🎤 ERROR: No suitable voice found for ${_voiceGender == VoiceGender.male ? 'MALE' : 'FEMALE'} $_language',
        );
      }
    } catch (e) {
      print('🎤 Error applying voice selection: $e');
    }
  }

  Future<void> initialize() async {
    print('🎤 initialize() called - _isInitialized: $_isInitialized');
    if (_isInitialized) {
      print('🎤 Already initialized, returning early');
      return;
    }

    if (_testMode) {
      _isInitialized = true;
      return;
    }

    print('🎤 Starting TTS Service initialization...');

    try {
      // Initialize TTS with background-friendly settings
      await _flutterTts.setLanguage(_language);
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(_volume);
      await _flutterTts.setPitch(_pitch);

      print('🎤 Basic TTS settings configured');

      // Configure for background playback
      await _flutterTts.setSharedInstance(true);
      await _flutterTts
          .setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ]);

      // Set up handlers
      print('🎤 Setting up TTS handlers...');
      _flutterTts.setStartHandler(() {
        print('🎤 TTS start handler called');
        _updatePlayingState(true);
      });

      _flutterTts.setCompletionHandler(() {
        print(
          '🎤 TTS completion handler called - isMultipleMode: $_isMultipleReadingsMode',
        );

        // Cancel fallback timer since we got the real completion
        if (_completionTimer?.isActive == true) {
          print('🎤 Cancelling fallback timer - real completion detected');
          _completionTimer?.cancel();
        }

        _updatePlayingState(false);

        // Only call the appropriate callback based on current mode
        if (_isMultipleReadingsMode) {
          print('🎤 Calling multiple reading completion callback');
          _onMultipleReadingComplete?.call();
        } else {
          print('🎤 Calling single reading completion callback');
          _onSingleReadingComplete?.call();
        }
      });

      _flutterTts.setErrorHandler((msg) {
        print('🎤 TTS error handler called: $msg');
        _updatePlayingState(false);
      });

      print('🎤 TTS handlers configured successfully');

      // Load and apply voice preferences
      await _loadVoicePreferences();

      // Debug: List available voices
      await debugListVoices();

      _isInitialized = true;
      print('🎤 TTS Service initialization completed successfully');
    } catch (e) {
      print('🎤 TTS Service initialization failed: $e');
      // TTS Service: Error during initialization
    }
  }

  // Debug method to list available voices
  Future<void> debugListVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      if (voices != null) {
        print('🎤 === AVAILABLE VOICES (${voices.length} total) ===');
        for (int i = 0; i < voices.length && i < 10; i++) {
          // Limit to first 10 voices
          final voice = voices[i];
          final name = voice['name'] ?? 'Unknown';
          final locale = voice['locale'] ?? 'Unknown';
          print('🎤 Voice $i: $name, Locale: $locale');
        }
        if (voices.length > 10) {
          print('🎤 ... and ${voices.length - 10} more voices');
        }
        print('🎤 === END VOICE LIST ===');
      } else {
        print('🎤 No voices available from TTS engine');
      }
    } catch (e) {
      print('🎤 Error listing voices: $e');
    }
  }

  Future<void> setVoiceGender(VoiceGender gender, {String? language}) async {
    // Prevent voice changes during multiple readings mode
    if (_isMultipleReadingsMode) {
      print('🎤 Voice change blocked: Multiple readings in progress');
      return;
    }

    await initialize();

    _voiceGender = gender;
    if (language != null) {
      _language = language;
      try {
        await _flutterTts.setLanguage(_language);
      } catch (e) {
        print('🎤 Error setting language: $e');
      }
    }

    print(
      '🎤 Setting voice gender to: ${gender == VoiceGender.male ? 'MALE' : 'FEMALE'} with language: $_language',
    );

    // Use the streamlined voice selection method
    await _applyVoiceSelection();
  }

  Future<void> setSpeechRate(double rate) async {
    await initialize();
    _speechRate = rate;
    try {
      await _flutterTts.setSpeechRate(rate);
    } catch (e) {
      // Error setting speech rate
    }
  }

  Future<void> setVolume(double volume) async {
    await initialize();
    _volume = volume;
    try {
      await _flutterTts.setVolume(volume);
    } catch (e) {
      // Error setting volume
    }
  }

  Future<void> setPitch(double pitch) async {
    await initialize();
    _pitch = pitch;
    try {
      await _flutterTts.setPitch(pitch);
    } catch (e) {
      // Error setting pitch
    }
  }

  Future<void> setVoice(Map<String, dynamic> voice) async {
    // Prevent voice changes during multiple readings mode
    if (_isMultipleReadingsMode) {
      print('🎤 Voice change blocked: Multiple readings in progress');
      return;
    }

    await initialize();
    try {
      await _flutterTts.setVoice({
        'name': voice['name']?.toString() ?? '',
        'locale': voice['locale']?.toString() ?? '',
      });
      print('🎤 Voice set to: ${voice['name']} (${voice['locale']})');
    } catch (e) {
      print('🎤 Error setting voice: $e');
    }
  }

  Future<void> speak(String text) async {
    print('🎤 speak called with text length: ${text.length}');
    await initialize();
    if (_disposed) {
      print('🎤 TTS service is disposed, cannot speak');
      return;
    }

    try {
      // Stop any current speech before starting new one
      await _flutterTts.stop();

      // Cancel any existing completion timer
      _completionTimer?.cancel();

      // Estimate speech duration more accurately based on current speech rate
      // Average 180 words per minute at normal rate (1.0)
      // Lower speech rate means slower speech, so we divide by the rate
      final adjustedWordsPerMinute = 180 / _speechRate;
      final estimatedDuration = Duration(
        milliseconds:
            (text.length / 5 / adjustedWordsPerMinute * 60 * 1000).round(),
      );
      final fallbackDuration =
          estimatedDuration +
          const Duration(milliseconds: 1000); // Slightly larger buffer

      print(
        '🎤 Estimated duration: ${estimatedDuration.inSeconds}s, fallback: ${fallbackDuration.inSeconds}s (rate: $_speechRate)',
      );

      print('🎤 Setting fallback timer for ${fallbackDuration.inSeconds}s');

      // Set up fallback timer
      _completionTimer = Timer(fallbackDuration, () {
        print('🎤 Fallback timer triggered - TTS completion not detected');
        _handleCompletionFallback();
      });

      print('🎤 Calling _flutterTts.speak()...');
      await _flutterTts.speak(text);
      print('🎤 _flutterTts.speak() completed');
    } catch (e) {
      print('🎤 Error in speak method: $e');
      _completionTimer?.cancel();
      // Error speaking
    }
  }

  Future<void> playReading(String title, String content) async {
    print('🎤 playReading called with title: "$title"');
    await initialize();
    if (_disposed) return;

    try {
      // Only acquire wake lock for individual readings, not during multiple readings mode
      if (!_isMultipleReadingsMode) {
        await _acquireWakeLock();
      }

      String textToRead = '$title. $content';
      print('🎤 About to speak: "${textToRead.substring(0, 50)}..."');

      // Store text for pause/resume functionality
      _pausedText = textToRead;
      _pausedTitle = title;

      await speak(textToRead);
    } catch (e) {
      print('🎤 Error playing reading: $e');
      // Error playing reading
      // Only release wake lock if we acquired it (not in multiple readings mode)
      if (!_isMultipleReadingsMode) {
        await _releaseWakeLock();
      }
    }
  }

  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      _isPaused = true;
      _isPlaying = false;
      isPlayingNotifier.value = false;
    } catch (e) {
      // Error pausing
    }
  }

  Future<void> resume() async {
    try {
      // Since Flutter TTS doesn't have a native resume method,
      // we restart the reading from the beginning
      if (_pausedText != null && _pausedTitle != null) {
        _isPaused = false;
        _isPlaying = true;
        isPlayingNotifier.value = true;
        await _flutterTts.speak(_pausedText!);
      }
    } catch (e) {
      // Error resuming
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _updatePlayingState(false);
      // Clear stored text when stopping
      _pausedText = null;
      _pausedTitle = null;
      await _releaseWakeLock();
    } catch (e) {
      // Error stopping
    }
  }

  void _updatePlayingState(bool playing) {
    _isPlaying = playing;
    _isPaused = false;
    isPlayingNotifier.value = playing;

    // Only release wake lock if not playing AND not in multiple readings mode
    if (!playing && !_isMultipleReadingsMode) {
      _releaseWakeLock();
    }
  }

  Future<void> _acquireWakeLock() async {
    try {
      await _methodChannel.invokeMethod('keepCpuAwake', {'keepAwake': true});
    } catch (e) {
      // Wake lock not available - this is non-critical
    }
  }

  Future<void> _releaseWakeLock() async {
    try {
      await _methodChannel.invokeMethod('keepCpuAwake', {'keepAwake': false});
    } catch (e) {
      // Wake lock not available - this is non-critical
    }
  }

  void setOnSingleReadingComplete(Function() callback) {
    _onSingleReadingComplete = callback;
  }

  void setMultipleReadingCallback(Function() callback) {
    _onMultipleReadingComplete = callback;
  }

  void clearMultipleReadingCallback() {
    _onMultipleReadingComplete = null;
  }

  // Methods to control multiple readings mode and wake lock persistence
  Future<void> startMultipleReadingsMode() async {
    print('🎤 startMultipleReadingsMode() called');
    _isMultipleReadingsMode = true;
    print('🎤 Multiple readings mode enabled: $_isMultipleReadingsMode');
    await _acquireWakeLock(); // Acquire wake lock immediately for entire session

    // Start foreground service for reliable background execution
    try {
      await _methodChannel.invokeMethod('startTtsService');
    } catch (e) {
      // Warning: Could not start TTS service
    }
  }

  void endMultipleReadingsMode() {
    _isMultipleReadingsMode = false;
    _releaseWakeLock();

    // Stop foreground service
    try {
      _methodChannel.invokeMethod('stopTtsService');
    } catch (e) {
      // Warning: Could not stop TTS service
    }
  }

  void dispose() {
    _disposed = true;
    _completionTimer?.cancel();
    _releaseWakeLock();
    isPlayingNotifier.dispose();
  }

  Future<List<dynamic>?> getAvailableVoices() async {
    await initialize();
    return await _flutterTts.getVoices;
  }

  Future<List<dynamic>?> getAvailableLanguages() async {
    await initialize();
    return await _flutterTts.getLanguages;
  }

  Future<void> testSpeak() async {
    await initialize();
    await speak('This is a test of the text to speech service.');
  }

  void _handleCompletionFallback() {
    print('🎤 Handling completion via fallback timer');

    // Only handle if timer is still active and we haven't already processed completion
    if (_completionTimer?.isActive != true) {
      print('🎤 Fallback already handled or cancelled, skipping');
      return;
    }

    _completionTimer?.cancel();
    _updatePlayingState(false);

    // Call the appropriate callback
    if (_isMultipleReadingsMode) {
      print('🎤 Calling multiple reading completion callback (fallback)');
      _onMultipleReadingComplete?.call();
    } else {
      print('🎤 Calling single reading completion callback (fallback)');
      _onSingleReadingComplete?.call();
    }
  }
}
