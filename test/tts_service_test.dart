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

    testWidgets('TTS service can set callbacks', (WidgetTester tester) async {
      // Test single reading callback
      ttsService.setOnSingleReadingComplete(() {
        // Callback set successfully
      });

      // Test multiple reading callback
      ttsService.setMultipleReadingCallback(() {
        // Callback set successfully
      });

      // Verify callbacks are set (we can't test actual TTS playback in unit tests)
      expect(ttsService, isNotNull);

      // Test clearing multiple reading callback
      ttsService.clearMultipleReadingCallback();

      // This test passes if no exceptions are thrown
    });

    tearDown(() {
      ttsService.dispose();
    });
  });
}
