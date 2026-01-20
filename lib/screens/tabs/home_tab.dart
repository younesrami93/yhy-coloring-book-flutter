import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yhy_coloring_book_flutter/widgets/result_screen.dart';

import '../../models/style_model.dart';
import '../../providers/styles_provider.dart';
import '../../theme.dart';
import '../../widgets/style_selector.dart';

// --- LOCAL STATE PROVIDERS ---
// Stores the ID of the selected style (int because your DB uses ints)
final selectedStyleProvider = StateProvider<int?>((ref) => null);

// Stores if an image is "picked" (Mocking file selection for now)
final hasImageProvider = StateProvider<bool>((ref) => false);

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // 1. Watch Local State
    final selectedStyleId = ref.watch(selectedStyleProvider);
    final hasImage = ref.watch(hasImageProvider);

    // 2. Watch API Data (The list of styles)
    final stylesAsyncValue = ref.watch(stylesProvider);

    // 3. Check if ready to generate
    final bool isReady = hasImage && selectedStyleId != null;

    return Stack(
      children: [
        // --- SCROLLABLE CONTENT ---
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          // Add padding at bottom so content isn't hidden behind the floating button
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // A. Header Text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "Create Coloring Page",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "Choose a photo and a style to begin.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // B. Image Picker Area
              GestureDetector(
                onTap: () {
                  // Toggle state for demo purposes
                  ref.read(hasImageProvider.notifier).state = !hasImage;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: hasImage ? 350 : 250, // Grows when image is there
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      // Highlight border if waiting for image
                      color: hasImage
                          ? Colors.transparent
                          : theme.colorScheme.primary.withOpacity(0.3),
                      width: 2,
                    ),
                    image: hasImage
                        ? const DecorationImage(
                      // Dummy image for demo
                      image: NetworkImage("https://picsum.photos/id/237/800/800"),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: hasImage
                      ? Stack(
                    children: [
                      Positioned(
                        top: 16,
                        right: 16,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              ref.read(hasImageProvider.notifier).state = false;
                            },
                          ),
                        ),
                      )
                    ],
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FontAwesomeIcons.image,
                        size: 48,
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Tap to upload photo",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // C. Style Section Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Icon(
                        FontAwesomeIcons.paintbrush,
                        size: 16,
                        color: theme.colorScheme.primary
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "CHOOSE STYLE",
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // D. Style Selector (Async Data)
              stylesAsyncValue.when(
                data: (styles) {
                  return StyleSelector(
                    styles: styles,
                    selectedStyleId: selectedStyleId,
                    onStyleSelected: (id) {
                      ref.read(selectedStyleProvider.notifier).state = id;
                    },
                  );
                },
                loading: () => const SizedBox(
                    height: 140,
                    child: Center(child: CircularProgressIndicator())
                ),
                error: (error, stack) => SizedBox(
                  height: 140,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text("Could not load styles", style: theme.textTheme.bodySmall),
                        TextButton(
                          onPressed: () => ref.refresh(stylesProvider),
                          child: const Text("Retry"),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- FLOATING ACTION BUTTON (ANIMATED) ---
        Positioned(
          left: 24,
          right: 24,
          bottom: 24, // Sits just above the bottom nav (if extended body) or inside body
          child: AnimatedSlide(
            // If ready, slide to 0 (visible). If not, slide down by 2.0 (hidden).
            offset: isReady ? const Offset(0, 0) : const Offset(0, 2),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack, // Nice bounce effect
            child: AnimatedOpacity(
              opacity: isReady ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.electricBlue.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: isReady ? () => _handleGenerate(context) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, // Transparent so gradient shows
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FontAwesomeIcons.wandMagicSparkles, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Text(
                        "Generate Magic",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleGenerate(BuildContext context) async {
    // 1. Show a loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Processing image..."),
        duration: Duration(seconds: 1),
      ),
    );

    // 2. Simulate Network Delay
    await Future.delayed(const Duration(seconds: 1));

    if (context.mounted) {
      // 3. Navigate to Result Screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ResultScreen()),
      );
    }
  }
}