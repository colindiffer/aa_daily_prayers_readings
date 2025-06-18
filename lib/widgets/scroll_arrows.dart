import 'package:flutter/material.dart';

class ScrollArrows extends StatelessWidget {
  final bool showUpArrow;
  final bool showDownArrow;
  final VoidCallback onUp;
  final VoidCallback onDown;

  const ScrollArrows({
    super.key,
    required this.showUpArrow,
    required this.showDownArrow,
    required this.onUp,
    required this.onDown,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showUpArrow)
          GestureDetector(
            onTap: onUp,
            child: Container(
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withAlpha(128),
              ),
              padding: const EdgeInsets.all(8.0),
              child: const Icon(Icons.arrow_upward, color: Colors.white, size: 32),
            ),
          ),
        if (showDownArrow)
          GestureDetector(
            onTap: onDown,
            child: Container(
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withAlpha(128),
              ),
              padding: const EdgeInsets.all(8.0),
              child: const Icon(Icons.arrow_downward, color: Colors.white, size: 32),
            ),
          ),
      ],
    );
  }
}
