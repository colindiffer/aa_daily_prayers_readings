import 'package:flutter/material.dart';
import '../widgets/reading_list_view.dart';
import '../widgets/sobriety_timer.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/scroll_arrows.dart';
import '../widgets/rating_banner.dart';
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

  // Multiple readings functionality
  Map<String, bool> selectedReadings = {};
  bool isMultipleMode = false;
  bool isPlayingMultiple = false;
  bool isPausedMultiple = false;
  bool isShuffleMode = false;
  int currentMultipleIndex = 0;
  List<Map<String, dynamic>> multiplePlaybackQueue = [];
  String currentlyPlayingMultipleTitle = '';

  // Single reading pause/resume functionality
  bool isPausedSingle = false;

  @override
  void initState() {
    super.initState();
    _ttsService = TTSService();
    _scrollController = ScrollController();
    _scrollController.addListener(_updateScrollArrows);
    _loadAppData();

    // Set up single reading completion callback to reset state when reading finishes
    _ttsService.setOnSingleReadingComplete(() {
      if (mounted) {
        setState(() {
          currentlyPlayingTitle = '';
          isPausedSingle = false;
        });
      }
    });
  }

  Future<void> _loadAppData() async {
    final appData = await AppDataManager.loadAppData();
    setState(() {
      final savedReadings =
          appData['userReadings'] as List<Map<String, dynamic>>;
      userReadings = savedReadings.isEmpty ? readings : savedReadings;
      sobrietyDate = appData['sobrietyDate'];
    });
  }

  void _updateScrollArrows() {
    setState(() {
      showUpArrow = _scrollController.offset > 100;
      showDownArrow =
          _scrollController.offset <
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

  // Multiple readings functionality
  void _toggleReadingSelection(String title) {
    setState(() {
      selectedReadings[title] = !(selectedReadings[title] ?? false);
    });
  }

  void _selectAllReadings() {
    setState(() {
      for (final reading in userReadings) {
        selectedReadings[reading['title']] = true;
      }
    });
  }

  void _clearAllSelections() {
    setState(() {
      selectedReadings.clear();
    });
  }

  void _toggleShuffleMode() {
    setState(() {
      isShuffleMode = !isShuffleMode;
    });
  }

  Future<void> _playMultipleReadings() async {
    // Filter selected readings
    List<Map<String, dynamic>> selectedForPlayback = [];
    try {
      selectedForPlayback =
          userReadings
              .where(
                (Map<String, dynamic> reading) =>
                    selectedReadings[reading['title']] == true,
              )
              .toList();
    } catch (e) {
      selectedForPlayback = [];
    }

    if (selectedForPlayback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select readings to play')),
      );
      return;
    }

    // Shuffle the readings if shuffle mode is enabled
    if (isShuffleMode) {
      selectedForPlayback.shuffle();
    }

    // Start multiple readings mode to enable wake lock persistence
    await _ttsService.startMultipleReadingsMode();

    // Set up the callback ONCE for the entire session to prevent callback overwrite bug
    _ttsService.setMultipleReadingCallback(() {
      print(
        '🎵 Multiple reading callback triggered - currentIndex: $currentMultipleIndex, queueLength: ${multiplePlaybackQueue.length}',
      );
      // Very short delay to ensure clean transition between readings
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          setState(() {
            currentMultipleIndex++;
          });
          print('🎵 Advanced to index: $currentMultipleIndex');

          if (currentMultipleIndex < multiplePlaybackQueue.length) {
            print('🎵 Playing next reading in queue');
            _playNextInQueue();
          } else {
            print('🎵 All readings completed, stopping multiple readings');
            _stopMultipleReadings();
          }
        }
      });
    });

    setState(() {
      multiplePlaybackQueue = selectedForPlayback;
      isPlayingMultiple = true;
      currentMultipleIndex = 0;
      isMultipleMode = true;
      currentlyPlayingTitle = ''; // Clear individual playing
    });

    _playNextInQueue();

    FirebaseAnalytics.instance.logEvent(
      name: "play_multiple_readings",
      parameters: {
        "reading_count": selectedForPlayback.length,
        "reading_names": selectedForPlayback.map((r) => r['title']).join(', '),
        "shuffle_mode": isShuffleMode ? "true" : "false",
      },
    );
  }

  void _playNextInQueue() {
    print(
      '🎵 _playNextInQueue called - currentIndex: $currentMultipleIndex, queueLength: ${multiplePlaybackQueue.length}',
    );
    if (currentMultipleIndex < multiplePlaybackQueue.length) {
      final currentReading = multiplePlaybackQueue[currentMultipleIndex];
      print('🎵 Playing reading: ${currentReading['title']}');
      setState(() {
        currentlyPlayingMultipleTitle = currentReading['title'];
      });

      _ttsService.playReading(
        currentReading['title'],
        currentReading['content'],
      );
    } else {
      print('🎵 Index out of bounds, stopping multiple readings');
    }
  }

  void _stopMultipleReadings() {
    setState(() {
      isPlayingMultiple = false;
      isMultipleMode = false;
      isPausedMultiple = false;
      currentlyPlayingMultipleTitle = '';
      multiplePlaybackQueue.clear();
      currentMultipleIndex = 0;
      // Clear selected readings after multiple readings finish
      selectedReadings.clear();
    });
    _ttsService.stop();
    _ttsService.clearMultipleReadingCallback();
    _ttsService
        .endMultipleReadingsMode(); // End multiple readings mode and release wake lock
  }

  void _pauseMultipleReadings() {
    setState(() {
      isPausedMultiple = true;
    });
    _ttsService.pause();
  }

  void _resumeMultipleReadings() {
    setState(() {
      isPausedMultiple = false;
    });
    _ttsService.resume();
  }

  void _skipToNextReading() {
    if (currentMultipleIndex < multiplePlaybackQueue.length - 1) {
      _ttsService.stop();
      setState(() {
        currentMultipleIndex++;
        isPausedMultiple = false;
      });
      _playNextInQueue();
    } else {
      _stopMultipleReadings();
    }
  }

  // Single reading pause/resume functionality
  void _pauseSingleReading() {
    setState(() {
      isPausedSingle = true;
    });
    _ttsService.pause();
  }

  void _resumeSingleReading() {
    setState(() {
      isPausedSingle = false;
    });
    _ttsService.resume();
  }

  void _stopSingleReading() {
    setState(() {
      currentlyPlayingTitle = '';
      isPausedSingle = false;
    });
    _ttsService.stop();
  }

  int get selectedReadingsCount {
    return selectedReadings.values.where((bool v) => v).length;
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
            if (isEditMode) {
              if (currentlyPlayingTitle.isNotEmpty) {
                currentlyPlayingTitle = '';
                isPausedSingle = false; // Reset pause state when stopping
                _ttsService.stop();
              }
              if (isPlayingMultiple) {
                _stopMultipleReadings();
              }
            }
          });
        },
        onAddReading: _showAddReadingDialog,
        onNavigateToSettings:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => SettingsPage(
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
        onNavigateToAbout:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutPage()),
            ),
        onNavigateToHelp:
            () => Navigator.push(
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
                onNavigateToSettings: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => SettingsPage(
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
                  );
                },
              ),
              const RatingBanner(),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: selectedReadingsCount > 0 ? 140.0 : 100.0,
                  ), // Extra padding when selections are made to account for taller bottom bar
                  child: ReadingListView(
                    readings: userReadings,
                    isEditMode: isEditMode,
                    onDeleteReading: (title) {
                      setState(() {
                        try {
                          userReadings.removeWhere(
                            (Map<String, dynamic> reading) =>
                                reading['title'] == title,
                          );
                        } catch (e) {
                          // Error removing reading
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
                      // Only allow individual play if not in multiple mode
                      if (!isMultipleMode) {
                        setState(() {
                          currentlyPlayingTitle = title;
                          isPausedSingle =
                              false; // Reset pause state when starting new reading
                        });
                        FirebaseAnalytics.instance.logEvent(
                          name: "play_individual_reading",
                          parameters: {"reading_name": title},
                        );
                        _ttsService.playReading(title, content);
                      }
                    },
                    onStopReading: () {
                      if (!isMultipleMode) {
                        setState(() {
                          currentlyPlayingTitle = '';
                        });
                        _ttsService.stop();
                      }
                    },
                    onReorder: _onReorderReadings,
                    scrollController: _scrollController,
                    currentlyPlayingTitle: currentlyPlayingTitle,
                    selectedReadings: selectedReadings,
                    onToggleSelection: _toggleReadingSelection,
                    isMultipleMode: isMultipleMode,
                    currentlyPlayingMultipleTitle:
                        currentlyPlayingMultipleTitle,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 10,
            left: MediaQuery.of(context).size.width / 2 - 20,
            child: ScrollArrows(
              showUpArrow: showUpArrow,
              showDownArrow: false,
              onUp:
                  () => _scrollController.animateTo(
                    _scrollController.offset - 200,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  ),
              onDown: () {},
            ),
          ),
          Positioned(
            bottom: 120, // Moved up to be above the bottom control bar
            left: MediaQuery.of(context).size.width / 2 - 20,
            child: ScrollArrows(
              showUpArrow: false,
              showDownArrow: showDownArrow,
              onUp: () {},
              onDown:
                  () => _scrollController.animateTo(
                    _scrollController.offset + 200,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  ),
            ),
          ),
          // Permanent bottom control bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Select All checkbox row (only when not playing multiple and readings are selected)
                  if (!isPlayingMultiple && selectedReadingsCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: IconButton(
                              iconSize: 24,
                              icon: Icon(
                                selectedReadingsCount == userReadings.length &&
                                        selectedReadingsCount > 0
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                              ),
                              onPressed:
                                  selectedReadingsCount ==
                                              userReadings.length &&
                                          selectedReadingsCount > 0
                                      ? _clearAllSelections
                                      : _selectAllReadings,
                              tooltip:
                                  selectedReadingsCount ==
                                              userReadings.length &&
                                          selectedReadingsCount > 0
                                      ? 'Deselect All'
                                      : 'Select All',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            selectedReadingsCount == userReadings.length &&
                                    selectedReadingsCount > 0
                                ? 'Deselect All'
                                : 'Select All',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  // Main control row
                  Row(
                    children: [
                      // Selection info or status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isPlayingMultiple)
                              Text(
                                'Playing ${currentMultipleIndex + 1} of ${multiplePlaybackQueue.length}${isShuffleMode ? ' • Shuffle' : ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            Text(
                              isPlayingMultiple
                                  ? currentlyPlayingMultipleTitle
                                  : currentlyPlayingTitle.isNotEmpty
                                  ? isPausedSingle
                                      ? 'Paused: $currentlyPlayingTitle'
                                      : 'Playing: $currentlyPlayingTitle'
                                  : selectedReadingsCount > 0
                                  ? '$selectedReadingsCount reading${selectedReadingsCount == 1 ? '' : 's'} selected'
                                  : 'Select readings to play multiple',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Control buttons - bigger size
                      if (isPlayingMultiple) ...[
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: IconButton(
                            iconSize: 32,
                            icon: Icon(
                              isPausedMultiple ? Icons.play_arrow : Icons.pause,
                            ),
                            onPressed:
                                isPausedMultiple
                                    ? _resumeMultipleReadings
                                    : _pauseMultipleReadings,
                            tooltip: isPausedMultiple ? 'Resume' : 'Pause',
                          ),
                        ),
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: IconButton(
                            iconSize: 32,
                            icon: const Icon(Icons.skip_next),
                            onPressed:
                                currentMultipleIndex <
                                        multiplePlaybackQueue.length - 1
                                    ? _skipToNextReading
                                    : null,
                            tooltip: 'Skip to Next',
                          ),
                        ),
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: IconButton(
                            iconSize: 32,
                            icon: const Icon(Icons.stop),
                            onPressed: _stopMultipleReadings,
                            tooltip: 'Stop',
                          ),
                        ),
                      ] else if (currentlyPlayingTitle.isNotEmpty) ...[
                        // Show pause/resume and stop buttons when single reading is playing
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: IconButton(
                            iconSize: 32,
                            icon: Icon(
                              isPausedSingle ? Icons.play_arrow : Icons.pause,
                            ),
                            onPressed:
                                isPausedSingle
                                    ? _resumeSingleReading
                                    : _pauseSingleReading,
                            tooltip: isPausedSingle ? 'Resume' : 'Pause',
                          ),
                        ),
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: IconButton(
                            iconSize: 32,
                            icon: const Icon(Icons.stop),
                            onPressed: _stopSingleReading,
                            tooltip: 'Stop Reading',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.1),
                            ),
                          ),
                        ),
                      ] else ...[
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: IconButton(
                            iconSize: 32,
                            icon: Icon(
                              isShuffleMode
                                  ? Icons.shuffle
                                  : Icons.shuffle_outlined,
                              color: isShuffleMode ? Colors.blue : null,
                            ),
                            onPressed: _toggleShuffleMode,
                            tooltip:
                                isShuffleMode ? 'Shuffle On' : 'Shuffle Off',
                          ),
                        ),
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: IconButton(
                            iconSize: 32,
                            icon: const Icon(Icons.play_arrow),
                            onPressed:
                                selectedReadingsCount > 0
                                    ? _playMultipleReadings
                                    : null,
                            tooltip: 'Play Selected',
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  selectedReadingsCount > 0
                                      ? Colors.blue.withOpacity(0.1)
                                      : null,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
