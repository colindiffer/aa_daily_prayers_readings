import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tts_service.dart';

class VoiceSelectionScreenNew extends StatefulWidget {
  const VoiceSelectionScreenNew({super.key});

  @override
  State<VoiceSelectionScreenNew> createState() =>
      _VoiceSelectionScreenNewState();
}

class _VoiceSelectionScreenNewState extends State<VoiceSelectionScreenNew> {
  final FlutterTts _testTts = FlutterTts();

  List<Map<String, dynamic>> _allVoices = [];
  List<Map<String, dynamic>> _usVoices = [];
  List<Map<String, dynamic>> _ukVoices = [];
  List<Map<String, dynamic>> _usMaleVoices = [];
  List<Map<String, dynamic>> _usFemaleVoices = [];
  List<Map<String, dynamic>> _ukMaleVoices = [];
  List<Map<String, dynamic>> _ukFemaleVoices = [];

  String? _selectedUsMaleVoice;
  String? _selectedUsFemaleVoice;
  String? _selectedUkMaleVoice;
  String? _selectedUkFemaleVoice;

  bool _isLoading = true;
  bool _isMultipleReadingsActive = false;

  // Default voice configurations - using indices for your preferred defaults
  static const Map<String, int> defaultVoiceIndices = {
    'us_male_voice': 12, // US Voice 12
    'us_female_voice': 6, // US Voice 6
    'uk_male_voice': 7, // UK Voice 7
    'uk_female_voice': 10, // UK Voice 10
  };

  // Fallback voice configurations if indices don't exist
  static const Map<String, String> defaultVoices = {
    'us_male_voice': 'en-us-x-iol-local',
    'us_female_voice': 'en-us-x-tpc-local',
    'uk_male_voice': 'en-gb-x-gbb-network',
    'uk_female_voice': 'en-gb-x-gba-local',
  };

  // Voice gender mapping based on your specific list
  // USA: Voice 1-4,6,7,11,13-16 = Female; Voice 5,8,9,10,12,17 = Male
  // UK: Voice 1,4,8,10,11,13 = Female; Voice 2,3,5,6,7,9,12 = Male
  static const Map<String, List<int>> voiceGenderByIndex = {
    'us_female_indices': [1, 2, 3, 4, 6, 7, 11, 13, 14, 15, 16],
    'us_male_indices': [5, 8, 9, 10, 12, 17],
    'uk_female_indices': [1, 4, 8, 10, 11, 13],
    'uk_male_indices': [2, 3, 5, 6, 7, 9, 12],
  };

  @override
  void initState() {
    super.initState();
    _initializeVoices();
    _checkMultipleReadingsStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check multiple readings status when the widget becomes visible
    _checkMultipleReadingsStatus();
  }

  void _checkMultipleReadingsStatus() {
    // Check the TTS service for multiple readings mode status
    final ttsService = TTSService();
    setState(() {
      _isMultipleReadingsActive = ttsService.isInMultipleReadingsMode;
    });
  }

  @override
  void dispose() {
    _testTts.stop();
    super.dispose();
  }

  /// Gets the default voice name for a preference based on the preferred index
  String? _getDefaultVoiceByIndex(
    String preferenceKey,
    List<Map<String, dynamic>> voices,
  ) {
    final preferredIndex = defaultVoiceIndices[preferenceKey];
    if (preferredIndex != null &&
        preferredIndex <= voices.length &&
        preferredIndex > 0) {
      // Convert to 0-based index and get the voice
      final voice = voices[preferredIndex - 1];
      return voice['originalName'] ?? voice['name'];
    }

    // Fallback to the original default voice name
    return defaultVoices[preferenceKey];
  }

