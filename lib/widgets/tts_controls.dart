import 'package:flutter/material.dart';
import '../services/tts_service.dart';

class TtsControls extends StatefulWidget {
  final String text;

  const TtsControls({Key? key, required this.text}) : super(key: key);

  @override
  State<TtsControls> createState() => _TtsControlsState();
}

class _TtsControlsState extends State<TtsControls> {
  final TTSService _ttsService = TTSService();
  VoiceGender _selectedGender = VoiceGender.male;
  String _selectedLanguage = 'en-GB'; // Always use UK English
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    // Listen to TTS service state changes
    _ttsService.isPlayingNotifier.addListener(_onPlayingStateChanged);
  }

  void _onPlayingStateChanged() {
    setState(() {
      _isPlaying = _ttsService.isPlayingNotifier.value;
    });
  }

  Future<void> _initTts() async {
    await _ttsService.setVoiceGender(_selectedGender,
        language: _selectedLanguage);
  }

  @override
  void dispose() {
    _ttsService.isPlayingNotifier.removeListener(_onPlayingStateChanged);
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gender selection only - language is always UK English
            DropdownButton<VoiceGender>(
              value: _selectedGender,
              onChanged: (VoiceGender? newValue) async {
                if (newValue != null) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                  await _ttsService.setVoiceGender(newValue,
                      language: _selectedLanguage);
                }
              },
              items: VoiceGender.values
                  .map<DropdownMenuItem<VoiceGender>>((VoiceGender value) {
                return DropdownMenuItem<VoiceGender>(
                  value: value,
                  child: Text(value.toString().split('.').last),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () {
                if (_isPlaying) {
                  _ttsService.pause();
                } else {
                  _ttsService.speak(widget.text);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () {
                _ttsService.stop();
              },
            ),
          ],
        ),
      ],
    );
  }
}
