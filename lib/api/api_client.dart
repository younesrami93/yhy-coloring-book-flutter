import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:yhy_coloring_book_flutter/models/style_model.dart';
import '../core/api_constants.dart';

class ApiClient {
  // 1. Centralized GET Request
  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/$endpoint');
    final headers = await _getHeaders();

    _logRequest('GET', url, headers);

    try {
      final response = await http.get(url, headers: headers);
      _logResponse(url, response);
      return response;
    } catch (e) {
      _logError(url, e);
      rethrow; // Pass the error up to the Service to handle
    }
  }

  // 2. Centralized POST Request
  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/$endpoint');
    final headers = await _getHeaders();

    _logRequest('POST', url, headers, body);

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      _logResponse(url, response);
      return response;
    } catch (e) {
      _logError(url, e);
      rethrow;
    }
  }

  // 3. Unified Headers (The Magic Part)
  Future<Map<String, String>> _getHeaders() async {
    // Standard headers for Laravel Sanctum
    final Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };

    // Automatically add the Token if we have one
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<List<StyleModel>> fetchStyles() async {
    // We reuse your existing generic 'get' method
    final response = await get('styles');

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      final List<dynamic> data = jsonResponse['data'];

      return data.map((e) => StyleModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load styles: ${response.statusCode}');
    }
  }

  // --- Logging Helpers (Clean Debugging) ---

  void _logRequest(
    String method,
    Uri url,
    Map<String, String> headers, [
    dynamic body,
  ]) {
    if (kDebugMode) {
      print('🔵 [API Request] $method: $url');
      // print('   Headers: $headers'); // Uncomment if you need to debug headers
      if (body != null) print('   Body: $body');
    }
  }

  void _logResponse(Uri url, http.Response response) {
    if (kDebugMode) {
      final statusEmoji =
          response.statusCode >= 200 && response.statusCode < 300 ? '🟢' : '🔴';
      print('$statusEmoji [API Response] ${response.statusCode}: $url');
      print('   Response: ${response.body}');
    }
  }

  void _logError(Uri url, Object error) {
    if (kDebugMode) {
      print('❌ [API Error] $url: $error');
    }
  }
}
