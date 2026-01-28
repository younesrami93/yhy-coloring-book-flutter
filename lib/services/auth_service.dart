import 'dart:convert';
import 'dart:io';
import 'package:app/core/api_constants.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/user_model.dart';
import '../api/api_client.dart';
// import '../core/api_constants.dart'; // Uncomment if needed

class AuthService {
  final ApiClient _client = ApiClient();

  // lib/api/auth_service.dart

  Future<bool> syncDeviceToken(String fcmToken) async {
    debugPrint("🚀 Attempting to sync FCM Token: $fcmToken");
    try {
      final deviceData = await _getDevicePayload();
      final packageInfo = await PackageInfo.fromPlatform();

      final Map<String, dynamic> body = {
        "fcm_token": fcmToken,
        "device_uuid": deviceData['uuid'],
        "platform": Platform.isAndroid ? 'android' : 'ios',
        "language": Platform.localeName.split('_')[0],
        "app_version": packageInfo.version,
      };

      final response = await _client.post('devices/sync', body: body);

      // Diagnostic Logs
      debugPrint("📡 Sync Response Status: ${response.statusCode}");
      debugPrint("📡 Sync Response Body: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ FCM Sync Error: $e");
      return false;
    }
  }

  // --- VERSION 6 STYLE: Unnamed Constructor ---
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // TODO: Paste your Web Client ID here (from Google Cloud Console)
    serverClientId: ApiConstants.webClientId,
    scopes: ['email', 'profile', 'openid'],
  );

  static const String _tokenKey = 'auth_token';
  static const String _deviceUuidKey = 'device_uuid';

  /// ----------------------------------------------------------------
  /// 1. UNIFIED AUTHENTICATION HANDLER
  /// ----------------------------------------------------------------
  Future<User?> _authenticate({
    String? provider,
    String? socialToken,
    String? socialAccessToken, // Added for V6 compatibility
  }) async {
    try {
      final deviceData = await _getDevicePayload();

      final Map<String, dynamic> body = {
        "device_uuid": deviceData['uuid'],
        "platform": Platform.isAndroid ? 'android' : 'ios',
        "language": Platform.localeName.split('_')[0],
      };

      if (provider != null && socialToken != null) {
        body['provider'] = provider;
        body['social_token'] = socialToken; // Usually ID Token
        if (socialAccessToken != null) {
          body['access_token'] =
              socialAccessToken; // Send access token if available
        }
      }

      final response = await _client.post('auth/login', body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final String token = data['token'];
        await _saveToken(token);
        return User.fromJson(data['user'], token: token);
      } else {
        debugPrint("Auth Failed: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Auth Error: $e");
      return null;
    }
  }

  /// ----------------------------------------------------------------
  /// 2. LOGIN METHODS
  /// ----------------------------------------------------------------

  Future<User?> loginAsGuest() async {
    return _authenticate();
  }

  Future<User?> loginWithGoogle() async {
    try {
      // 1. Force Clean Sign Out (Fixes "Reauth failed" in many cases)
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      // 2. Sign In (V6 Style)
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return null; // Cancelled

      // 3. Get Auth Details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // V6 allows accessing both idToken and accessToken directly
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken != null) {
        return _authenticate(
          provider: 'google',
          socialToken: idToken,
          socialAccessToken: accessToken,
        );
      }
    } catch (e) {
      debugPrint("Google Sign In Error: $e");
      rethrow;
    }
    return null;
  }

  Future<User?> loginWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        return _authenticate(
          provider: 'facebook',
          socialToken: result.accessToken!.tokenString,
        );
      }
    } catch (e) {
      debugPrint("Facebook Error: $e");
    }
    return null;
  }

  /// ----------------------------------------------------------------
  /// 3. HELPER METHODS
  /// ----------------------------------------------------------------

  Future<User?> getUserData() async {
    try {
      final response = await _client.get('user/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data['user'], token: await getToken());
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
    return null;
  }

  Future<Map<String, String>> _getDevicePayload() async {
    final prefs = await SharedPreferences.getInstance();
    String? uuid = prefs.getString(_deviceUuidKey);

    if (uuid == null) {
      uuid = const Uuid().v4();
      await prefs.setString(_deviceUuidKey, uuid);
    }
    return {'uuid': uuid};
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await _googleSignIn.signOut();
      await FacebookAuth.instance.logOut();
    } catch (_) {}
    await prefs.remove(_tokenKey);
  }
}
