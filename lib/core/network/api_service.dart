import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiService {
  /// Toggle to switch between Live Firebase Server and Local Server
  static bool isProduction = true;

  /// Live Deployed Hostinger VPS Backend Base URL
  static const String liveHostingerBaseUrl = 'http://72.61.229.6:5000/api/v1';

  /// Live Deployed Firebase Backend Base URL (Fallback)
  static const String liveFirebaseBaseUrl = 'https://propconnect-b89bd.web.app/api/v1';

  static String get baseUrl {
    if (isProduction) {
      return liveHostingerBaseUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:5000/api/v1';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api/v1';
    }
    return 'http://127.0.0.1:5000/api/v1';
  }

  static String? _authToken;
  static VoidCallback? onSessionExpired;
  static Future<void> Function(String newToken, Map<String, dynamic> user)? onTokenRefreshed;

  static void setAuthToken(String token) {
    _authToken = token;
  }

  static String? getAuthToken() => _authToken;

  static const Duration _timeout = Duration(seconds: 12);

  static bool _isRefreshing = false;
  static final List<Completer<bool>> _refreshWaiters = [];

  /// Proactively or reactively refresh the authentication token from PostgreSQL backend
  static Future<bool> refreshToken() async {
    if (_authToken == null || _authToken!.isEmpty) return false;

    if (_isRefreshing) {
      final completer = Completer<bool>();
      _refreshWaiters.add(completer);
      return completer.future;
    }

    _isRefreshing = true;

    try {
      final url = Uri.parse('$baseUrl/auth/refresh');
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      final request = await client.postUrl(url).timeout(const Duration(seconds: 8));
      request.headers.set('content-type', 'application/json; charset=UTF-8');
      request.headers.set('authorization', 'Bearer $_authToken');
      request.write(jsonEncode({'token': _authToken}));

      final response = await request.close().timeout(const Duration(seconds: 8));
      final responseBody = await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 8));
      client.close();

      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      if (response.statusCode == 200 && decoded['success'] == true && decoded['data'] != null) {
        final data = decoded['data'] as Map<String, dynamic>;
        final newToken = data['token'] as String?;
        final user = data['user'] as Map<String, dynamic>?;

        if (newToken != null && newToken.isNotEmpty) {
          _authToken = newToken;
          if (user != null && onTokenRefreshed != null) {
            await onTokenRefreshed!(newToken, user);
          }
          _resolveRefreshWaiters(true);
          return true;
        }
      }
    } catch (_) {}

    _resolveRefreshWaiters(false);
    return false;
  }

  static void _resolveRefreshWaiters(bool success) {
    _isRefreshing = false;
    for (final waiter in _refreshWaiters) {
      if (!waiter.isCompleted) {
        waiter.complete(success);
      }
    }
    _refreshWaiters.clear();
  }

  /// Core HTTP client with automatic 401 refresh-and-retry handling
  static Future<Map<String, dynamic>> _sendRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    bool isRetry = false,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final client = HttpClient()..connectionTimeout = _timeout;

    try {
      HttpClientRequest request;
      switch (method.toUpperCase()) {
        case 'POST':
          request = await client.postUrl(url).timeout(_timeout);
          break;
        case 'PUT':
          request = await client.putUrl(url).timeout(_timeout);
          break;
        case 'PATCH':
          request = await client.patchUrl(url).timeout(_timeout);
          break;
        case 'DELETE':
          request = await client.deleteUrl(url).timeout(_timeout);
          break;
        case 'GET':
        default:
          request = await client.getUrl(url).timeout(_timeout);
          break;
      }

      request.headers.set('content-type', 'application/json; charset=UTF-8');
      if (includeAuth && _authToken != null && _authToken!.isNotEmpty) {
        request.headers.set('authorization', 'Bearer $_authToken');
      }

      if (body != null) {
        request.write(jsonEncode(body));
      }

      final response = await request.close().timeout(_timeout);
      final responseBody = await response.transform(utf8.decoder).join().timeout(_timeout);

      // Auto 401 Refresh & Transparent Retry Interceptor
      if (response.statusCode == 401 && !isRetry && !endpoint.startsWith('/auth/')) {
        client.close();
        final refreshed = await refreshToken();
        if (refreshed) {
          return await _sendRequest(
            method,
            endpoint,
            body: body,
            includeAuth: includeAuth,
            isRetry: true,
          );
        } else {
          onSessionExpired?.call();
        }
      }

      final decodedData = jsonDecode(responseBody) as Map<String, dynamic>;
      return decodedData;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error connecting to backend server ($e)',
      };
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    return _sendRequest('POST', endpoint, body: body);
  }

  static Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic> body) async {
    return _sendRequest('PATCH', endpoint, body: body);
  }

  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body) async {
    return _sendRequest('PUT', endpoint, body: body);
  }

  static Future<Map<String, dynamic>> get(String endpoint, {bool includeAuth = true}) async {
    return _sendRequest('GET', endpoint, includeAuth: includeAuth);
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    return _sendRequest('DELETE', endpoint);
  }

  /// PRD Sec 16: Send Property Brochure to Client WhatsApp via Interakt API
  static Future<Map<String, dynamic>> sendWhatsAppBrochure({
    required String recipientPhone,
    required String propertyName,
    String? clientName,
    String? propertyPrice,
    String? propertyLocation,
    String? bhk,
    String? carpetArea,
    String? brochureUrl,
  }) async {
    return await post('/whatsapp/send-brochure', {
      'recipientPhone': recipientPhone,
      'clientName': clientName,
      'propertyName': propertyName,
      'propertyPrice': propertyPrice,
      'propertyLocation': propertyLocation,
      'bhk': bhk,
      'carpetArea': carpetArea,
      'brochureUrl': brochureUrl,
    });
  }

  /// PRD Sec 17: Register Device FCM Token with PostgreSQL User Profile
  static Future<Map<String, dynamic>> registerFcmToken({
    required int userId,
    required String fcmToken,
  }) async {
    return await post('/notifications/register-token', {
      'userId': userId,
      'fcmToken': fcmToken,
    });
  }

  /// PRD Sec 17: Fetch In-App Notifications Feed
  static Future<Map<String, dynamic>> getNotifications({
    int? userId,
    int? agencyId,
    String? status,
    String? type,
  }) async {
    final params = <String>[];
    if (userId != null) params.add('userId=$userId');
    if (agencyId != null) params.add('agencyId=$agencyId');
    if (status != null && status.isNotEmpty && status != 'all') params.add('status=$status');
    if (type != null && type.isNotEmpty && type != 'all') params.add('type=$type');
    final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
    return await get('/notifications$queryString');
  }

  /// PRD Sec 17: Mark Individual Notification as Read
  static Future<Map<String, dynamic>> markNotificationAsRead(int notificationId) async {
    return await put('/notifications/$notificationId/read', {});
  }

  /// PRD Sec 17: Mark All Notifications as Read
  static Future<Map<String, dynamic>> markAllNotificationsAsRead({
    int? userId,
    int? agencyId,
  }) async {
    final body = <String, dynamic>{};
    if (userId != null) body['userId'] = userId;
    if (agencyId != null) body['agencyId'] = agencyId;
    return await put('/notifications/read-all', body);
  }

  /// PRD Sec 17: Delete Notification
  static Future<Map<String, dynamic>> deleteNotification(int notificationId) async {
    return await delete('/notifications/$notificationId');
  }

  /// PRD Sec 7.3: Upload Deal Document
  static Future<Map<String, dynamic>> uploadDealDocument(String dealId, {
    required String title,
    required String documentType,
    String? fileUrl,
    String? uploadedBy,
    String? notes,
  }) async {
    return await post('/deals/$dealId/documents', {
      'title': title,
      'documentType': documentType,
      'fileUrl': fileUrl,
      'uploadedBy': uploadedBy,
      'notes': notes,
    });
  }

  /// Upload real document (PDF / image / doc) as Base64 to server storage
  static Future<Map<String, dynamic>> uploadFileBase64({
    required String base64Data,
    required String fileName,
  }) async {
    return await post('/upload/base64', {
      'document': base64Data,
      'filename': fileName,
    });
  }

  /// PRD Sec 7.3: Delete Deal Document
  static Future<Map<String, dynamic>> deleteDealDocument(String dealId, String docId) async {
    return await delete('/deals/$dealId/documents/$docId');
  }
}
