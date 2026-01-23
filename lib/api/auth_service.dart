import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // No alias needed now
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/user_model.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  // V7 CHANGE: Use the singleton instance (No constructor)
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static const String _tokenKey = 'auth_token';
  static const String _deviceUuidKey = 'device_uuid';

  // --- CONSTRUCTOR: Initialize Google Sign In ---
  AuthService() {
    _initGoogle();
  }

  Future<void> _initGoogle() async {
    // V7 CHANGE: You MUST initialize before using it
    try {
      await _googleSignIn.initialize();
    } catch (e) {
      debugPrint("Google Init Error: $e");
    }
  }

  // ... [Keep _authenticate method exactly as it was] ...
  Future<User?> _authenticate({String? provider, String? socialToken}) async {
    // (Paste the _authenticate logic from the previous response here)
    // It remains the same because the backend API hasn't changed.
    try {
      final deviceData = await _getDevicePayload();
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) { /* Ignore */ }

      final Map<String, dynamic> body = {
        "device_uuid": deviceData['uuid'],
        "platform": Platform.isAndroid ? 'android' : 'ios',
        "language": Platform.localeName.split('_')[0],
        "fcm_token": fcmToken,
      };

      if (provider != null && socialToken != null) {
        body['provider'] = provider;
        body['social_token'] = socialToken;
      }

      final response = await _client.post('auth/login', body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final String token = data['token'];
        await _saveToken(token);
        return User.fromJson(data['user'], token: token);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- V7 UPDATED GOOGLE LOGIN ---
  Future<User?> loginWithGoogle() async {
    try {
      // V7 CHANGE: Use 'authenticate()' instead of 'signIn()'
      // Note: scopes are usually configured in Google Cloud Console now,
      // but if you need specific ones: .authenticate(scopes: ['email'])
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();

      if (googleUser == null) return null; // User cancelled

      // V7 CHANGE: Authentication is different from Authorization
      // 1. Get the Auth object (contains idToken)
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 2. Decide which token to send to Laravel:
      // - If your Laravel uses Socialite default, it typically wants 'accessToken'.
      // - In v7, accessToken is found in the *Authorization* flow, not Authentication.

      // Let's try sending the 'idToken' first (Safest for new integrations)
      // If Laravel fails, we might need to request scopes to get an accessToken.
      final String? tokenToSend = googleAuth.accessToken ?? googleAuth.idToken;

      if (tokenToSend != null) {
        return _authenticate(
          provider: 'google',
          socialToken: tokenToSend,
        );
      }
    } catch (e) {
      debugPrint("Google Sign In Error: $e");
    }
    return null;
  }

  // --- FACEBOOK LOGIN (Unchanged) ---
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

  // ... [Rest of helper methods: getUserData, logout, etc.] ...
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await _googleSignIn.signOut(); // works same in v7
      await FacebookAuth.instance.logOut();
    } catch (e) { /* Ignore */ }
    await prefs.remove(_tokenKey);
  }

  // ... [Keep _getDevicePayload, _saveToken, getToken] ...
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
}