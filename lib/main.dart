import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'data/readings.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AA Readings',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ReadingsScreen(),
    );
  }
}

class ReadingsScreen extends StatefulWidget {
  const ReadingsScreen({super.key});

  @override
  State<ReadingsScreen> createState() => _ReadingsScreenState();
}

class _ReadingsScreenState extends State<ReadingsScreen> {
  final FlutterTts flutterTts = FlutterTts();
  Map<String, bool> selectedReadings = {};
  bool isPlaying = false;
  bool shouldStop = false;
  bool isEditMode = false;

  @override
  void initState() {
    super.initState();
    for (var reading in readings) {
      selectedReadings[reading['title']] = false;
    }
  }

  Future<void> _speak(String title, String text) async {
    await flutterTts.stop(); // Stop any ongoing playback
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);

    await flutterTts.speak(title);
    await flutterTts.awaitSpeakCompletion(true);

    await flutterTts.speak(text);
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> _playSelectedReadings() async {
    setState(() {
      isPlaying = true;
      shouldStop = false;
    });

    for (var reading in readings) {
      if (selectedReadings[reading['title']] == true) {
        if (shouldStop) break; // Stop if the user presses "Stop All"
        await _speak(reading['title']!, reading['content']!);
      }
    }

    setState(() {
      isPlaying = false;
    });
  }

  void _stopAll() {
    setState(() {
      shouldStop = true;
      isPlaying = false;
    });
    flutterTts.stop();
  }

  void _addReading() {
    String newTitle = '';
    String newContent = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Reading'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Title'),
                onChanged: (value) {
                  newTitle = value;
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 5,
                onChanged: (value) {
                  newContent = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (newTitle.isNotEmpty && newContent.isNotEmpty) {
                  setState(() {
                    readings.add({
                      'title': newTitle,
                      'content': newContent,
                      'protected': false, // New readings are not protected
                    });
                    selectedReadings[newTitle] = false;
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _toggleEditMode() {
    setState(() {
      isEditMode = !isEditMode;
    });
  }

  void _deleteReading(int index) {
    if (readings[index]['protected'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cannot delete protected readings."),
        ),
      );
      return; // Do nothing if the reading is protected
    }
    setState(() {
      selectedReadings.remove(readings[index]['title']);
      readings.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AA Readings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addReading,
            tooltip: 'Add Reading',
          ),
          IconButton(
            icon: Icon(isEditMode ? Icons.check : Icons.edit),
            onPressed: _toggleEditMode,
            tooltip: isEditMode ? 'Finish Editing' : 'Edit Readings',
          ),
        ],
      ),
      body: ReorderableListView.builder(
        itemCount: readings.length,
        onReorder: (oldIndex, newIndex) {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          setState(() {
            final reading = readings.removeAt(oldIndex);
            readings.insert(newIndex, reading);
          });
        },
        itemBuilder: (context, index) {
          final reading = readings[index];
          return ListTile(
            key: ValueKey(reading['title']),
            leading: isEditMode
                ? IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteReading(index),
              tooltip: 'Delete',
            )
                : Checkbox(
              value: selectedReadings[reading['title']],
              onChanged: (bool? value) {
                setState(() {
                  selectedReadings[reading['title']] = value ?? false;
                });
              },
            ),
            title: Text(reading['title']!),
            trailing: isEditMode
                ? const Icon(Icons.drag_handle)
                : IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.lightBlue),
              onPressed: () => _speak(reading['title']!, reading['content']!),
              tooltip: 'Play',
            ),
          );
        },
      ),
      bottomNavigationBar: isEditMode
          ? null
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
              onPressed: isPlaying ? null : _playSelectedReadings,
              child: const Text('Play Selected Readings'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
              onPressed: _stopAll,
              child: const Text('Stop All'),
            ),
          ],
        ),
      ),
    );
  }
}
