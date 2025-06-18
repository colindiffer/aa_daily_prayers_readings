import 'package:flutter/material.dart';

class ReadingListView extends StatefulWidget {
  final List<Map<String, dynamic>> readings;
  final bool isEditMode;
  final Function(String) onDeleteReading;
  final Function(String, String) onPlayReading;
  final Function() onStopReading;
  final Function(int, int)? onReorder; // Add reorder callback
  final ScrollController scrollController;
  final String currentlyPlayingTitle;

  const ReadingListView({
    super.key,
    required this.readings,
    required this.isEditMode,
    required this.onDeleteReading,
    required this.onPlayReading,
    required this.onStopReading,
    this.onReorder, // Add to constructor
    required this.scrollController,
    required this.currentlyPlayingTitle,
  });

  @override
  State<ReadingListView> createState() => _ReadingListViewState();
}

class _ReadingListViewState extends State<ReadingListView>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    try {
      _pulseController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      );

      _pulseAnimation = Tween<double>(
        begin: 0.8,
        end: 1.2,
      ).animate(CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ));

      // Start animations only after widget is mounted
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _pulseController.repeat(reverse: true);
        }
      });
    } catch (e) {
      debugPrint('Error initializing animations: $e');
    }
  }

  @override
  void dispose() {
    try {
      _pulseController.stop();
      _pulseController.dispose();
    } catch (e) {
      debugPrint('Error disposing animation controllers: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditMode && widget.onReorder != null) {
      // Use ReorderableListView for edit mode with drag-and-drop
      return ReorderableListView.builder(
        scrollController: widget.scrollController,
        itemCount: widget.readings.length,
        onReorder: widget.onReorder!,
        itemBuilder: (context, index) {
          final reading = widget.readings[index];
          final isProtected = reading['protected'] ?? false;
          final isPlaying = (reading['title'] == widget.currentlyPlayingTitle);

          return ListTile(
            key: ValueKey(reading['title']), // Important for reordering
            leading: const Icon(Icons.drag_handle),
            title: Text(
              reading['title'],
              style: TextStyle(
                color: isPlaying ? Colors.blue : Colors.black,
                fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Show reading duration in edit mode too
                _buildDurationIndicator(reading),
                const SizedBox(width: 8),
                // Delete/Lock icon
                IconButton(
                  icon: Icon(
                    isProtected ? Icons.lock : Icons.delete,
                    color: isProtected ? Colors.grey : Colors.red,
                  ),
                  onPressed: isProtected
                      ? null
                      : () => widget.onDeleteReading(reading['title']),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // Use regular ListView for normal mode
      return ListView.builder(
        controller: widget.scrollController,
        itemCount: widget.readings.length,
        itemBuilder: (context, index) {
          final reading = widget.readings[index];
          final isPlaying = (reading['title'] == widget.currentlyPlayingTitle);

          return Column(
            children: [
              ListTile(
                title: Text(
                  reading['title'],
                  style: TextStyle(
                    color: isPlaying ? Colors.blue : Colors.black,
                    fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  // Click to play/stop reading directly
                  if (!isPlaying) {
                    widget.onPlayReading(reading['title'], reading['content']);
                  } else {
                    widget.onStopReading();
                  }
                },
                trailing:
                    _buildTrailingWidget(reading, isPlaying, widget.isEditMode),
              ),
              // Progress bar removed as requested
            ],
          );
        },
      );
    }
  }

  Widget _buildDurationIndicator(Map<String, dynamic> reading) {
    // Calculate estimated reading time (average 200 words per minute)
    final content = reading['content'] ?? '';
    final wordCount =
        content.split(' ').where((String word) => word.isNotEmpty).length;

    // Calculate time in seconds, then format appropriately
    final totalSeconds = ((wordCount / 200) * 60).ceil();

    String timeText;
    if (totalSeconds < 60) {
      timeText = '$totalSeconds Secs';
    } else {
      final minutes = totalSeconds / 60;
      if (minutes <= 1.0) {
        timeText = '1 min';
      } else if (minutes % 0.5 == 0 || (minutes * 2).round() / 2 == minutes) {
        // Handle half minutes (1.5, 2.5, etc.)
        final roundedMinutes = (minutes * 2).round() / 2;
        if (roundedMinutes == roundedMinutes.toInt()) {
          timeText = '${roundedMinutes.toInt()} min';
        } else {
          timeText = '${roundedMinutes.toStringAsFixed(1)} min';
        }
      } else {
        // Round up to nearest half minute
        final roundedMinutes = (minutes * 2).ceil() / 2;
        if (roundedMinutes == roundedMinutes.toInt()) {
          timeText = '${roundedMinutes.toInt()} min';
        } else {
          timeText = '${roundedMinutes.toStringAsFixed(1)} min';
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        timeText,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTrailingWidget(
      Map<String, dynamic> reading, bool isPlaying, bool isEditMode) {
    // Calculate estimated reading time (average 200 words per minute)
    final content = reading['content'] ?? '';
    final wordCount =
        content.split(' ').where((String word) => word.isNotEmpty).length;

    // Calculate time in seconds, then format appropriately
    final totalSeconds = ((wordCount / 200) * 60).ceil();

    String timeText;
    if (totalSeconds < 60) {
      timeText = '$totalSeconds Secs';
    } else {
      final minutes = totalSeconds / 60;
      if (minutes <= 1.0) {
        timeText = '1 min';
      } else if (minutes % 0.5 == 0 || (minutes * 2).round() / 2 == minutes) {
        // Handle half minutes (1.5, 2.5, etc.)
        final roundedMinutes = (minutes * 2).round() / 2;
        if (roundedMinutes == roundedMinutes.toInt()) {
          timeText = '${roundedMinutes.toInt()} min';
        } else {
          timeText = '${roundedMinutes.toStringAsFixed(1)} min';
        }
      } else {
        // Round up to nearest half minute
        final roundedMinutes = (minutes * 2).ceil() / 2;
        if (roundedMinutes == roundedMinutes.toInt()) {
          timeText = '${roundedMinutes.toInt()} min';
        } else {
          timeText = '${roundedMinutes.toStringAsFixed(1)} min';
        }
      }
    }

    final isProtected = reading['protected'] ?? false;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show enhanced playing indicator when active
        if (isPlaying) _buildAnimatedPlayingIndicator(),

        // Show reading duration
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            timeText,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Show protected icon ONLY in edit mode
        if (isProtected && isEditMode)
          Icon(
            Icons.lock,
            color: Colors.grey[500],
            size: 16,
          ),
      ],
    );
  }

  Widget _buildAnimatedPlayingIndicator() {
    try {
      return Container(
        width: 30,
        height: 24,
        margin: const EdgeInsets.only(right: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing speaker icon only (removed animated equalizer)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                if (!mounted) return const SizedBox.shrink();
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: const Icon(
                    Icons.volume_up,
                    color: Colors.blue,
                    size: 18,
                  ),
                );
              },
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error in animated indicator: $e');
      // Fallback to static indicator
      return Container(
        width: 30,
        height: 24,
        margin: const EdgeInsets.only(right: 12),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.volume_up,
              color: Colors.blue,
              size: 18,
            ),
          ],
        ),
      );
    }
  }
}
