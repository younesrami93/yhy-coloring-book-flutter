import 'package:app/api/api_service.dart';
import 'package:app/providers/generations_provider.dart';
import 'package:app/screens/home_screen.dart';
import 'package:app/widgets/generation_detail_dialog.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart'; // To access navigatorKey
import '../core/app_state.dart'; // To access bottomNavProvider
import 'auth_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Import this

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final Ref ref;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

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
        await _apiService.syncDeviceToken(token);
      }

      // 3. Listen for token refreshes
      _fcm.onTokenRefresh.listen(_apiService.syncDeviceToken);

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

      final data = message.data;
      final String? type = data['type']; // Make sure your backend sends 'type'
      if (type == 'promo' || type == 'system') {
        _showLocalNotification(message);
        return;
      }
      if (type == 'generation_completed') {
        _handleInAppGenerationEvent(message, isSuccess: true);
        return;
      }

      // CASE 3: GENERATION FAILED
      if (type == 'generation_failed') {
        _handleInAppGenerationEvent(message, isSuccess: false);
        return;
      }

      _showLocalNotification(message);

      // Optional: Show a custom snackbar/toast here
    });
  }

  /// -------------------------------------------------------------
  /// HANDLER 1: Standard Notification (Promos)
  /// -------------------------------------------------------------
  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: message.data['generation_id'],
      );
    }
  }

  /// -------------------------------------------------------------
  /// HANDLER 2: In-App Experience (Generations)
  /// -------------------------------------------------------------


  // 1. Rename and modify the private handler to just parse data
  void _handleInAppGenerationEvent(RemoteMessage message, {required bool isSuccess}) {

    final int currentIndex = ref.read(bottomNavIndexProvider);

    if (currentIndex == 1) {
      debugPrint("User is on History tab. Auto-refreshing list...");
      ref.read(generationsProvider.notifier).refresh();
    } else {
      debugPrint("User is on tab $currentIndex. Ignoring auto-refresh.");
    }


    final generationId = message.data['generation_id'];
    // Call the new public method
    showStatusSnackBar(
        id: generationId?.toString(),
        isSuccess: isSuccess
    );
  }

  // 2. Create this NEW Public Method (Paste your styled SnackBar code here)
  void showStatusSnackBar({required String? id, required bool isSuccess}) {
    final Color bgColor = isSuccess ? const Color(0xFF00C853) : const Color(0xFFE53935);
    final IconData icon = isSuccess ? Icons.check_circle_outline : Icons.error_outline;

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        elevation: 6,
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSuccess ? "Ready!" : "Failed",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                  ),
                  Text(
                    isSuccess ? "Your image is ready." : "Credits refunded.",
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSuccess)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () {
                      scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
                      // Open the modal directly with your test ID
                      if (id != null) _openGenerationModal(id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: bgColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text("VIEW", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ),
              ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
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

  void _openGenerationModal(String idstr) {
    final int? id = int.tryParse(idstr);
    if (id == null) return;

    // 1. Force Navigate to History Tab
    // We assume 'bottomNavIndexProvider' controls your Home tabs
    ref.read(bottomNavIndexProvider.notifier).state = 1;

    // 2. Ensure we are on the HomeScreen (if user was deep in settings)
    navigatorKey.currentState?.popUntil((route) => route.isFirst);

    // 3. Show the Dialog
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => GenerationDetailDialog(generationId: id),
    );
  }
}

// Provider for the service
final notificationServiceProvider = Provider((ref) => NotificationService(ref));
