import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isEditMode;
  final VoidCallback onToggleEditMode;
  final VoidCallback onAddReading;
  final VoidCallback onNavigateToSettings;
  final VoidCallback onNavigateToAbout;
  final VoidCallback onNavigateToHelp;

  const CustomAppBar({
    Key? key,
    required this.isEditMode,
    required this.onToggleEditMode,
    required this.onAddReading,
    required this.onNavigateToSettings,
    required this.onNavigateToAbout,
    required this.onNavigateToHelp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        'AA Daily Prayers & Readings',
        style: TextStyle(fontSize: 18),
      ),
      actions: [
        // Edit mode toggle
        IconButton(
          icon: Icon(isEditMode ? Icons.check : Icons.edit),
          tooltip: isEditMode ? 'Save Changes' : 'Edit Mode',
          onPressed: onToggleEditMode,
        ),
        // Add reading button
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Add Reading',
          onPressed: onAddReading,
        ), // Menu for settings and about
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'settings') {
              onNavigateToSettings();
            } else if (value == 'about') {
              onNavigateToAbout();
            } else if (value == 'help') {
              onNavigateToHelp();
            }
          },
          itemBuilder:
              (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'help',
                  child: ListTile(
                    leading: Icon(Icons.help_outline),
                    title: Text('How to Use'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Settings'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'about',
                  child: ListTile(
                    leading: Icon(Icons.info),
                    title: Text('About'),
                  ),
                ),
              ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
