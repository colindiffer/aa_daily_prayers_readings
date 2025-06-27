import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Use This App'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Getting Started',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInstructionCard(
              context,
              'Playing Individual Readings',
              'Simply tap on any reading title to play it. Tap again to stop playback.',
              Icons.play_circle_filled,
            ),
            const SizedBox(height: 16),
            _buildInstructionCard(
              context,
              'Multiple Reading Selection',
              'Use the checkboxes to select multiple readings, then press the play button at the bottom of the screen to play them in sequence.',
              Icons.playlist_play,
            ),
            const SizedBox(height: 16),
            _buildInstructionCard(
              context,
              'Edit Mode',
              'Toggle edit mode using the pencil icon in the top bar to rearrange readings or delete custom readings (pre-installed readings cannot be deleted).',
              Icons.edit,
            ),
            const SizedBox(height: 16),
            _buildInstructionCard(
              context,
              'Adding Custom Readings',
              'Press the + button in the top bar to add your own readings with custom titles and content.',
              Icons.add_circle,
            ),
            const SizedBox(height: 16),
            _buildInstructionCard(
              context,
              'Playback Controls',
              'Use the controls at the bottom of the screen to play, pause, skip, or stop readings.',
              Icons.music_note,
            ),
            const SizedBox(height: 16),
            _buildInstructionCard(
              context,
              'Selecting All Readings',
              'On wider screens, use the "Select All Readings" button in the side panel to quickly select all readings.',
              Icons.select_all,
            ),
            const SizedBox(height: 16),
            _buildInstructionCard(
              context,
              'Sobriety Tracking',
              'Set your sobriety date in Settings to track your days sober.',
              Icons.calendar_today,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionCard(
      BuildContext context, String title, String content, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
