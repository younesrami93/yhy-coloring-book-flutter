import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme.dart';

class GenerationLoadingDialog extends StatefulWidget {
  const GenerationLoadingDialog({super.key});

  @override
  State<GenerationLoadingDialog> createState() => _GenerationLoadingDialogState();
}

class _GenerationLoadingDialogState extends State<GenerationLoadingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true); // Pulse animation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false, // Prevent dismissing by tapping outside or back button
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppTheme.electricBlue.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- ANIMATED ICON ---
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_controller.value * 0.2), // Scales 1.0 -> 1.2
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.electricBlue.withOpacity(0.5),
                            blurRadius: 20 * _controller.value, // Glowing pulse
                            spreadRadius: 2 * _controller.value,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(FontAwesomeIcons.wandMagicSparkles,
                            color: Colors.white, size: 32),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // --- TEXT ---
              Text(
                "We are working our magic...",
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Uploading your image and applying the style. Please wait.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // --- LINEAR PROGRESS ---
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const LinearProgressIndicator(
                  minHeight: 6,
                  backgroundColor: Color(0xFFE0E0E0),
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.electricBlue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}