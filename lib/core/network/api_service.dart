import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiService {
  /// Toggle to switch between Live Firebase Server and Local Server
  static bool isProduction = true;

  /// Live Deployed Firebase Backend Base URL
  static const String liveFirebaseBaseUrl = 'https://propconnect-b89bd.web.app/api/v1';

  static String get baseUrl {
    if (isProduction) {
      return liveFirebaseBaseUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:5001/api/v1';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5001/api/v1';
    }
    return 'http://127.0.0.1:5001/api/v1';
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
}
