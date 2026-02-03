import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:app/providers/auth_provider.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/screens/home_screen.dart';
import 'package:app/theme.dart';

// We'll use this provider to manage the loading state of the login action
final authLoadingProvider = StateProvider<bool>((ref) => false);

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authLoadingProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // --- Header Section ---
              Icon(
                Icons.color_lens_outlined,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.appTitle, // "Coloring AI"
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Turn your photos into coloring pages instantly.",
                // You can add this to .arb later
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),

              const Spacer(),

              // --- Social Login Buttons ---
              _SocialLoginButton(
                icon: FontAwesomeIcons.google,
                text: "Continue with Google",
                onPressed: () async {
                  ref.read(authLoadingProvider.notifier).state = true;

                  // This now calls the backend-integrated method
                  final success = await ref
                      .read(authProvider.notifier)
                      .loginWithGoogle();

                  ref.read(authLoadingProvider.notifier).state = false;

                  if (success && context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Google Login Failed")),
                    );
                  }
                },
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                textColor: theme.colorScheme.onSurface,
              ),
              const SizedBox(height: 16),

              _SocialLoginButton(
                icon: FontAwesomeIcons.facebook,
                text: "Continue with Facebook",
                onPressed: () async {
                  ref.read(authLoadingProvider.notifier).state = true;

                  final success = await ref
                      .read(authProvider.notifier)
                      .loginWithFacebook();

                  ref.read(authLoadingProvider.notifier).state = false;

                  if (success && context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Facebook Login Failed")),
                    );
                  }
                },
                backgroundColor: AppTheme.facebookBlue,
                // Facebook Blue
                textColor: Colors.white,
              ),

              const SizedBox(height: 32),

              // --- Divider ---
              /*Row(
                children: [
                  Expanded(child: Divider(color: theme.dividerColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text("OR", style: theme.textTheme.bodySmall),
                  ),
                  Expanded(child: Divider(color: theme.dividerColor)),
                ],
              ),

              const SizedBox(height: 32),

              // --- Guest Button (Primary Action for now) ---
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: isLoading ? null : () async {
                    ref.read(authLoadingProvider.notifier).state = true; // Start loading spinner

                    // Call the Provider
                    final success = await ref.read(authProvider.notifier).loginGuest();

                    ref.read(authLoadingProvider.notifier).state = false; // Stop loading spinner

                    if (success && context.mounted) {
                      // Navigate to Home
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen())
                      );
                    } else {
                      // Show Error Snack bar
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Login Failed. Please check internet.")),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                  )
                      : Text(
                    l10n.guestLogin,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),*/
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper Widget for consistent Social Buttons
class _SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;

  const _SocialLoginButton({
    required this.icon,
    required this.text,
    required this.onPressed,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: FaIcon(icon, color: textColor, size: 20),
        label: Text(text, style: TextStyle(color: textColor, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          alignment: Alignment.center, // Centers text and icon
        ),
      ),
    );
  }
}
