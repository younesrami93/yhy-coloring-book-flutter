import 'dart:convert';
import 'dart:io'; // Required for File
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart'; // Required for picking images

import '../../models/style_model.dart';
import '../../providers/styles_provider.dart';
import '../../theme.dart';
import '../../widgets/style_selector.dart';

// --- LOCAL STATE PROVIDERS ---
final selectedStyleProvider = StateProvider<int?>((ref) => null);

// Changed to hold the actual File object instead of a boolean
final selectedImageProvider = StateProvider<File?>((ref) => null);

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  // Helper method to pick image
  Future<void> _pickImage(WidgetRef ref, ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024, // Resize for performance
        imageQuality: 85,
      );

      if (pickedFile != null) {
        ref.read(selectedImageProvider.notifier).state = File(pickedFile.path);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedStyleId = ref.watch(selectedStyleProvider);
    final selectedImage = ref.watch(selectedImageProvider);
    final stylesAsyncValue = ref.watch(stylesProvider);

    // Ready if we have both an image and a style
    final bool isReady = selectedImage != null && selectedStyleId != null;

    return Stack(
      children: [
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
                onTap: () => _showImageSourceModal(context, ref),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: selectedImage != null ? 350 : 250,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: selectedImage != null
                          ? Colors.transparent
                          : theme.colorScheme.primary.withOpacity(0.3),
                      width: 2,
                    ),
                    image: selectedImage != null
                        ? DecorationImage(
                      image: FileImage(selectedImage),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: selectedImage != null
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
                              ref.read(selectedImageProvider.notifier).state = null;
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

              // C. Style Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Icon(FontAwesomeIcons.paintbrush,
                        size: 16, color: theme.colorScheme.primary),
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

              // D. Style Selector
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
                    height: 140, child: Center(child: CircularProgressIndicator())),
                error: (error, stack) => SizedBox(
                  height: 140,
                  child: Center(
                    child: Text("Could not load styles",
                        style: theme.textTheme.bodySmall),
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- FLOATING ACTION BUTTON ---
        Positioned(
          left: 24,
          right: 24,
          bottom: 24,
          child: AnimatedSlide(
            offset: isReady ? const Offset(0, 0) : const Offset(0, 2),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
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
                  onPressed: isReady ? () => _handleGenerate(context, ref) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FontAwesomeIcons.wandMagicSparkles,
                          color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Text(
                        "Generate Magic",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
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

  // Helper to choose Camera or Gallery
  void _showImageSourceModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ref, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ref, ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGenerate(BuildContext context, WidgetRef ref) async {
    final selectedStyleId = ref.read(selectedStyleProvider);
    final selectedImage = ref.read(selectedImageProvider);
    final client = ref.read(apiClientProvider);

    if (selectedStyleId == null || selectedImage == null) return;

    // 1. Show Loading Indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2. Call the API
      final response = await client.postMultipart(
        'generate',
        file: selectedImage,
        fileField: 'image',
        fields: {
          'style_id': selectedStyleId.toString(),
          // 'prompt': 'optional custom prompt here',
        },
      );

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // 3. SUCCESS
        // Clear state if desired
        ref.read(selectedImageProvider.notifier).state = null;
        ref.read(selectedStyleProvider.notifier).state = null;

        if (context.mounted) {
          _showSuccessDialog(context);
        }
      } else if (response.statusCode == 402) {
        // 4. Insufficient Credits
        final msg = jsonDecode(response.body)['message'] ?? "Insufficient credits";
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            action: SnackBarAction(label: "Buy", onPressed: () {}),
          ));
        }
      } else {
        // 5. Other Error
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error: ${response.statusCode}. Please try again."),
          ));
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading if error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Connection error: $e")),
        );
      }
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text("Started!"),
          ],
        ),
        content: const Text(
          "Your image is being processed. This usually takes about 10 seconds.\n\n"
              "We'll send you a notification when it's ready!",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Awesome"),
          )
        ],
      ),
    );
  }
}