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
    // 1. Artificial delay (optional)
    await Future.delayed(const Duration(seconds: 2));

    final authNotifier = ref.read(authProvider.notifier);

    // 2. Check for existing token
    bool isLoggedIn = await authNotifier.checkLoginStatus();

    // 3. If NOT logged in, try to sign in as guest automatically
    if (!isLoggedIn) {
      try {
        isLoggedIn = await authNotifier.loginGuest();
      } catch (e) {
        // Handle specific errors if needed, otherwise isLoggedIn remains false
        debugPrint("Auto-guest login failed: $e");
      }
    }

    if (!mounted) return;

    // 4. Navigate
    if (isLoggedIn) {
      // Success: Go straight to Home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      // Failure (e.g., No Internet):
      // Fallback to LoginScreen so the user isn't stuck on the Splash screen
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
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            // Optional: Show text indicating what's happening
            Text(
              "Setting things up...",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}