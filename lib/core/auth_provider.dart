import 'package:app/api/api_client.dart';
import 'package:app/api/api_service.dart';
import 'package:app/models/User.dart';
import 'package:app/services/purchase_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final purchaseIntentProvider = StateProvider<bool>((ref) => false);

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier();
});

final _authService = AuthService();
final _apiService = ApiService();
final _apiClient = ApiClient();
final FirebaseMessaging _fcm = FirebaseMessaging.instance;

Future<void> _syncFCMToken() async {
  try {
    // 1. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Get FCM Token
      String? fcmToken = await _fcm.getToken();
      debugPrint("_syncFCMToken " + fcmToken!);

      if (fcmToken != null) {
        // 3. Sync with Backend
        await _apiService.syncDeviceToken(fcmToken);
      }
    } else {
      debugPrint("_syncFCMToken authorizationStatus not authorized");
    }

    // 4. Listen for token refreshes
    _fcm.onTokenRefresh.listen((newToken) {
      _apiService.syncDeviceToken(newToken);
    });
  } catch (e) {
    debugPrint("Notification Init Error: $e");
  }
}

class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier() : super(null);
  final _apiService = ApiService(); // Add this
  final _authService = AuthService();

  Future<bool> loginWithGoogle() async {
    final user = await _authService.loginWithGoogle();
    if (user != null) {
      state = user;
      await PurchaseService.identifyUser(user.id.toString());
      await _syncFCMToken();
      return true;
    }
    return false;
  }

  Future<bool> loginWithFacebook() async {
    final user = await _authService.loginWithFacebook();
    if (user != null) {
      state = user;
      await PurchaseService.identifyUser(user.id.toString());
      await _syncFCMToken();
      return true;
    }
    return false;
  }

  /// Checks if a token exists in local storage
  Future<bool> checkLoginStatus() async {
    final token = await _apiClient.getToken();

    if (token != null && token.isNotEmpty) {
      // We found a token! Restore a basic user session.
      // (In a real app, you would verify this token with the API here)
      state = User(
        id: 0,
        name: "Welcome Back",
        email: "",
        credits: 0,
        token: token,
      );

      _syncFCMToken();
      return true; // Logged in
    }

    state = null;
    return false; // Not logged in
  }

  Future<void> refreshUser() async {
    if (state == null) return; // Don't refresh if not logged in

    final updatedUser = await _apiService.getUserData();
    if (updatedUser != null) {
      state = updatedUser as User?; // This triggers the UI update automatically
    }
  }

  Future<bool> loginGuest() async {
    final user = await _apiService.authenticate();
    ;
    if (user != null) {
      state = user;
      await PurchaseService.identifyUser(user.id.toString());
      await _syncFCMToken();
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
    await PurchaseService.logout(); // Reset RevenueCat
    state = null;
  }
}
