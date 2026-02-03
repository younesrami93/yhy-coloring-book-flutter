import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../core/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The networking engine of the app.
/// Handles raw HTTP communication, headers, and centralized logging.
class ApiClient {
  static const String _tokenKey = 'auth_token';

  // ----------------------------------------------------------------
  // 1. CORE REQUEST METHODS
  // ----------------------------------------------------------------

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/$endpoint');
    final headers = await _getHeaders();

    return _performRequest(() => http.get(url, headers: headers), 'GET', url);
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/$endpoint');
    final headers = await _getHeaders();
    final jsonBody = body != null ? jsonEncode(body) : null;

    return _performRequest(
      () => http.post(url, headers: headers, body: jsonBody),
      'POST',
      url,
      body: body,
    );
  }

  /// Specialized Multipart request for file uploads (e.g., images)
  Future<http.Response> postMultipart(
    String endpoint, {
    required File file,
    required String fileField,
    Map<String, String>? fields,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/$endpoint');
    final request = http.MultipartRequest('POST', url);

    // 1. Set Headers (Multipart manages its own Content-Type boundary)
    final headers = await _getHeaders();
    request.headers.addAll(headers);
    request.headers.remove('Content-Type');

    // 2. Add Payload
    if (fields != null) request.fields.addAll(fields);
    request.files.add(await http.MultipartFile.fromPath(fileField, file.path));

    // 3. Send and convert Stream to standard Response
    _logRequest('MULTIPART POST', url, request.headers, fields);
    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      _logResponse(url, response);
      return response;
    } catch (e) {
      _logError(url, e);
      rethrow;
    }
  }

  // ----------------------------------------------------------------
  // 2. PRIVATE HELPERS
  // ----------------------------------------------------------------

  /// Wrapper to handle logging and standard try-catch for basic requests
  Future<http.Response> _performRequest(
    Future<http.Response> Function() requestFn,
    String method,
    Uri url, {
    dynamic body,
  }) async {
    final headers = await _getHeaders();
    _logRequest(method, url, headers, body);

    try {
      final response = await requestFn();
      _logResponse(url, response);
      return response;
    } catch (e) {
      _logError(url, e);
      rethrow;
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  // ----------------------------------------------------------------
  // 3. LOGGING (Debug Mode Only)
  // ----------------------------------------------------------------

  void _logRequest(
    String method,
    Uri url,
    Map<String, String> headers, [
    dynamic body,
  ]) {
    if (kDebugMode) {
      print('🔵 [API Request] $method: $url');
      if (body != null) print('   Body: $body');
    }
  }

  void _logResponse(Uri url, http.Response response) {
    if (kDebugMode) {
      final status = response.statusCode;
      final emoji = (status >= 200 && status < 300) ? '🟢' : '🔴';
      print('$emoji [API Response] $status: $url');
      print('   Data: ${response.body}');
    }
  }

  void _logError(Uri url, Object error) {
    if (kDebugMode) print('❌ [API Error] $url: $error');
  }
}
