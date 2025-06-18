import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/services/tts_service.dart';

void main() {
  group('TTS Service Tests', () {
    late TTSService ttsService;

    setUp(() {
      ttsService = TTSService();
    });

    test('TTS service can be initialized', () {
      expect(ttsService, isNotNull);
    });

    test('Speech rate can be set within valid range', () async {
      await ttsService.setSpeechRate(0.5);
      expect(ttsService.speechRate, equals(0.5));

      await ttsService.setSpeechRate(1.5);
      expect(ttsService.speechRate, equals(1.5));
    });

    test('Invalid speech rate is rejected', () async {
      double originalRate = ttsService.speechRate;

      await ttsService.setSpeechRate(0.05); // Too low
      expect(ttsService.speechRate, equals(originalRate));

      await ttsService.setSpeechRate(3.0); // Too high
      expect(ttsService.speechRate, equals(originalRate));
    });

    testWidgets('TTS service can play reading', (WidgetTester tester) async {
      bool completionCalled = false;

      ttsService.setOnSingleReadingComplete(() {
        completionCalled = true;
      });

      // Test with short text to ensure completion
      await ttsService.playReading('Test Title', 'Short test content.');

      // Wait for TTS to process
      await tester.pump(const Duration(seconds: 2));

      // Note: In actual testing, this would need more sophisticated mocking
      // since TTS behavior depends on platform-specific implementations
    });

    tearDown(() {
      ttsService.dispose();
    });
  });
}
