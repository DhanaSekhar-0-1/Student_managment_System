import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      // Build URI with query parameters
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final finalUri = queryParams != null && queryParams.isNotEmpty
          ? uri.replace(queryParameters: queryParams)
          : uri;

      final response = await http
          .get(
            finalUri,
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Request timeout. Please try again.');
    } on SocketException {
      throw ApiException('No internet connection.');
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      final response = await http
          .post(
            uri,
            headers: ApiConfig.headers,
            body: json.encode(body),
          )
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Request timeout. Please try again.');
    } on SocketException {
      throw ApiException('No internet connection.');
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      final response = await http
          .patch(
            uri,
            headers: ApiConfig.headers,
            body: json.encode(body),
          )
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Request timeout. Please try again.');
    } on SocketException {
      throw ApiException('No internet connection.');
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      final response = await http
          .delete(
            uri,
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException('Request timeout. Please try again.');
    } on SocketException {
      throw ApiException('No internet connection.');
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data = json.decode(response.body);
        return data as Map<String, dynamic>;
      } catch (e) {
        throw ApiException('Failed to parse response: $e');
      }
    } else {
      try {
        final error = json.decode(response.body);
        throw ApiException(
          error['message'] ?? 'Request failed with status ${response.statusCode}',
        );
      } catch (e) {
        throw ApiException('Request failed with status ${response.statusCode}');
      }
    }
  }
}

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}