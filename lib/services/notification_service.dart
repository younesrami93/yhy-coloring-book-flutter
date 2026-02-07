import 'package:app/api/api_service.dart';
import 'package:app/providers/generations_provider.dart';
import 'package:app/screens/home_screen.dart';
import 'package:app/widgets/generation_detail_dialog.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart'; // To access navigatorKey
import '../core/app_state.dart'; // To access bottomNavIndexProvider (renamed from bottomNavProvider)
import 'auth_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();
  final Ref ref;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  NotificationService(this.ref);

  Future<void> init() async {

    if (_isInitialized) return;
    // 1. Request Permissions (iOS/Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _isInitialized = true;
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

      // 5. Initialize Local Notifications (Android)
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle Local Notification Click
          if (response.payload != null) {
            // Reconstruct a message-like object or handle directly
            _handlePayloadClick(response.payload);
          }
        },
      );

      // 6. Setup Interaction Listeners
      _setupInteractions();
    }
  }

  void _setupInteractions() {
    // A. App is TERMINATED: Notification clicked to open app
    _fcm.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint("Application opened from Terminated state");
        _handleMessageClick(message);
      }
    });

    // B. App is in BACKGROUND: Notification clicked from tray
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint("Application opened from Background state");
      _handleMessageClick(message);
    });

    // C. App is in FOREGROUND: Message received while using app
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint("Foreground notification received: ${message.data}");

      final data = message.data;
      final String? type = data['type'];

      // CASE 1: GENERATION COMPLETED
      if (type == 'generation_completed') {
        _handleInAppGenerationEvent(message, isSuccess: true);
        return;
      }

      // CASE 2: GENERATION FAILED
      if (type == 'generation_failed') {
        _handleInAppGenerationEvent(message, isSuccess: false);
        return;
      }

      // CASE 3: PROMO / SYSTEM
      _showLocalNotification(message);
    });
  }

  /// -------------------------------------------------------------
  /// HANDLER: Deep Link Logic (Terminated / Background)
  /// -------------------------------------------------------------
  void _handleMessageClick(RemoteMessage message) {
    final String? generationId = message.data['generation_id'];
    if (generationId != null) {
      _handlePayloadClick(generationId);
    }
  }

  void _handlePayloadClick(String? generationId) {
    if (generationId == null) return;

    // 1. Navigate to Home (Resetting stack to avoid back-button issues)
    // Ensure '/home' is registered in your main.dart routes
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/home',
          (route) => false,
    );

    // 2. Switch to History Tab (Index 1)
    // We delay slightly to let the navigation settle
    Future.delayed(const Duration(milliseconds: 100), () {
      ref.read(bottomNavIndexProvider.notifier).state = 1;
    });

    // 3. Open the Modal
    // Wait for the build cycle to complete after navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _openGenerationModal(generationId);
      });
    });
  }

  void _openGenerationModal(String idstr) {
    final int? id = int.tryParse(idstr);
    if (id == null) return;

    // Use the navigatorKey context to show dialog
    final context = navigatorKey.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        builder: (context) => GenerationDetailDialog(generationId: id),
      );
    }
  }

  /// -------------------------------------------------------------
  /// HANDLER: Foreground In-App Events
  /// -------------------------------------------------------------
  void _handleInAppGenerationEvent(RemoteMessage message, {required bool isSuccess}) {
    // Auto-refresh if user is looking at History list
    final int currentIndex = ref.read(bottomNavIndexProvider);
    if (currentIndex == 1) {
      debugPrint("User is on History tab. Auto-refreshing list...");
      ref.read(generationsProvider.notifier).refresh();
    }

    final generationId = message.data['generation_id'];

    // Show the custom SnackBar
    showStatusSnackBar(
        id: generationId?.toString(),
        isSuccess: isSuccess
    );
  }

  /// -------------------------------------------------------------
  /// UI: Local Notification (System Tray)
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
        payload: message.data['generation_id'], // Pass ID to payload for click handling
      );
    }
  }

  /// -------------------------------------------------------------
  /// UI: Custom SnackBar
  /// -------------------------------------------------------------
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
}

// Provider for the service
final notificationServiceProvider = Provider((ref) => NotificationService(ref));