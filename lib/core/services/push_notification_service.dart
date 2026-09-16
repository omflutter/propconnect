import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/network/api_service.dart';
import 'package:propconnect/core/routing/app_router.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('[FCM Background] Received message: ${message.messageId}, data: ${message.data}');
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  static String? _currentToken;
  static String? get currentToken => _currentToken;

  /// Stream controller to notify UI components (e.g. unread badge) of incoming notifications
  static final StreamController<RemoteMessage> onMessageReceivedStream = StreamController<RemoteMessage>.broadcast();

  /// Initialize Firebase Cloud Messaging & Request Device Permissions
  Future<void> initialize() async {
    try {
      // 1. Register background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 2. Request permission (iOS & Android 13+)
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('[FCM] Notification authorization status: ${settings.authorizationStatus}');

      // 3. Obtain FCM Device Token
      await _fetchAndRegisterToken();

      // 4. Listen for Token Refreshes
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] Token refreshed: $newToken');
        _currentToken = newToken;
        syncTokenWithBackend();
      });

      // 5. Foreground Message Listener (PRD Sec 17)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM Foreground] Got message: ${message.notification?.title} - ${message.notification?.body}');
        onMessageReceivedStream.add(message);
        _showForegroundInAppAlert(message);
      });

      // 6. Handle notification click when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM OpenedApp] User tapped notification: ${message.data}');
        _handleNotificationNavigation(message);
      });

      // 7. Check if app was opened from a terminated state via a notification
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FCM InitialMessage] App launched from notification: ${initialMessage.data}');
        // Delay slightly until router is mounted
        Future.delayed(const Duration(milliseconds: 600), () {
          _handleNotificationNavigation(initialMessage);
        });
      }
    } catch (e) {
      debugPrint('[FCM Init Error] $e');
    }
  }

  /// Retrieve FCM device registration token
  Future<void> _fetchAndRegisterToken() async {
    try {
      if (kIsWeb) {
        // On Web, token requires service worker or VAPID key
        _currentToken = await FirebaseMessaging.instance.getToken();
      } else {
        _currentToken = await FirebaseMessaging.instance.getToken();
      }

      debugPrint('[FCM] Device Token: $_currentToken');
      if (_currentToken != null) {
        await syncTokenWithBackend();
      }
    } catch (e) {
      debugPrint('[FCM Token Fetch Error] $e');
    }
  }

  /// Sync device FCM token with PostgreSQL user profile
  Future<void> syncTokenWithBackend() async {
    if (_currentToken == null || _currentToken!.isEmpty) return;

    final userData = AuthStorageService.getUserData();
    if (userData == null) return;

    final rawId = userData['id'];
    final userId = rawId is int ? rawId : int.tryParse(rawId.toString());

    if (userId != null && userId > 0) {
      try {
        final res = await ApiService.registerFcmToken(
          userId: userId,
          fcmToken: _currentToken!,
        );
        debugPrint('[FCM] Sync with PostgreSQL backend: ${res['success']}');
      } catch (e) {
        debugPrint('[FCM] Failed to sync token with backend: $e');
      }
    }
  }

  /// Show an elegant In-App notification banner for foreground alerts
  void _showForegroundInAppAlert(RemoteMessage message) {
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null) return;

    final title = message.notification?.title ?? message.data['title'] ?? 'New Notification';
    final body = message.notification?.body ?? message.data['message'] ?? '';
    final actionRoute = message.data['actionRoute'] as String?;

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.surface,
        elevation: 6,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active, color: AppColors.primaryBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'View',
          textColor: AppColors.primaryBlue,
          onPressed: () {
            if (actionRoute != null && actionRoute.isNotEmpty) {
              _navigate(actionRoute);
            } else {
              _navigate(AppRouter.notifications);
            }
          },
        ),
      ),
    );
  }

  /// Handle deep linking / navigation on notification tap
  void _handleNotificationNavigation(RemoteMessage message) {
    final actionRoute = message.data['actionRoute'] as String?;
    if (actionRoute != null && actionRoute.isNotEmpty) {
      _navigate(actionRoute);
    } else {
      _navigate(AppRouter.notifications);
    }
  }

  void _navigate(String route) {
    try {
      AppRouter.router.push(route);
    } catch (e) {
      debugPrint('[FCM Navigation Error] Could not navigate to $route: $e');
    }
  }
}
