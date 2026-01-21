import 'dart:convert';
import 'dart:io'; // <--- Added for File
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
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
      rethrow;
    }
  }

  // 2. Centralized POST Request (JSON)
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

  // 3. NEW: Centralized Multipart Request (File Uploads)
  Future<http.Response> postMultipart(
      String endpoint, {
        required File file,
        required String fileField, // e.g. 'image'
        Map<String, String>? fields, // e.g. {'style_id': '1'}
      }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/$endpoint');
    final request = http.MultipartRequest('POST', url);

    // Add Headers
    final headers = await _getHeaders();
    request.headers.addAll(headers);
    // NOTE: Do NOT set Content-Type manually for multipart; the request handles it (boundary)
    request.headers.remove('Content-Type');

    // Add Text Fields
    if (fields != null) {
      request.fields.addAll(fields);
    }

    // Add File
    final multipartFile = await http.MultipartFile.fromPath(
      fileField,
      file.path,
    );
    request.files.add(multipartFile);

    _logRequest('MULTIPART POST', url, headers, fields);

    try {
      final streamedResponse = await request.send();
      // Convert stream back to standard Response to easy parsing/logging
      final response = await http.Response.fromStream(streamedResponse);
      _logResponse(url, response);
      return response;
    } catch (e) {
      _logError(url, e);
      rethrow;
    }
  }

  // 4. Unified Headers
  Future<Map<String, String>> _getHeaders() async {
    final Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<List<StyleModel>> fetchStyles() async {
    final response = await get('styles');

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      final List<dynamic> data = jsonResponse['data'];
      return data.map((e) => StyleModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load styles: ${response.statusCode}');
    }
  }

  // --- Logging Helpers ---
  void _logRequest(String method, Uri url, Map<String, String> headers, [dynamic body]) {
    if (kDebugMode) {
      print('🔵 [API Request] $method: $url');
      if (body != null) print('   Body: $body');
    }
  }

  void _logResponse(Uri url, http.Response response) {
    if (kDebugMode) {
      final statusEmoji = response.statusCode >= 200 && response.statusCode < 300 ? '🟢' : '🔴';
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