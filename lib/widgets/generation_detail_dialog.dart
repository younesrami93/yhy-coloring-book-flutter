import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/generation_model.dart';
import '../providers/generations_provider.dart';
import '../screens/image_viewer_screen.dart';
import 'before_after_card.dart';

class GenerationDetailDialog extends ConsumerStatefulWidget {
  final int generationId;

  const GenerationDetailDialog({super.key, required this.generationId});

  @override
  ConsumerState<GenerationDetailDialog> createState() => _GenerationDetailDialogState();
}

class _GenerationDetailDialogState extends ConsumerState<GenerationDetailDialog> {
  Generation? _generation;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final gen = await ref
          .read(generationsProvider.notifier)
          .fetchGeneration(widget.generationId);

      if (mounted) {
        setState(() {
          _generation = gen;
          _isLoading = false;
          if (gen == null) _error = "Generation not found";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "Connection error";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: theme.colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Hug content height
          children: [
            // --- 1. Minimal Header ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Generation Completed",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Small Circular Close Button
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- 2. Body (Image) ---
            Flexible(
              child: _buildBody(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _generation == null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            _error ?? "Unable to load",
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Success State
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The Card (Details are already inside here)
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 450),
            width: double.infinity,
            child: BeforeAfterCard(generation: _generation!),
          ),
        ),

        const SizedBox(height: 20),

        // --- 3. Full Screen Action ---
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ImageViewerScreen(generation: _generation!),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const FaIcon(FontAwesomeIcons.expand, size: 16),
            label: const Text(
              "Full Screen",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}