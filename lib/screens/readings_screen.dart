import 'package:flutter/material.dart';
import '../widgets/reading_list_view.dart';
import '../widgets/sobriety_timer.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/scroll_arrows.dart';
import '../widgets/review_request_banner.dart';
import '../services/tts_service.dart';
import '../data/readings.dart';
import '../utils/app_data_manager.dart';
import 'settings_page.dart';
import 'about_page.dart';
import 'help_screen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class ReadingsScreen extends StatefulWidget {
  const ReadingsScreen({super.key});

  @override
  State<ReadingsScreen> createState() => _ReadingsScreenState();
}

class _ReadingsScreenState extends State<ReadingsScreen> {
  late TTSService _ttsService;
  List<Map<String, dynamic>> userReadings = [];
  bool isEditMode = false;
  String currentlyPlayingTitle = '';
  late ScrollController _scrollController;
  bool showUpArrow = false;
  bool showDownArrow = true;
  DateTime? sobrietyDate;

  @override
  void initState() {
    super.initState();
    debugPrint('ReadingsScreen initState called');
    
    try {
      _ttsService = TTSService();
      debugPrint('TTS Service initialized');
      
      _scrollController = ScrollController();
      _scrollController.addListener(_updateScrollArrows);
      debugPrint('Scroll controller initialized');
      
      _loadAppData();
      debugPrint('App data loading started');
    } catch (e, stackTrace) {
      debugPrint('Error in ReadingsScreen initState: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> _loadAppData() async {
    try {
      debugPrint('Loading app data...');
      final appData = await AppDataManager.loadAppData();
      debugPrint('App data loaded: ${appData.keys}');
      
      setState(() {
        final savedReadings =
            appData['userReadings'] as List<Map<String, dynamic>>;
        userReadings = savedReadings.isEmpty ? readings : savedReadings;
        sobrietyDate = appData['sobrietyDate'];
      });
      
      debugPrint('App data set - readings count: ${userReadings.length}');
    } catch (e, stackTrace) {
      debugPrint('Error loading app data: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Fallback to default readings
      setState(() {
        userReadings = readings;
        sobrietyDate = null;
      });
    }
  }

  void _updateScrollArrows() {
    setState(() {
      showUpArrow = _scrollController.offset > 100;
      showDownArrow = _scrollController.offset <
          _scrollController.position.maxScrollExtent - 100;
    });
  }

  void _onReorderReadings(int oldIndex, int newIndex) {
    setState(() {
      // Adjust newIndex if moving item down
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      // Remove the item from the old position
      final Map<String, dynamic> item = userReadings.removeAt(oldIndex);

      // Insert it at the new position
      userReadings.insert(newIndex, item);
    });

    // Save the reordered list
    AppDataManager.saveAppData(
      userReadings: userReadings,
      selectedVoice: 'en-US',
      sobrietyDate: sobrietyDate,
    );

    // Log analytics
    FirebaseAnalytics.instance.logEvent(
      name: "reorder_readings",
      parameters: {"old_index": oldIndex, "new_index": newIndex},
    );
  }

  void _showAddReadingDialog() {
    TextEditingController titleController = TextEditingController();
    TextEditingController contentController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add New Reading"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: "Content"),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    contentController.text.isNotEmpty) {
                  setState(() {
                    userReadings.add({
                      'title': titleController.text,
                      'content': contentController.text,
                      'protected': false,
                    });
                    AppDataManager.saveAppData(
                      userReadings: userReadings,
                      selectedVoice: 'en-US',
                      sobrietyDate: sobrietyDate,
                    );
                  });
                  FirebaseAnalytics.instance.logEvent(
                    name: "add_new_reading",
                    parameters: {"reading_title": titleController.text},
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _ttsService.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        isEditMode: isEditMode,
        onToggleEditMode: () {
          setState(() {
            isEditMode = !isEditMode;
            // Stop any playing reading when entering edit mode
            if (isEditMode && currentlyPlayingTitle.isNotEmpty) {
              currentlyPlayingTitle = '';
              _ttsService.stop();
            }
          });
        },
        onAddReading: _showAddReadingDialog,
        onNavigateToSettings: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SettingsPage(
              sobrietyDate: sobrietyDate,
              onSettingsChanged: (newSobrietyDate) {
                setState(() {
                  sobrietyDate = newSobrietyDate;
                });
                AppDataManager.saveAppData(
                  userReadings: userReadings,
                  selectedVoice: 'en-US',
                  sobrietyDate: sobrietyDate,
                );
              },
              ttsService: _ttsService,
            ),
          ),
        ),
        onNavigateToAbout: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AboutPage()),
        ),
        onNavigateToHelp: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HelpScreen()),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              SobrietyTimer(
                sobrietyDate: sobrietyDate,
                onNavigateToSettings: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(
                      sobrietyDate: sobrietyDate,
                      onSettingsChanged: (newSobrietyDate) {
                        setState(() {
                          sobrietyDate = newSobrietyDate;
                        });
                        AppDataManager.saveAppData(
                          userReadings: userReadings,
                          selectedVoice: 'en-US',
                          sobrietyDate: sobrietyDate,
                        );
                      },
                      ttsService: _ttsService,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ReadingListView(
                  readings: userReadings,
                  isEditMode: isEditMode,
                  onDeleteReading: (title) {
                    setState(() {
                      try {
                        userReadings.removeWhere(
                            (Map<String, dynamic> reading) =>
                                reading['title'] == title);
                      } catch (e) {
                        debugPrint('Error removing reading: $e');
                      }
                      AppDataManager.saveAppData(
                        userReadings: userReadings,
                        selectedVoice: 'en-US',
                        sobrietyDate: sobrietyDate,
                      );
                    });
                    FirebaseAnalytics.instance.logEvent(
                      name: "delete_reading",
                      parameters: {"reading_title": title},
                    );
                  },
                  onPlayReading: (title, content) {
                    setState(() {
                      currentlyPlayingTitle = title;
                    });
                    FirebaseAnalytics.instance.logEvent(
                      name: "play_individual_reading",
                      parameters: {"reading_name": title},
                    );
                    _ttsService.playReading(title, content);
                  },
                  onStopReading: () {
                    setState(() {
                      currentlyPlayingTitle = '';
                    });
                    _ttsService.stop();
                  },
                  onReorder: _onReorderReadings,
                  scrollController: _scrollController,
                  currentlyPlayingTitle: currentlyPlayingTitle,
                ),
              ),
            ],
          ),
          // Review request banner
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ReviewRequestBanner(),
          ),
          // Scroll arrows
          Positioned(
            top: 10,
            left: MediaQuery.of(context).size.width / 2 - 20,
            child: ScrollArrows(
              showUpArrow: showUpArrow,
              showDownArrow: false,
              onUp: () => _scrollController.animateTo(
                _scrollController.offset - 200,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              ),
              onDown: () {},
            ),
          ),
          Positioned(
            bottom: 10,
            left: MediaQuery.of(context).size.width / 2 - 20,
            child: ScrollArrows(
              showUpArrow: false,
              showDownArrow: showDownArrow,
              onUp: () {},
              onDown: () => _scrollController.animateTo(
                _scrollController.offset + 200,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
