import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:turbo_disc_golf/services/search/course_search_provider.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';

/// MeiliSearch implementation of [CourseSearchProvider].
///
/// Uses production URL (Fly.io) in these cases:
/// - Release mode (always)
/// - Physical device in debug mode (can't reach localhost)
///
/// Uses localhost only when running on simulator in debug mode.
///
/// Reads API key from MEILISEARCH_API_KEY environment variable.
class MeiliSearchProvider implements CourseSearchProvider {
  static const String _index = 'courses';

  static const String _localUrl = 'http://localhost:7700';
  static const String _productionUrl =
      'https://meilisearch-fly-young-firefly-2568.fly.dev';

  String? _cachedBaseUrl;

  Future<String> _getBaseUrl() async {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;

    // Always use production in release mode
    if (!kDebugMode) {
      _cachedBaseUrl = _productionUrl;
      return _cachedBaseUrl!;
    }

    // In debug mode, check if physical device
    final bool isPhysical = await _isPhysicalDevice();
    if (isPhysical || !useLocalMeiliSearchOnSimulator) {
      _cachedBaseUrl = _productionUrl;
    } else {
      _cachedBaseUrl = _localUrl;
    }
    return _cachedBaseUrl!;
  }

  Future<bool> _isPhysicalDevice() async {
    if (Platform.isIOS) {
      final IosDeviceInfo info = await DeviceInfoPlugin().iosInfo;
      return info.isPhysicalDevice;
    }
    if (Platform.isAndroid) {
      final AndroidDeviceInfo info = await DeviceInfoPlugin().androidInfo;
      return info.isPhysicalDevice;
    }
    return false;
  }

  Map<String, String> get _headers {
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    final String? apiKey = dotenv.env['MEILISEARCH_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }
    return headers;
  }

  @override
  Future<List<Map<String, dynamic>>> search(
    String query, {
    int limit = 25,
  }) async {
    final String baseUrl = await _getBaseUrl();
    final http.Response response = await http.post(
      Uri.parse('$baseUrl/indexes/$_index/search'),
      headers: _headers,
      body: jsonEncode({'q': query, 'limit': limit}),
    );

    if (response.statusCode != 200) {
      throw Exception('MeiliSearch query failed: ${response.statusCode}');
    }

    final Map<String, dynamic> decoded =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> hits = decoded['hits'] as List<dynamic>;

    return hits.cast<Map<String, dynamic>>();
  }

  @override
  Future<void> indexDocument(Map<String, dynamic> doc) async {
    final String baseUrl = await _getBaseUrl();
    final http.Response response = await http.post(
      Uri.parse('$baseUrl/indexes/$_index/documents'),
      headers: _headers,
      body: jsonEncode([doc]),
    );

    if (response.statusCode != 202) {
      throw Exception('Failed to index document: ${response.statusCode}');
    }
  }

  @override
  Future<void> indexDocuments(List<Map<String, dynamic>> docs) async {
    if (docs.isEmpty) return;

    final String baseUrl = await _getBaseUrl();
    final http.Response response = await http.post(
      Uri.parse('$baseUrl/indexes/$_index/documents'),
      headers: _headers,
      body: jsonEncode(docs),
    );

    if (response.statusCode != 202) {
      throw Exception('Failed to bulk index documents: ${response.statusCode}');
    }
  }

  @override
  Future<void> deleteDocument(String id) async {
    final String baseUrl = await _getBaseUrl();
    final http.Response response = await http.delete(
      Uri.parse('$baseUrl/indexes/$_index/documents/$id'),
      headers: _headers,
    );

    if (response.statusCode != 202) {
      throw Exception('Failed to delete document: ${response.statusCode}');
    }
  }

  @override
  Future<void> clearIndex() async {
    final String baseUrl = await _getBaseUrl();
    final http.Response response = await http.delete(
      Uri.parse('$baseUrl/indexes/$_index/documents'),
      headers: _headers,
    );

    if (response.statusCode != 202) {
      throw Exception('Failed to clear index: ${response.statusCode}');
    }
  }

  /// Creates the index if it doesn't exist and configures settings.
  /// Safe to call multiple times - will update settings if index already exists.
  Future<void> initializeIndex() async {
    final String baseUrl = await _getBaseUrl();

    // Create index (will return 202 if created, 200 if already exists)
    final http.Response createResponse = await http.post(
      Uri.parse('$baseUrl/indexes'),
      headers: _headers,
      body: jsonEncode({'uid': _index, 'primaryKey': 'id'}),
    );

    if (createResponse.statusCode != 202 && createResponse.statusCode != 200) {
      throw Exception('Failed to create index: ${createResponse.statusCode}');
    }

    // Configure settings
    await updateIndexSettings();
  }

  /// Updates the searchable and filterable attributes for the index.
  Future<void> updateIndexSettings() async {
    final String baseUrl = await _getBaseUrl();
    final http.Response response = await http.patch(
      Uri.parse('$baseUrl/indexes/$_index/settings'),
      headers: _headers,
      body: jsonEncode({
        'searchableAttributes': ['name', 'city', 'state', 'country'],
        'filterableAttributes': ['id', 'city', 'state', 'country'],
      }),
    );

    if (response.statusCode != 202) {
      throw Exception('Failed to update settings: ${response.statusCode}');
    }
  }
}