  Future<void> _initializeVoices() async {
    try {
      await _testTts.setLanguage('en-US');

      final voices = await _testTts.getVoices;
      print('Retrieved ${voices?.length ?? 0} voices from TTS engine');

      if (voices != null && voices.isNotEmpty) {
        setState(() {
          // Cast the dynamic list to List<dynamic> first, then process
          final voiceList = List<dynamic>.from(voices);

          _allVoices =
              voiceList
                  .map<Map<String, dynamic>>((voice) {
                    // Handle both Map and other possible formats
                    if (voice is Map) {
                      return {
                        'name': voice['name']?.toString() ?? '',
                        'locale': voice['locale']?.toString() ?? '',
                        'originalName':
                            voice['name']?.toString() ??
                            '', // Keep original for TTS
                      };
                    } else {
                      // Fallback for unexpected formats
                      return {
                        'name': voice.toString(),
                        'locale': '',
                        'originalName': voice.toString(),
                      };
                    }
                  })
                  .where(
                    (Map<String, dynamic> voice) =>
                        voice['name']?.isNotEmpty == true,
                  )
                  .toList();

          // Filter US voices and assign friendly names
          _usVoices =
              _allVoices
                  .where(
                    (Map<String, dynamic> voice) =>
                        voice['locale']?.toLowerCase() == 'en-us',
                  )
                  .toList();

          // Assign simple friendly names first
          _assignFriendlyNames(_usVoices, 'US Voice');

          // Filter US voices by gender using index
          _usMaleVoices = [];
          _usFemaleVoices = [];

          for (int i = 0; i < _usVoices.length; i++) {
            final voiceIndex = i + 1; // Voice numbers start from 1
            if (voiceGenderByIndex['us_female_indices']!.contains(voiceIndex)) {
              _usFemaleVoices.add(_usVoices[i]);
            } else if (voiceGenderByIndex['us_male_indices']!.contains(
              voiceIndex,
            )) {
              _usMaleVoices.add(_usVoices[i]);
            }
          }

          // Filter UK voices and assign friendly names
          _ukVoices =
              _allVoices
                  .where(
                    (Map<String, dynamic> voice) =>
                        voice['locale']?.toLowerCase() == 'en-gb',
                  )
                  .toList();

          // Assign simple friendly names first
          _assignFriendlyNames(_ukVoices, 'UK Voice');

          // Filter UK voices by gender using index
          _ukMaleVoices = [];
          _ukFemaleVoices = [];

          for (int i = 0; i < _ukVoices.length; i++) {
            final voiceIndex = i + 1; // Voice numbers start from 1
            if (voiceGenderByIndex['uk_female_indices']!.contains(voiceIndex)) {
              _ukFemaleVoices.add(_ukVoices[i]);
            } else if (voiceGenderByIndex['uk_male_indices']!.contains(
              voiceIndex,
            )) {
              _ukMaleVoices.add(_ukVoices[i]);
            }
          }

          print(
            'Filtered voices: US Male: ${_usMaleVoices.length}, US Female: ${_usFemaleVoices.length}, UK Male: ${_ukMaleVoices.length}, UK Female: ${_ukFemaleVoices.length}',
          );

          _isLoading = false;
        });

        // Load saved preferences after voices are loaded
        await _loadSavedVoices();
      } else {
        print('No voices retrieved from TTS engine');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading voices: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSavedVoices() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      // Load saved voices or use index-based defaults
      final savedUsMale =
          prefs.getString('us_male_voice') ??
          _getDefaultVoiceByIndex('us_male_voice', _usVoices);
      final savedUsFemale =
          prefs.getString('us_female_voice') ??
          _getDefaultVoiceByIndex('us_female_voice', _usVoices);
      final savedUkMale =
          prefs.getString('uk_male_voice') ??
          _getDefaultVoiceByIndex('uk_male_voice', _ukVoices);
      final savedUkFemale =
          prefs.getString('uk_female_voice') ??
          _getDefaultVoiceByIndex('uk_female_voice', _ukVoices);

      // Set defaults if no saved preferences exist
      _setDefaultVoiceIfAvailable(
        'us_male_voice',
        savedUsMale,
        _usMaleVoices,
        (voice) => _selectedUsMaleVoice = voice,
      );
      _setDefaultVoiceIfAvailable(
        'us_female_voice',
        savedUsFemale,
        _usFemaleVoices,
        (voice) => _selectedUsFemaleVoice = voice,
      );
      _setDefaultVoiceIfAvailable(
        'uk_male_voice',
        savedUkMale,
        _ukMaleVoices,
        (voice) => _selectedUkMaleVoice = voice,
      );
      _setDefaultVoiceIfAvailable(
        'uk_female_voice',
        savedUkFemale,
        _ukFemaleVoices,
        (voice) => _selectedUkFemaleVoice = voice,
      );

      print(
        'Loaded voices - US Male: ${_usMaleVoices.length}, US Female: ${_usFemaleVoices.length}, UK Male: ${_ukMaleVoices.length}, UK Female: ${_ukFemaleVoices.length}',
      );
      print(
        'Selected voices: US Male: $_selectedUsMaleVoice, US Female: $_selectedUsFemaleVoice',
      );
      print(
        'Selected voices: UK Male: $_selectedUkMaleVoice, UK Female: $_selectedUkFemaleVoice',
      );
    });

    // Save defaults to preferences if this is the first time
    await _saveDefaultsIfNeeded(prefs);
  }

