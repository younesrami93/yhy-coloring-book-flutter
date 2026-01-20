import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SleekBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const SleekBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Glassmorphism Wrapper
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // The Blur Effect
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          // Transparent color is required for the blur to show through
          color: theme.scaffoldBackgroundColor.withOpacity(0.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(context, 0, FontAwesomeIcons.house, "Home"),
              _buildNavItem(context, 1, FontAwesomeIcons.clockRotateLeft, "History"),
              _buildNavItem(context, 2, FontAwesomeIcons.gear, "Settings"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final bool isSelected = currentIndex == index;
    final theme = Theme.of(context);

    final Color selectedColor = theme.colorScheme.primary;
    final Color unselectedColor = theme.colorScheme.onSurfaceVariant.withOpacity(0.6);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 20 : 12,
            vertical: 10
        ),
        decoration: isSelected
            ? BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        )
            : null,
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? selectedColor : unselectedColor,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selectedColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}