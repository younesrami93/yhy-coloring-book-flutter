import 'dart:convert';
import 'dart:io';
import 'package:app/api/api_service.dart';
import 'package:app/core/api_constants.dart';
import 'package:app/models/User.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../api/api_client.dart';
// import '../core/api_constants.dart'; // Uncomment if needed

class AuthService {
  final ApiClient _client = ApiClient();
  final ApiService _apiService = ApiService();

  // lib/api/auth_service.dart

  // --- VERSION 6 STYLE: Unnamed Constructor ---
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // TODO: Paste your Web Client ID here (from Google Cloud Console)
    serverClientId: ApiConstants.webClientId,
    scopes: ['email', 'profile', 'openid'],
  );

  static const String _tokenKey = 'auth_token';

  /// ----------------------------------------------------------------
  /// 1. UNIFIED AUTHENTICATION HANDLER
  /// ----------------------------------------------------------------

  /// ----------------------------------------------------------------
  /// 2. LOGIN METHODS
  /// ----------------------------------------------------------------


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
        return _apiService.authenticate(
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
        return _apiService.authenticate(
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

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await _googleSignIn.signOut();
      await FacebookAuth.instance.logOut();
    } catch (_) {}
    await prefs.remove(_tokenKey);
  }
}
