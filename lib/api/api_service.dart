import 'dart:convert';
import 'dart:io';
import 'package:app/models/User.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/style_model.dart';
import 'api_client.dart';

class ApiService {
  final ApiClient _client = ApiClient();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _tokenKey = 'auth_token';
  static const String _deviceUuidKey = 'device_uuid';
  static const String _iosPersistentIdKey = 'ios_persistent_guest_id';

  /// ----------------------------------------------------------------
  /// 1. AUTHENTICATION & SESSION
  /// ----------------------------------------------------------------

  /// Unified Authentication: Handles Guest, Google, and Facebook logins.
  Future<User?> authenticate({
    String? provider,
    String? socialToken,
    String? socialAccessToken,
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
        body['social_token'] = socialToken;
        if (socialAccessToken != null) {
          body['access_token'] = socialAccessToken;
        }
      }

      final response = await _client.post('auth/login', body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final String token = data['token'];
        await saveToken(token);
        return User.fromJson(data['user'], token: token);
      }
      return null;
    } catch (e) {
      debugPrint("Auth Error: $e");
      return null;
    }
  }

  Future<User?> getUserData() async {
    try {
      final response = await _client.get('user/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = await getToken();
        return User.fromJson(data['user'], token: token);
      }
    } catch (e) {
      debugPrint("Get User Data Error: $e");
    }
    return null;
  }

  /// ----------------------------------------------------------------
  /// 2. NOTIFICATIONS & DEVICES
  /// ----------------------------------------------------------------

  Future<bool> syncDeviceToken(String fcmToken) async {
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
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("FCM Sync Error: $e");
      return false;
    }
  }

  /// ----------------------------------------------------------------
  /// 3. APP DATA
  /// ----------------------------------------------------------------

  Future<List<StyleModel>> fetchStyles() async {
    final response = await _client.get('styles');

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      final List<dynamic> data = jsonResponse['data'];
      return data.map((e) => StyleModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load styles');
    }
  }

  /// ----------------------------------------------------------------
  /// 4. STORAGE HELPERS (Centralized)
  /// ----------------------------------------------------------------

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<Map<String, String>> _getDevicePayload() async {
    String deviceId;

    if (Platform.isAndroid) {
      // 1. ANDROID: Use Hardware ID (Survives Uninstall)
      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        // 'id' is a string unique to this device + signing key
        deviceId = androidInfo.id;
      } catch (e) {
        // Fallback if something weird happens (rare)
        deviceId = const Uuid().v4();
      }
    } else if (Platform.isIOS) {
      // 2. iOS: Use Keychain (Survives Uninstall)
      // Check if we already have a saved ID in the secure vault
      String? storedId = await _storage.read(key: _iosPersistentIdKey);

      if (storedId == null) {
        // First time ever? Generate one and LOCK it in the Keychain
        storedId = const Uuid().v4();
        await _storage.write(key: _iosPersistentIdKey, value: storedId);
      }
      deviceId = storedId;
    } else {
      // 3. FALLBACK (Web/Desktop) - Uses SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      deviceId = prefs.getString('device_uuid') ?? const Uuid().v4();
      if (prefs.getString('device_uuid') == null) {
        await prefs.setString('device_uuid', deviceId);
      }
    }

    return {'uuid': deviceId};
  }
}
