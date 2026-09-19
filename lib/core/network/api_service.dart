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

  static void setAuthToken(String token) {
    _authToken = token;
  }

  static const Duration _timeout = Duration(seconds: 18);

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final client = HttpClient()..connectionTimeout = _timeout;

    try {
      final request = await client.postUrl(url).timeout(_timeout);
      request.headers.set('content-type', 'application/json; charset=UTF-8');
      
      if (_authToken != null) {
        request.headers.set('authorization', 'Bearer $_authToken');
      }

      final jsonString = jsonEncode(body);
      request.write(jsonString);

      final response = await request.close().timeout(_timeout);
      final responseBody = await response.transform(utf8.decoder).join().timeout(_timeout);
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

  static Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final client = HttpClient()..connectionTimeout = _timeout;

    try {
      final request = await client.patchUrl(url).timeout(_timeout);
      request.headers.set('content-type', 'application/json; charset=UTF-8');
      
      if (_authToken != null) {
        request.headers.set('authorization', 'Bearer $_authToken');
      }

      final jsonString = jsonEncode(body);
      request.write(jsonString);

      final response = await request.close().timeout(_timeout);
      final responseBody = await response.transform(utf8.decoder).join().timeout(_timeout);
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

  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final client = HttpClient()..connectionTimeout = _timeout;

    try {
      final request = await client.putUrl(url).timeout(_timeout);
      request.headers.set('content-type', 'application/json; charset=UTF-8');
      
      if (_authToken != null) {
        request.headers.set('authorization', 'Bearer $_authToken');
      }

      final jsonString = jsonEncode(body);
      request.write(jsonString);

      final response = await request.close().timeout(_timeout);
      final responseBody = await response.transform(utf8.decoder).join().timeout(_timeout);
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

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final client = HttpClient()..connectionTimeout = _timeout;

    try {
      final request = await client.getUrl(url).timeout(_timeout);
      request.headers.set('content-type', 'application/json; charset=UTF-8');
      
      if (_authToken != null) {
        request.headers.set('authorization', 'Bearer $_authToken');
      }

      final response = await request.close().timeout(_timeout);
      final responseBody = await response.transform(utf8.decoder).join().timeout(_timeout);
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

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final client = HttpClient()..connectionTimeout = _timeout;

    try {
      final request = await client.deleteUrl(url).timeout(_timeout);
      request.headers.set('content-type', 'application/json; charset=UTF-8');
      
      if (_authToken != null) {
        request.headers.set('authorization', 'Bearer $_authToken');
      }

      final response = await request.close().timeout(_timeout);
      final responseBody = await response.transform(utf8.decoder).join().timeout(_timeout);
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
}
