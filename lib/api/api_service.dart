import 'dart:convert';
import 'dart:io';
import 'package:app/models/User.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/style_model.dart';
import 'api_client.dart';

class ApiService {
  final ApiClient _client = ApiClient();
  static const String _tokenKey = 'auth_token';

  /// Fetches the list of available coloring styles from the backend
  Future<List<StyleModel>> fetchStyles() async {
    final response = await _client.get('styles');

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      final List<dynamic> data = jsonResponse['data'];
      return data.map((e) => StyleModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load styles: ${response.statusCode}');
    }
  }

  static const String _deviceUuidKey = 'device_uuid';

  Future<Map<String, String>> _getDevicePayload() async {
    final prefs = await SharedPreferences.getInstance();
    String? uuid = prefs.getString(_deviceUuidKey);

    if (uuid == null) {
      uuid = const Uuid().v4();
      await prefs.setString(_deviceUuidKey, uuid);
    }
    return {'uuid': uuid};
  }

  Future<User?> authenticate({
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
        await saveToken(token);
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

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

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

  Future<User?> getUserData() async {
    try {
      final response = await _client.get('user/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(_tokenKey);

        return User.fromJson(data['user'], token: token);
      }
    } catch (e) {
      // Error handling is managed by ApiClient logging
    }
    return null;
  }
}
