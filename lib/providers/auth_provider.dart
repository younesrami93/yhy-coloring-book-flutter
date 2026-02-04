import 'package:app/api/api_client.dart';
import 'package:app/api/api_service.dart';
import 'package:app/core/ApiException.dart';
import 'package:app/models/User.dart';
import 'package:app/services/purchase_service.dart';
import 'package:app/services/notification_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

// Providers for dependencies
final apiServiceClientProvider = Provider((ref) => ApiClient());
final apiServiceProvider = Provider((ref) => ApiService());
final authServiceProvider = Provider((ref) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier(
    ref.watch(apiServiceProvider),
    ref.watch(authServiceProvider),
    ref.watch(notificationServiceProvider),
  );
});

class AuthNotifier extends StateNotifier<User?> {
  final ApiService _apiService;
  final AuthService _authService;
  final NotificationService _notificationService;

  AuthNotifier(this._apiService, this._authService, this._notificationService)
    : super(null);

  /// 1. Google Login Flow
  Future<void> loginWithGoogle() async {
    // Changed return type to Future<void> - we rely on exceptions for failure
    final creds = await _authService.getGoogleCredentials();

    if (creds?.idToken != null) {
      // If authenticate fails, it throws ApiException.
      // We let it propagate to the UI.
      final user = await _apiService.authenticate(
        provider: 'google',
        socialToken: creds!.idToken,
        socialAccessToken: creds.accessToken,
      );

      if (user != null) {
        await _finalizeLogin(user);
      } else {
        throw ApiException(
          "Login failed",
        ); // Fallback if user is null but no error thrown
      }
    } else {
      throw ApiException("Google sign-in cancelled");
    }
  }

  /// 2. Facebook Login Flow
  Future<bool> loginWithFacebook() async {
    final fbToken = await _authService.getFacebookToken();
    if (fbToken != null) {
      final user = await _apiService.authenticate(
        provider: 'facebook',
        socialToken: fbToken,
      );
      return _finalizeLogin(user);
    }
    return false;
  }

  /// 3. Guest Login Flow
  Future<bool> loginGuest() async {
    final user = await _apiService.authenticate();
    return _finalizeLogin(user);
  }

  /// 4. Startup Check: Restore Session from Token
  Future<bool> checkLoginStatus() async {
    final token = await _apiService.getToken();
    if (token != null && token.isNotEmpty) {
      final user = await _apiService.getUserData();
      if (user != null) {
        state = user;
        _notificationService
            .init(); // Re-sync notification listeners on startup
        return true;
      }
    }
    state = null;
    return false;
  }

  /// 5. Post-Login Orchestration
  Future<bool> _finalizeLogin(User? user) async {
    if (user != null) {
      state = user;
      // All side effects are now centralized here
      await PurchaseService.identifyUser(user.id.toString());
      await _notificationService.init();
      return true;
    }
    return false;
  }

  /// 6. Utility Methods
  Future<void> refreshUser() async {
    if (state == null) return;
    final updatedUser = await _apiService.getUserData();
    if (updatedUser != null) {
      state = updatedUser;
    }
  }

  void updateCredits(int newCredits) {
    if (state != null) {
      state = state!.copyWith(credits: newCredits);
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logoutSDKs();
    } catch (e) {}
    try {
      await PurchaseService.logout();
    } catch (e) {}
    try {
      await _apiService
          .clearToken(); // Centralized token clearing in ApiService
    } catch (e) {}
    state = null;
  }
}