  void _setDefaultVoiceIfAvailable(
    String preferenceKey,
    String? voiceName,
    List<Map<String, dynamic>> availableVoices,
    Function(String?) setter,
  ) {
    if (voiceName != null) {
      // Check if the voice exists in the current list (by original name, display name, or locale)
      final voiceExists = availableVoices.any(
        (v) =>
            v['originalName'] == voiceName ||
            v['name'] == voiceName ||
            v['displayName'] == voiceName ||
            v['locale']?.toLowerCase() == voiceName.toLowerCase(),
      );

      if (voiceExists) {
        // Find the actual voice and use its display name
        final voice = availableVoices.firstWhere(
          (v) =>
              v['originalName'] == voiceName ||
              v['name'] == voiceName ||
              v['displayName'] == voiceName ||
              v['locale']?.toLowerCase() == voiceName.toLowerCase(),
          orElse: () => {'displayName': voiceName},
        );
        setter(voice['displayName']);
      } else {
        // If preferred voice not available, try to find a reasonable fallback
        final fallback = _findFallbackVoice(preferenceKey, availableVoices);
        setter(fallback);
        if (fallback != null) {
          print(
            'Default voice $voiceName not found for $preferenceKey, using fallback: $fallback',
          );
        }
      }
    }
  }

  String? _findFallbackVoice(
    String preferenceKey,
    List<Map<String, dynamic>> availableVoices,
  ) {
    if (availableVoices.isEmpty) return null;

    // Try to find a suitable fallback based on the preference type
    if (preferenceKey.contains('us')) {
      // For US voices, prefer voices with 'en-us' locale
      final usVoice = availableVoices.firstWhere(
        (v) => v['locale']?.toLowerCase().contains('en-us') == true,
        orElse: () => availableVoices.first,
      );
      return usVoice['displayName'];
    } else if (preferenceKey.contains('uk')) {
      // For UK voices, prefer voices with 'en-gb' locale
      final ukVoice = availableVoices.firstWhere(
        (v) => v['locale']?.toLowerCase().contains('en-gb') == true,
        orElse: () => availableVoices.first,
      );
      return ukVoice['displayName'];
    }

    // Default fallback to first available voice
    return availableVoices.first['displayName'];
  }

  Future<void> _saveDefaultsIfNeeded(SharedPreferences prefs) async {
    // Save the current selections (original names for TTS) to preferences
    if (_selectedUsMaleVoice != null && !prefs.containsKey('us_male_voice')) {
      final originalName = _getOriginalVoiceName(
        _selectedUsMaleVoice!,
        _usMaleVoices,
      );
      await prefs.setString('us_male_voice', originalName);
    }
    if (_selectedUsFemaleVoice != null &&
        !prefs.containsKey('us_female_voice')) {
      final originalName = _getOriginalVoiceName(
        _selectedUsFemaleVoice!,
        _usFemaleVoices,
      );
      await prefs.setString('us_female_voice', originalName);
    }
    if (_selectedUkMaleVoice != null && !prefs.containsKey('uk_male_voice')) {
      final originalName = _getOriginalVoiceName(
        _selectedUkMaleVoice!,
        _ukMaleVoices,
      );
      await prefs.setString('uk_male_voice', originalName);
    }
    if (_selectedUkFemaleVoice != null &&
        !prefs.containsKey('uk_female_voice')) {
      final originalName = _getOriginalVoiceName(
        _selectedUkFemaleVoice!,
        _ukFemaleVoices,
      );
      await prefs.setString('uk_female_voice', originalName);
    }
  }

  String _getOriginalVoiceName(
    String displayName,
    List<Map<String, dynamic>> voices,
  ) {
    final voice = voices.firstWhere(
      (v) => v['displayName'] == displayName,
      orElse: () => {'originalName': displayName, 'name': displayName},
    );
    return voice['originalName'] ?? voice['name'] ?? displayName;
  }

  Future<void> _saveVoicePreference(
    String key,
    String displayName,
    List<Map<String, dynamic>> voices,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final originalName = _getOriginalVoiceName(displayName, voices);
    await prefs.setString(key, originalName);
  }

  Future<void> _testVoice(
    String originalVoiceName,
    String locale,
    String displayName,
  ) async {
    try {
      await _testTts.setVoice({'name': originalVoiceName, 'locale': locale});
      await _testTts.speak('This is a test of $displayName.');
    } catch (e) {
      print('Error testing voice: $e');
    }
  }

