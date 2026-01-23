import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yhy_coloring_book_flutter/screens/login_screen.dart';
import 'package:yhy_coloring_book_flutter/widgets/generation_error_dialog.dart';
import 'package:yhy_coloring_book_flutter/widgets/generation_loading_dialog.dart';
import 'package:yhy_coloring_book_flutter/widgets/insufficient_credits_dialog.dart';
import 'package:yhy_coloring_book_flutter/widgets/purchase_credits_dialog.dart';

import '../../models/style_model.dart';
import '../../providers/styles_provider.dart';
import '../../theme.dart';
import '../../widgets/style_selector.dart';
import '../../core/auth_provider.dart';
import '../../widgets/generation_success_dialog.dart'; // <--- Import New Widget

final selectedStyleProvider = StateProvider<int?>((ref) => null);
final selectedImageProvider = StateProvider<File?>((ref) => null);

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  Future<void> _pickImage(WidgetRef ref, ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
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
    // ... [Use the exact same UI build code as before. No changes needed here] ...
    // For brevity, I am not pasting the UI scaffold again, just the Logic below.
    // If you need the full UI code again, let me know, but it is unchanged.

    // Copy/Paste your existing build method here.
    final theme = Theme.of(context);
    final selectedStyleId = ref.watch(selectedStyleProvider);
    final selectedImage = ref.watch(selectedImageProvider);
    final stylesAsyncValue = ref.watch(stylesProvider);

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
              // Header
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

              // Image Picker
              GestureDetector(
                onTap: () => _showImageSourceModal(context, ref),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: selectedImage != null ? 350 : 250,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.5),
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
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    ref
                                            .read(
                                              selectedImageProvider.notifier,
                                            )
                                            .state =
                                        null;
                                  },
                                ),
                              ),
                            ),
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

              // Style Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.paintbrush,
                      size: 16,
                      color: theme.colorScheme.primary,
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

              // Style Selector
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
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => SizedBox(
                  height: 140,
                  child: Center(
                    child: Text(
                      "Could not load styles",
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // FAB
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
                  onPressed: isReady
                      ? () => _handleGenerate(context, ref)
                      : null,
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
                      Icon(
                        FontAwesomeIcons.wandMagicSparkles,
                        color: Colors.white,
                        size: 20,
                      ),
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

  void _showImageSourceModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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

  // --- UPDATED GENERATION LOGIC ---

  Future<void> _handleGenerate(BuildContext context, WidgetRef ref) async {
    final selectedStyleId = ref.read(selectedStyleProvider);
    final selectedImage = ref.read(selectedImageProvider);
    final client = ref.read(apiClientProvider);

    if (selectedStyleId == null || selectedImage == null) return;

    final oldCredits = ref.read(authProvider)?.credits ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const GenerationLoadingDialog(),
    );

    try {
      final response = await client.postMultipart(
        'generate',
        file: selectedImage,
        fileField: 'image',
        fields: {'style_id': selectedStyleId.toString()},
      );

      if (context.mounted) Navigator.pop(context); // Close loading

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final remainingCredits = data['remaining_credits'];

        if (remainingCredits != null && remainingCredits is int) {
          ref.read(authProvider.notifier).updateCredits(remainingCredits);
        }

        ref.read(selectedImageProvider.notifier).state = null;
        ref.read(selectedStyleProvider.notifier).state = null;

        if (context.mounted) {
          showDialog(
            context: context,
            barrierColor: Colors.black.withOpacity(0.6),
            builder: (_) => GenerationSuccessDialog(
              oldCredits: oldCredits,
              newCredits: remainingCredits ?? (oldCredits - 1),
            ),
          );
        }
      } else if (response.statusCode == 402) {
        // --- INSUFFICIENT CREDITS LOGIC ---
        final msg =
            jsonDecode(response.body)['message'] ??
            "You don't have enough credits.";
        ref.read(authProvider.notifier).refreshUser();

        if (context.mounted) {
          showDialog(
            context: context,
            builder: (_) => InsufficientCreditsDialog(
              message: msg,
              onTopUp: () {
                // 1. Check if user is Guest
                final user = ref.read(authProvider);
                // We assume guest has no email or specific name/id pattern.
                // Adjust this check based on your actual backend user model.
                final isGuest = user?.email.isEmpty ?? true;

                if (isGuest) {
                  // A. Set the "Purchase Intent" flag
                  ref.read(purchaseIntentProvider.notifier).state = true;

                  // B. Redirect to Login
                  // We use push() so the Guest session is still in the stack if they hit back,
                  // but typically LoginScreen replaces everything on success.
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                } else {
                  // C. Real User -> Show Store directly
                  showDialog(
                    context: context,
                    builder: (_) => const PurchaseCreditsDialog(),
                  );
                }
              },
            ),
          );
        }
      } else {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (_) => GenerationErrorDialog(
              message: "Server returned error: ${response.statusCode}",
              onRetry: () => _handleGenerate(context, ref),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (_) => GenerationErrorDialog(
            message: "Connection failed.\n($e)",
            onRetry: () => _handleGenerate(context, ref),
          ),
        );
      }
    }
  }
}
