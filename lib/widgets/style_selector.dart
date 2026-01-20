import 'package:flutter/material.dart';
import '../models/style_model.dart';
import '../theme.dart';

class StyleSelector extends StatelessWidget {
  final List<StyleModel> styles;
  final int? selectedStyleId;
  final Function(int) onStyleSelected;

  const StyleSelector({
    super.key,
    required this.styles,
    required this.selectedStyleId,
    required this.onStyleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: styles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final style = styles[index];
          final isSelected = style.id == selectedStyleId;
          final theme = Theme.of(context);

          return GestureDetector(
            onTap: () => onStyleSelected(style.id),
            child: Column(
              children: [
                // THUMBNAIL IMAGE
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),

                    // --- BORDER LOGIC UPDATED ---
                    border: isSelected
                        ? Border.all(color: AppTheme.electricBlue, width: 3)
                        : Border.all(
                      // Subtle grey border for unselected items
                      color: theme.colorScheme.outline.withOpacity(0.2),
                      width: 1.5,
                    ),

                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppTheme.electricBlue.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                    ],
                    image: DecorationImage(
                      image: NetworkImage(style.thumbnailUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Checkmark Overlay (Only when selected)
                  child: isSelected
                      ? Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Center(
                      child: Icon(Icons.check, color: Colors.white, size: 30),
                    ),
                  )
                      : null,
                ),
                const SizedBox(height: 8),
                // STYLE TITLE
                Text(
                  style.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? AppTheme.electricBlue
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}