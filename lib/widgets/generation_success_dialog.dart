import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme.dart';

class GenerationSuccessDialog extends StatefulWidget {
  final int oldCredits;
  final int newCredits;

  const GenerationSuccessDialog({
    super.key,
    required this.oldCredits,
    required this.newCredits,
  });

  @override
  State<GenerationSuccessDialog> createState() => _GenerationSuccessDialogState();
}

class _GenerationSuccessDialogState extends State<GenerationSuccessDialog>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _scaleAnimation;

  late AnimationController _numberController;
  late Animation<double> _numberAnimation;

  // NEW: Controller for the "Pop" effect
  late AnimationController _popController;
  late Animation<double> _popAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Main Entrance (Dialog Pop-in)
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.elasticOut,
    );

    // 2. Number Slide (Odometer)
    _numberController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _numberAnimation = CurvedAnimation(
      parent: _numberController,
      curve: Curves.easeInOutBack,
    );

    // 3. NEW: Pop Effect (Scale Up -> Down)
    _popController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Goes 1.0 -> 1.4 -> 1.0
    _popAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _popController,
      curve: Curves.easeInOut,
    ));

    _startSequence();
  }

  Future<void> _startSequence() async {
    // A. Show Dialog
    await _mainController.forward();

    if (mounted) {
      // B. Wait a beat to read "6"
      await Future.delayed(const Duration(milliseconds: 400));
    }

    if (mounted) {
      // C. Trigger Pop & Slide simultaneously
      HapticFeedback.mediumImpact();
      _popController.forward(); // Make it BIG
      _numberController.forward(); // Change the number
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _numberController.dispose();
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppTheme.electricBlue.withOpacity(0.25),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- ICON ---
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.check_rounded, color: Colors.white, size: 48),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- TEXT ---
                  Text(
                    "Magic Started!",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "We are painting your masterpiece.\nThis won't take long.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- ANIMATED CREDIT COUNTER ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withOpacity(0.05),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(FontAwesomeIcons.coins,
                            color: AppTheme.goldAccent, size: 22),
                        const SizedBox(width: 16),
                        Text(
                          "Balance:",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // NEW: Wrapped in ScaleTransition for the "POP"
                        ScaleTransition(
                          scale: _popAnimation,
                          child: SizedBox(
                            height: 32,
                            width: 44,
                            child: Stack(
                              children: [
                                // 1. The "Old" Number (Slides Up/Out)
                                AnimatedBuilder(
                                  animation: _numberAnimation,
                                  builder: (context, child) {
                                    final val = _numberAnimation.value.clamp(0.0, 1.0);
                                    return Transform.translate(
                                      offset: Offset(0, -32 * val),
                                      child: Opacity(
                                        opacity: (1.0 - val).clamp(0.0, 1.0),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "${widget.oldCredits}",
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                      height: 1.0,
                                    ),
                                  ),
                                ),

                                // 2. The "New" Number (Slides In from Bottom)
                                AnimatedBuilder(
                                  animation: _numberAnimation,
                                  builder: (context, child) {
                                    final val = _numberAnimation.value.clamp(0.0, 1.0);
                                    return Transform.translate(
                                      offset: Offset(0, 32 * (1.0 - val)),
                                      child: Opacity(
                                        opacity: val.clamp(0.0, 1.0),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "${widget.newCredits}",
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Removed the "-1 Credit" text block here

                  const SizedBox(height: 32),

                  // --- BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.electricBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text("Got it"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}