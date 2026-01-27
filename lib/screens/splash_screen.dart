// [file_path: lib/screens/splash_screen.dart]
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/auth_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // 1. Artificial delay for branding
    await Future.delayed(const Duration(seconds: 2));

    final authNotifier = ref.read(authProvider.notifier);

    // 2. Check for existing token in SharedPreferences
    bool isLoggedIn = await authNotifier.checkLoginStatus();

    if (isLoggedIn) {
      // CRITICAL: If we have a token, fetch the latest user data (Name, Email, Credits)
      // otherwise, the app thinks the name is "Welcome Back" and email is empty.
      await authNotifier.refreshUser();
    } else {
      // 3. If NO token, automatically create a Guest Session
      try {
        debugPrint("No token found. Attempting Guest Login...");
        isLoggedIn = await authNotifier.loginGuest();
      } catch (e) {
        debugPrint("Auto-guest login failed: $e");
      }
    }

    if (!mounted) return;

    // 4. Navigate based on result
    if (isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      // Only goes here if Guest Login also failed (e.g., no internet)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.color_lens_outlined,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              "Setting things up...",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}