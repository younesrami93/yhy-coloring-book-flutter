import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/user_model.dart';
import 'api_client.dart'; // <--- Import the new client

class AuthService {
  // Use the central client
  final ApiClient _client = ApiClient();

  static const String _tokenKey = 'auth_token';
  static const String _deviceUuidKey = 'device_uuid';


  Future<User?> getUserData() async {
    try {
      final response = await _client.get('user/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userMap = data['user'];
        final token = await getToken();
        return User.fromJson(userMap, token: token);
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
    return null;
  }


  Future<User?> loginAsGuest() async {
    try {
      final deviceData = await _getDevicePayload();

      final body = {
        "device_uuid": deviceData['uuid'],
        "platform": Platform.isAndroid ? 'android' : 'ios',
        "language": Platform.localeName.split('_')[0],
      };

      // --- CLEANER CALL ---
      // We just pass the endpoint name "guest-login", not the full URL.
      // Headers and JSON encoding are handled automatically.
      final response = await _client.post('auth/login', body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final String token = data['token'];

        await _saveToken(token);

        return User.fromJson(data['user'], token: token);
      } else {
        return null; // Error logging is already done in ApiClient
      }
    } catch (e) {
      return null;
    }
  }

  // ... (keep _getDevicePayload, _saveToken, getToken, logout as they were) ...
  // ... (No changes needed to those helper methods) ...

  Future<Map<String, String>> _getDevicePayload() async {
    // ... (Same as before) ...
    final prefs = await SharedPreferences.getInstance();
    // ... copy previous implementation ...
    // For brevity, assuming you kept the previous implementation here
    // If you need me to repost the UUID logic, let me know!
    return {'uuid': 'temp-uuid'}; // Placeholder to keep code valid for this snippet
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
    await prefs.remove(_tokenKey);
  }
}