import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:propconnect/core/network/api_service.dart';
import 'package:propconnect/core/providers/user_role_provider.dart';
import 'package:propconnect/core/models/property_model.dart';
import 'package:propconnect/core/models/deal_model.dart';
import 'package:propconnect/core/models/commission_model.dart';
import 'package:propconnect/core/models/owner_model.dart';
import 'package:propconnect/core/services/push_notification_service.dart';
import 'package:propconnect/core/services/user_presence_service.dart';

class AuthStorageService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUserData = 'user_data';
  static const String _keyUserRole = 'user_role';
  static const String _keyCachedProperties = 'cached_properties';
  static const String _keyCachedDeals = 'cached_deals';
  static const String _keyCachedCommissions = 'cached_commissions';
  static const String _keyCachedOwners = 'cached_owners';
  static const String _keyAutoSyncConfig = 'auto_sync_config';
  static const String _keyThemeMode = 'app_theme_mode';
  static const String _keyPushNotification = 'pref_push_notification';
  static const String _keyEmailAlerts = 'pref_email_alerts';
  static const String _keyTwoFactor = 'pref_two_factor';

  static VoidCallback? onSessionCleared;

  static SharedPreferences? _prefs;

  /// Scope auto-sync key per agency / user account
  static String _getScopedAutoSyncKey() {
    final userData = getUserData();
    final agencyId = userData?['agencyId'] ?? userData?['agency']?['id'] ?? userData?['id'];
    return agencyId != null ? '${_keyAutoSyncConfig}_$agencyId' : _keyAutoSyncConfig;
  }

  /// Initialize SharedPreferences instance
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save authenticated session data
  static Future<void> saveSession({
    required String token,
    required Map<String, dynamic> user,
    required UserRole role,
  }) async {
    await init();
    // Clear previous caches to avoid leaking data across user accounts
    await _prefs?.remove(_keyCachedProperties);
    await _prefs?.remove(_keyCachedDeals);
    await _prefs?.remove(_keyCachedCommissions);
    await _prefs?.remove(_keyCachedOwners);
    // Remove legacy un-scoped auto-sync config
    await _prefs?.remove(_keyAutoSyncConfig);

    await _prefs?.setBool(_keyIsLoggedIn, true);
    await _prefs?.setString(_keyAuthToken, token);
    await _prefs?.setString(_keyUserData, jsonEncode(user));
    await _prefs?.setString(_keyUserRole, role == UserRole.agencyAdmin ? 'agencyAdmin' : 'broker');
    
    // Set token in ApiService
    ApiService.setAuthToken(token);

    // Sync device FCM token with backend
    PushNotificationService().syncTokenWithBackend();

    // Mark online in presence tracker
    UserPresenceService.setOnline(true);
  }

  /// Update authenticated token and user profile together (used after automatic token refresh)
  static Future<void> updateTokenAndUser(String token, Map<String, dynamic> user) async {
    await init();
    await _prefs?.setString(_keyAuthToken, token);
    await updateUserData(user);
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

  /// Update stored user profile data and synchronize user role
  static Future<void> updateUserData(Map<String, dynamic> user) async {
    await init();
    await _prefs?.setString(_keyUserData, jsonEncode(user));
    final roleStr = (user['role'] as String?)?.toLowerCase() ??
        (user['userType'] as String?)?.toLowerCase();
    if (roleStr == 'broker') {
      await _prefs?.setString(_keyUserRole, 'broker');
    } else if (roleStr == 'agency_admin' || roleStr == 'super_admin') {
      await _prefs?.setString(_keyUserRole, 'agencyAdmin');
    }
  }

  /// Persist user role
  static Future<void> saveUserRole(UserRole role) async {
    await init();
    await _prefs?.setString(_keyUserRole, role == UserRole.agencyAdmin ? 'agencyAdmin' : 'broker');
  }

  /// Proactively refresh session profile and agency from PostgreSQL in background
  static Future<bool> refreshSession({void Function(Map<String, dynamic>)? onRefreshed}) async {
    if (!isLoggedIn()) return false;
    try {
      final res = await ApiService.get('/auth/me');
      if (res['success'] == true && res['data'] != null && res['data'] is Map) {
        final data = Map<String, dynamic>.from(res['data'] as Map);
        await updateUserData(data);
        if (onRefreshed != null) {
          onRefreshed(data);
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Get stored user role with robust fallback to user profile data
  static UserRole getUserRole() {
    final roleStr = _prefs?.getString(_keyUserRole);
    if (roleStr == 'broker') {
      return UserRole.broker;
    }
    if (roleStr == 'agencyAdmin' || roleStr == 'agency_admin') {
      return UserRole.agencyAdmin;
    }
    final userData = getUserData();
    if (userData != null) {
      final role = (userData['role'] ?? userData['userType'] ?? '').toString().toLowerCase();
      if (role == 'broker') {
        return UserRole.broker;
      }
    }
    return UserRole.agencyAdmin;
  }

  /// Load session on app startup and wire ApiService interceptors
  static void loadSessionIntoServices() {
    ApiService.onTokenRefreshed = updateTokenAndUser;
    ApiService.onSessionExpired = clearSession;
    if (isLoggedIn()) {
      final token = getAuthToken();
      if (token != null && token.isNotEmpty) {
        ApiService.setAuthToken(token);
        UserPresenceService.setOnline(true);
      }
    }
  }

  /// Clear session on logout
  static Future<void> clearSession() async {
    try {
      await UserPresenceService.setOnline(false).timeout(const Duration(milliseconds: 800));
    } catch (_) {}
    await init();
    final scopedKey = _getScopedAutoSyncKey();
    await _prefs?.remove(_keyIsLoggedIn);
    await _prefs?.remove(_keyAuthToken);
    await _prefs?.remove(_keyUserData);
    await _prefs?.remove(_keyUserRole);
    await _prefs?.remove(_keyCachedProperties);
    await _prefs?.remove(_keyCachedDeals);
    await _prefs?.remove(_keyCachedCommissions);
    await _prefs?.remove(_keyCachedOwners);
    await _prefs?.remove(_keyAutoSyncConfig);
    await _prefs?.remove(scopedKey);
    ApiService.setAuthToken('');
    onSessionCleared?.call();
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

  /// Cache deals to local storage for zero-lag instant screen load
  static Future<void> saveCachedDeals(List<DealModel> deals) async {
    try {
      await init();
      final jsonList = deals.map((d) => d.toJson()).toList();
      await _prefs?.setString(_keyCachedDeals, jsonEncode(jsonList));
    } catch (_) {}
  }

  /// Retrieve cached deals from local storage
  static List<DealModel> getCachedDeals() {
    try {
      final str = _prefs?.getString(_keyCachedDeals);
      if (str != null && str.isNotEmpty) {
        final decoded = jsonDecode(str) as List<dynamic>;
        return decoded.map((item) => DealModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Cache commissions to local storage
  static Future<void> saveCachedCommissions(List<CommissionModel> commissions) async {
    try {
      await init();
      final jsonList = commissions.map((c) => c.toJson()).toList();
      await _prefs?.setString(_keyCachedCommissions, jsonEncode(jsonList));
    } catch (_) {}
  }

  /// Retrieve cached commissions
  static List<CommissionModel> getCachedCommissions() {
    try {
      final str = _prefs?.getString(_keyCachedCommissions);
      if (str != null && str.isNotEmpty) {
        final decoded = jsonDecode(str) as List<dynamic>;
        return decoded.map((item) => CommissionModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Cache property owners to local storage
  static Future<void> saveCachedOwners(List<OwnerModel> owners) async {
    try {
      await init();
      final jsonList = owners.map((o) => o.toJson()).toList();
      await _prefs?.setString(_keyCachedOwners, jsonEncode(jsonList));
    } catch (_) {}
  }

  /// Retrieve cached property owners
  static List<OwnerModel> getCachedOwners() {
    try {
      final str = _prefs?.getString(_keyCachedOwners);
      if (str != null && str.isNotEmpty) {
        final decoded = jsonDecode(str) as List<dynamic>;
        return decoded.map((item) => OwnerModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
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

  /// Clear cached properties to free storage
  static Future<void> clearCachedProperties() async {
    try {
      await init();
      await _prefs?.remove(_keyCachedProperties);
    } catch (_) {}
  }

  /// Theme Mode setting ('system', 'light', 'dark')
  static String getThemeMode() {
    return _prefs?.getString(_keyThemeMode) ?? 'light';
  }

  static Future<void> setThemeMode(String mode) async {
    await init();
    await _prefs?.setString(_keyThemeMode, mode);
  }

  /// Push Notifications preference (defaults to true)
  static bool getPushNotificationEnabled() {
    return _prefs?.getBool(_keyPushNotification) ?? true;
  }

  static Future<void> setPushNotificationEnabled(bool enabled) async {
    await init();
    await _prefs?.setBool(_keyPushNotification, enabled);
  }

  /// Email Alerts preference (defaults to false)
  static bool getEmailAlertsEnabled() {
    return _prefs?.getBool(_keyEmailAlerts) ?? false;
  }

  static Future<void> setEmailAlertsEnabled(bool enabled) async {
    await init();
    await _prefs?.setBool(_keyEmailAlerts, enabled);
  }

  /// Two Factor Authentication preference (defaults to false)
  static bool getTwoFactorEnabled() {
    return _prefs?.getBool(_keyTwoFactor) ?? false;
  }

  static Future<void> setTwoFactorEnabled(bool enabled) async {
    await init();
    await _prefs?.setBool(_keyTwoFactor, enabled);
  }

  /// Default Property Visibility preference ('Public' vs 'Private' - PRD Sec 4.1.2 & 6.3.1)
  static String getDefaultVisibility() {
    return _prefs?.getString('pref_default_visibility') ?? 'Public';
  }

  static Future<void> setDefaultVisibility(String visibility) async {
    await init();
    await _prefs?.setString('pref_default_visibility', visibility);
  }

  /// WhatsApp Business Broadcast & Push Alerts (PRD Sec 16 & 17)
  static bool getWhatsAppAlertsEnabled() {
    return _prefs?.getBool('pref_whatsapp_alerts') ?? true;
  }

  static Future<void> setWhatsAppAlertsEnabled(bool enabled) async {
    await init();
    await _prefs?.setBool('pref_whatsapp_alerts', enabled);
  }

  /// Automated Reminder: Lead Inactivity Days threshold (PRD Sec 7.2)
  static int getLeadInactivityDays() {
    return _prefs?.getInt('pref_lead_inactivity_days') ?? 7;
  }

  static Future<void> setLeadInactivityDays(int days) async {
    await init();
    await _prefs?.setInt('pref_lead_inactivity_days', days);
  }

  /// Area Unit formatting ('sq.ft', 'sq.yd', 'sq.m')
  static String getAreaUnit() {
    return _prefs?.getString('pref_area_unit') ?? 'sq.ft';
  }

  static Future<void> setAreaUnit(String unit) async {
    await init();
    await _prefs?.setString('pref_area_unit', unit);
  }

  /// Biometric Screen Lock preference
  static bool getBiometricLockEnabled() {
    return _prefs?.getBool('pref_biometric_lock') ?? false;
  }

  static Future<void> setBiometricLockEnabled(bool enabled) async {
    await init();
    await _prefs?.setBool('pref_biometric_lock', enabled);
  }

  /// Default Commission Split preference (PRD Sec 4.5.1 & 12, defaults to '50 / 50')
  static String getDefaultCommissionSplit() {
    return _prefs?.getString('pref_default_commission_split') ?? '50 / 50';
  }

  static Future<void> setDefaultCommissionSplit(String split) async {
    await init();
    await _prefs?.setString('pref_default_commission_split', split);
  }

  /// Default Sales Commission Rate preference (PRD Sec 7.5, defaults to '2.0%')
  static String getDefaultCommissionRate() {
    return _prefs?.getString('pref_default_commission_rate') ?? '2.0%';
  }

  static Future<void> setDefaultCommissionRate(String rate) async {
    await init();
    await _prefs?.setString('pref_default_commission_rate', rate);
  }

  /// Default Rental Commission preference (PRD Sec 7.5, defaults to '1 Month Rent')
  static String getDefaultRentalCommission() {
    return _prefs?.getString('pref_default_rental_commission') ?? '1 Month Rent';
  }

  static Future<void> setDefaultRentalCommission(String rate) async {
    await init();
    await _prefs?.setString('pref_default_rental_commission', rate);
  }
}

