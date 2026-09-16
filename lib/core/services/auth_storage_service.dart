import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:propconnect/core/network/api_service.dart';
import 'package:propconnect/core/providers/user_role_provider.dart';
import 'package:propconnect/core/models/property_model.dart';

class AuthStorageService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUserData = 'user_data';
  static const String _keyUserRole = 'user_role';
  static const String _keyCachedProperties = 'cached_properties';
  static const String _keyAutoSyncConfig = 'auto_sync_config';

  static SharedPreferences? _prefs;

  /// Scope auto-sync key per agency / user account
  static String _getScopedAutoSyncKey() {
    final userData = getUserData();
    final agencyId = userData?['agencyId'] ?? userData?['agency']?['id'] ?? userData?['id'];
    return agencyId != null ? '${_keyAutoSyncConfig}_$agencyId' : _keyAutoSyncConfig;
  }

  /// Initialize SharedPreferences instance
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Save authenticated session data
  static Future<void> saveSession({
    required String token,
    required Map<String, dynamic> user,
    required UserRole role,
  }) async {
    await init();
    // Clear any previous user's cached properties to avoid leaking inventory
    await _prefs?.remove(_keyCachedProperties);
    // Remove legacy un-scoped auto-sync config
    await _prefs?.remove(_keyAutoSyncConfig);

    await _prefs?.setBool(_keyIsLoggedIn, true);
    await _prefs?.setString(_keyAuthToken, token);
    await _prefs?.setString(_keyUserData, jsonEncode(user));
    await _prefs?.setString(_keyUserRole, role == UserRole.agencyAdmin ? 'agencyAdmin' : 'broker');
    
    // Set token in ApiService
    ApiService.setAuthToken(token);
  }

  /// Check if user has an active logged-in session
  static bool isLoggedIn() {
    return _prefs?.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Get stored auth token
  static String? getAuthToken() {
    return _prefs?.getString(_keyAuthToken);
  }

  /// Get stored user profile data
  static Map<String, dynamic>? getUserData() {
    final str = _prefs?.getString(_keyUserData);
    if (str != null && str.isNotEmpty) {
      try {
        return jsonDecode(str) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  /// Get stored user role
  static UserRole getUserRole() {
    final roleStr = _prefs?.getString(_keyUserRole);
    if (roleStr == 'broker') {
      return UserRole.broker;
    }
    return UserRole.agencyAdmin;
  }

  /// Load session on app startup
  static void loadSessionIntoServices() {
    if (isLoggedIn()) {
      final token = getAuthToken();
      if (token != null && token.isNotEmpty) {
        ApiService.setAuthToken(token);
      }
    }
  }

  /// Clear session on logout
  static Future<void> clearSession() async {
    await init();
    final scopedKey = _getScopedAutoSyncKey();
    await _prefs?.remove(_keyIsLoggedIn);
    await _prefs?.remove(_keyAuthToken);
    await _prefs?.remove(_keyUserData);
    await _prefs?.remove(_keyUserRole);
    await _prefs?.remove(_keyCachedProperties);
    await _prefs?.remove(_keyAutoSyncConfig);
    await _prefs?.remove(scopedKey);
    ApiService.setAuthToken('');
  }

  /// Cache properties to local storage for instant zero-lag startup
  static Future<void> saveCachedProperties(List<PropertyModel> properties) async {
    try {
      await init();
      final jsonList = properties.map((p) => p.toJson()).toList();
      await _prefs?.setString(_keyCachedProperties, jsonEncode(jsonList));
    } catch (_) {}
  }

  /// Retrieve cached properties from local storage
  static List<PropertyModel> getCachedProperties() {
    try {
      final str = _prefs?.getString(_keyCachedProperties);
      if (str != null && str.isNotEmpty) {
        final decoded = jsonDecode(str) as List<dynamic>;
        return decoded.map((item) => PropertyModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Save partner feed auto-sync settings (scoped to current agency/account)
  static Future<void> saveAutoSyncConfig({
    required String platform,
    required String frequency,
    required String apiKey,
    required String feedUrl,
    required bool isEnabled,
    DateTime? lastSyncedAt,
  }) async {
    try {
      await init();
      final data = {
        'platform': platform,
        'frequency': frequency,
        'apiKey': apiKey,
        'feedUrl': feedUrl,
        'isEnabled': isEnabled,
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      };
      final key = _getScopedAutoSyncKey();
      await _prefs?.setString(key, jsonEncode(data));
      // Remove any un-scoped legacy key
      await _prefs?.remove(_keyAutoSyncConfig);
    } catch (_) {}
  }

  /// Get partner feed auto-sync settings (scoped to current agency/account)
  static Map<String, dynamic>? getAutoSyncConfig() {
    try {
      final key = _getScopedAutoSyncKey();
      final str = _prefs?.getString(key);
      if (str != null && str.isNotEmpty) {
        return jsonDecode(str) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Update last synced timestamp
  static Future<void> updateLastSyncedAt(DateTime timestamp) async {
    try {
      final config = getAutoSyncConfig();
      if (config != null) {
        config['lastSyncedAt'] = timestamp.toIso8601String();
        final key = _getScopedAutoSyncKey();
        await _prefs?.setString(key, jsonEncode(config));
      }
    } catch (_) {}
  }

  /// Clear auto sync config for current user/agency
  static Future<void> clearAutoSyncConfig() async {
    try {
      await init();
      final key = _getScopedAutoSyncKey();
      await _prefs?.remove(key);
      await _prefs?.remove(_keyAutoSyncConfig);
    } catch (_) {}
  }
}
