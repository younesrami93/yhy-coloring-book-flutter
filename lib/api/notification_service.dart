import 'package:app/screens/home_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart'; // To access navigatorKey
import '../core/app_state.dart'; // To access bottomNavProvider
import 'auth_service.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final AuthService _authService = AuthService();
  final Ref ref;

  NotificationService(this.ref);

  Future<void> init() async {
    // 1. Request Permissions (iOS/Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Get and Sync Token
      String? token = await _fcm.getToken();
      if (token != null) {
        await _authService.syncDeviceToken(token);
      }

      // 3. Listen for token refreshes
      _fcm.onTokenRefresh.listen(_authService.syncDeviceToken);

      // 4. Set Foreground Options (iOS)
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 5. Setup Interaction Listeners
      _setupInteractions();
    }
  }

  void _setupInteractions() {
    // A. App is TERMINATED: Notification clicked to open app
    _fcm.getInitialMessage().then((message) {
      if (message != null) _handleMessageClick(message);
    });

    // B. App is in BACKGROUND: Notification clicked from tray
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageClick);

    // C. App is in FOREGROUND: Message received while using app
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint("Foreground notification received: ${message.data}");
      // Optional: Show a custom snackbar/toast here
    });
  }

  void _handleMessageClick(RemoteMessage message) {
    final String? generationId = message.data['generation_id'];
    if (generationId != null) {
      // 1. Navigate to Home
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
      );

      // 2. Switch to History Tab (Index 1)
      ref.read(bottomNavIndexProvider.notifier).state = 1;

      // 3. Post-frame callback ensures the UI is ready before showing modal
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // You will implement this in your HomeScreen or as a global dialog
        _openGenerationModal(generationId);
      });
    }
  }

  void _openGenerationModal(String id) {
    // Logic to fetch generation and show dialog
    debugPrint("Opening modal for generation: $id");
  }
}

// Provider for the service
final notificationServiceProvider = Provider((ref) => NotificationService(ref));
