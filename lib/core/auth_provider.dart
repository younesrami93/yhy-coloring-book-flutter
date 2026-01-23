import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/auth_service.dart';
import '../models/user_model.dart';


final purchaseIntentProvider = StateProvider<bool>((ref) => false);

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier();
});




class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier() : super(null);

  final _authService = AuthService();



  Future<bool> loginWithGoogle() async {
    final user = await _authService.loginWithGoogle();
    if (user != null) {
      state = user;
      return true;
    }
    return false;
  }

  Future<bool> loginWithFacebook() async {
    final user = await _authService.loginWithFacebook();
    if (user != null) {
      state = user;
      return true;
    }
    return false;
  }

  /// Checks if a token exists in local storage
  Future<bool> checkLoginStatus() async {
    final token = await _authService.getToken();

    if (token != null && token.isNotEmpty) {
      // We found a token! Restore a basic user session.
      // (In a real app, you would verify this token with the API here)
      state = User(
          id: "cached-id",
          name: "Welcome Back",
          email: "",
          credits: 0,
          token: token
      );
      return true; // Logged in
    }

    state = null;
    return false; // Not logged in
  }

  Future<void> refreshUser() async {
    if (state == null) return; // Don't refresh if not logged in

    final updatedUser = await _authService.getUserData();
    if (updatedUser != null) {
      state = updatedUser; // This triggers the UI update automatically
    }
  }



  Future<bool> loginGuest() async {
    final user = await _authService.loginAsGuest();
    if (user != null) {
      state = user;
      return true;
    }
    return false;
  }

  void updateCredits(int newCredits) {
    if (state != null) {
      state = state!.copyWith(credits: newCredits);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = null;
  }
}