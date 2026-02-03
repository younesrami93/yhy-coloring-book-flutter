import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart';

/// This service is now strictly for Third-Party SDK interactions.
/// It retrieves credentials and returns them to the AuthNotifier,
/// which then passes them to the ApiService for backend authentication.
class AuthService {
  // VERSION 6 STYLE: Unnamed Constructor
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: ApiConstants.webClientId,
    scopes: ['email', 'profile', 'openid'],
  );


  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }


  /// Triggers the Google Sign-In flow and returns the authentication credentials.
  Future<GoogleSignInAuthentication?> getGoogleCredentials() async {
    try {
      // Force Clean Sign Out to prevent "Reauth failed" errors
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      return await googleUser.authentication;
    } catch (e) {
      debugPrint("Google SDK Error: $e");
      rethrow;
    }
  }

  /// Triggers the Facebook login flow and returns the access token string.
  Future<String?> getFacebookToken() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        return result.accessToken?.tokenString;
      }
    } catch (e) {
      debugPrint("Facebook SDK Error: $e");
    }
    return null;
  }

  /// Clears active sessions from Third-Party SDKs.
  Future<void> logoutSDKs() async {
    try {
      await _googleSignIn.signOut();
      await FacebookAuth.instance.logOut();
    } catch (e) {
      debugPrint("SDK Logout Error: $e");
    }
  }
}