  Widget _buildVoiceDropdown({
    required String title,
    required List<Map<String, dynamic>> voices,
    required String? selectedVoice,
    required Function(String?) onChanged,
    required String preferenceKey,
    bool enabled = true,
  }) {
    final defaultVoiceName = _getDefaultVoiceByIndex(
      preferenceKey,
      preferenceKey.contains('us') ? _usVoices : _ukVoices,
    );
    final isUsingDefault =
        selectedVoice != null &&
        voices.any(
          (v) =>
              v['displayName'] == selectedVoice &&
              (v['originalName'] == defaultVoiceName ||
                  v['name'] == defaultVoiceName),
        );

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isUsingDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Default',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedVoice,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                filled: isUsingDefault,
                fillColor: isUsingDefault ? Colors.green.shade50 : null,
              ),
              hint: Text('Select a voice (${voices.length} available)'),
              isExpanded: true,
              items:
                  voices.isEmpty
                      ? null
                      : voices.map((voice) {
                        final isDefault =
                            voice['originalName'] == defaultVoiceName ||
                            voice['name'] == defaultVoiceName;
                        return DropdownMenuItem<String>(
                          value: voice['displayName'],
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  voice['displayName']!,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isDefault)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Recommended',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
              onChanged:
                  voices.isEmpty || !enabled
                      ? null
                      : (String? newValue) {
                        if (newValue != null) {
                          onChanged(newValue);
                          _saveVoicePreference(preferenceKey, newValue, voices);
                        }
                      },
            ),
            const SizedBox(height: 8),
            if (voices.isEmpty)
              const Text(
                'No voices available for this language',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            if (selectedVoice != null)
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        enabled && !_isMultipleReadingsActive
                            ? () {
                              final voice = voices.firstWhere(
                                (v) => v['displayName'] == selectedVoice,
                                orElse:
                                    () => {
                                      'originalName': '',
                                      'locale': '',
                                      'displayName': '',
                                    },
                              );
                              _testVoice(
                                voice['originalName']!,
                                voice['locale']!,
                                voice['displayName']!,
                              );
                            }
                            : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Test Voice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isUsingDefault ? Colors.green : null,
                      foregroundColor: isUsingDefault ? Colors.white : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected: $selectedVoice',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (defaultVoiceName != null && !isUsingDefault)
                          Text(
                            'Default: $defaultVoiceName',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      // Reset to default voices using index-based preferences
      _setDefaultVoiceIfAvailable(
        'us_male_voice',
        _getDefaultVoiceByIndex('us_male_voice', _usVoices),
        _usMaleVoices,
        (voice) => _selectedUsMaleVoice = voice,
      );
      _setDefaultVoiceIfAvailable(
        'us_female_voice',
        _getDefaultVoiceByIndex('us_female_voice', _usVoices),
        _usFemaleVoices,
        (voice) => _selectedUsFemaleVoice = voice,
      );
      _setDefaultVoiceIfAvailable(
        'uk_male_voice',
        _getDefaultVoiceByIndex('uk_male_voice', _ukVoices),
        _ukMaleVoices,
        (voice) => _selectedUkMaleVoice = voice,
      );
      _setDefaultVoiceIfAvailable(
        'uk_female_voice',
        _getDefaultVoiceByIndex('uk_female_voice', _ukVoices),
        _ukFemaleVoices,
        (voice) => _selectedUkFemaleVoice = voice,
      );
    });

    // Save the defaults to preferences (original names for TTS)
    if (_selectedUsMaleVoice != null) {
      final originalName = _getOriginalVoiceName(
        _selectedUsMaleVoice!,
        _usMaleVoices,
      );
      await prefs.setString('us_male_voice', originalName);
    }
    if (_selectedUsFemaleVoice != null) {
      final originalName = _getOriginalVoiceName(
        _selectedUsFemaleVoice!,
        _usFemaleVoices,
      );
      await prefs.setString('us_female_voice', originalName);
    }
    if (_selectedUkMaleVoice != null) {
      final originalName = _getOriginalVoiceName(
        _selectedUkMaleVoice!,
        _ukMaleVoices,
      );
      await prefs.setString('uk_male_voice', originalName);
    }
    if (_selectedUkFemaleVoice != null) {
      final originalName = _getOriginalVoiceName(
        _selectedUkFemaleVoice!,
        _ukFemaleVoices,
      );
      await prefs.setString('uk_female_voice', originalName);
    }

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice selections reset to defaults!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String? selectedVoice,
    String? defaultVoice,
  ) {
    final isDefault =
        selectedVoice == defaultVoice ||
        (selectedVoice != null &&
            defaultVoice != null &&
            selectedVoice.toLowerCase() == defaultVoice.toLowerCase());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedVoice ?? 'Not selected',
                    style: TextStyle(
                      color:
                          selectedVoice != null ? Colors.black87 : Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isDefault)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Default',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Settings'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Voice Settings',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'We\'ve pre-selected high-quality voices for each accent and gender combination. You can test and change these selections anytime.',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Default voices are marked with this badge',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Show blocking message if multiple readings are active
                    if (_isMultipleReadingsActive) ...[
                      Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lock,
                                    color: Colors.orange.shade700,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Voice settings are temporarily locked',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Multiple readings are currently playing. Voice settings cannot be changed during playback to ensure a smooth listening experience.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.orange.shade800,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.orange.shade700,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Go back to the readings screen to stop playback, then return here to adjust your voice settings.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.orange.shade700,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    const Text(
                      'Select specific voices for each accent and gender combination:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),

                    // Voice selection content with opacity overlay when disabled
                    Opacity(
                      opacity: _isMultipleReadingsActive ? 0.4 : 1.0,
                      child: IgnorePointer(
                        ignoring: _isMultipleReadingsActive,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // USA Voices Section
                            const Text(
                              '🇺🇸 USA Voices',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),

                            _buildVoiceDropdown(
                              title: 'USA Male Voice',
                              voices: _usMaleVoices,
                              selectedVoice: _selectedUsMaleVoice,
                              onChanged:
                                  (value) => setState(
                                    () => _selectedUsMaleVoice = value,
                                  ),
                              preferenceKey: 'us_male_voice',
                              enabled: !_isMultipleReadingsActive,
                            ),

                            _buildVoiceDropdown(
                              title: 'USA Female Voice',
                              voices: _usFemaleVoices,
                              selectedVoice: _selectedUsFemaleVoice,
                              onChanged:
                                  (value) => setState(
                                    () => _selectedUsFemaleVoice = value,
                                  ),
                              preferenceKey: 'us_female_voice',
                              enabled: !_isMultipleReadingsActive,
                            ),

                            const SizedBox(height: 20),

                            // UK Voices Section
                            const Text(
                              '🇬🇧 UK Voices',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),

                            _buildVoiceDropdown(
                              title: 'UK Male Voice',
                              voices: _ukMaleVoices,
                              selectedVoice: _selectedUkMaleVoice,
                              onChanged:
                                  (value) => setState(
                                    () => _selectedUkMaleVoice = value,
                                  ),
                              preferenceKey: 'uk_male_voice',
                              enabled: !_isMultipleReadingsActive,
                            ),

                            _buildVoiceDropdown(
                              title: 'UK Female Voice',
                              voices: _ukFemaleVoices,
                              selectedVoice: _selectedUkFemaleVoice,
                              onChanged:
                                  (value) => setState(
                                    () => _selectedUkFemaleVoice = value,
                                  ),
                              preferenceKey: 'uk_female_voice',
                              enabled: !_isMultipleReadingsActive,
                            ),

                            const SizedBox(height: 30),

                            // Summary
                            Card(
                              color: Colors.green.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'Current Selection Summary:',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        TextButton.icon(
                                          onPressed:
                                              _isMultipleReadingsActive
                                                  ? null
                                                  : _resetToDefaults,
                                          icon: const Icon(
                                            Icons.refresh,
                                            size: 16,
                                          ),
                                          label: const Text(
                                            'Reset to Defaults',
                                          ),
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                Colors.blue.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    _buildSummaryRow(
                                      '🇺🇸 USA Male',
                                      _selectedUsMaleVoice,
                                      _getDefaultVoiceByIndex(
                                        'us_male_voice',
                                        _usVoices,
                                      ),
                                    ),
                                    _buildSummaryRow(
                                      '🇺🇸 USA Female',
                                      _selectedUsFemaleVoice,
                                      _getDefaultVoiceByIndex(
                                        'us_female_voice',
                                        _usVoices,
                                      ),
                                    ),
                                    _buildSummaryRow(
                                      '🇬🇧 UK Male',
                                      _selectedUkMaleVoice,
                                      _getDefaultVoiceByIndex(
                                        'uk_male_voice',
                                        _ukVoices,
                                      ),
                                    ),
                                    _buildSummaryRow(
                                      '🇬🇧 UK Female',
                                      _selectedUkFemaleVoice,
                                      _getDefaultVoiceByIndex(
                                        'uk_female_voice',
                                        _ukVoices,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),

                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Voice preferences saved!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: const Text('Save and Return'),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  void _assignFriendlyNames(List<Map<String, dynamic>> voices, String prefix) {
    for (int i = 0; i < voices.length; i++) {
      voices[i]['displayName'] = '$prefix ${i + 1}';
    }
  }
}
