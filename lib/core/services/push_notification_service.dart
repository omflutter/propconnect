import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
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

  /// ValueNotifier tracking whether notification permission is granted
  final ValueNotifier<bool> isPermissionGrantedNotifier = ValueNotifier<bool>(false);

  /// Has the service been initialized
  bool _isInitialized = false;

  /// Initialize Firebase Cloud Messaging listeners & foreground options
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      // 1. Register background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 2. Configure iOS / macOS foreground notification presentation options
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Check current permission status
      await checkPermissionStatus();

      // 4. Obtain initial FCM Device Token if permission already granted or on Android
      await _fetchAndRegisterToken();

      // 5. Listen for Token Refreshes
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] Token refreshed: $newToken');
        _currentToken = newToken;
        syncTokenWithBackend();
      });

      // 6. Foreground Message Listener (PRD Sec 17)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM Foreground] Got message: ${message.notification?.title} - ${message.notification?.body}');
        onMessageReceivedStream.add(message);
        _showForegroundInAppAlert(message);
      });

      // 7. Handle notification click when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM OpenedApp] User tapped notification: ${message.data}');
        _handleNotificationNavigation(message);
      });

      // 8. Check if app was opened from a terminated state via a notification
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FCM InitialMessage] App launched from notification: ${initialMessage.data}');
        Future.delayed(const Duration(milliseconds: 800), () {
          _handleNotificationNavigation(initialMessage);
        });
      }
    } catch (e) {
      debugPrint('[FCM Init Error] $e');
    }
  }

  /// Check whether notification permission is granted
  Future<bool> checkPermissionStatus() async {
    try {
      if (kIsWeb) {
        final settings = await FirebaseMessaging.instance.getNotificationSettings();
        final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
        isPermissionGrantedNotifier.value = granted;
        return granted;
      }

      final status = await Permission.notification.status;
      final granted = status.isGranted;
      isPermissionGrantedNotifier.value = granted;
      return granted;
    } catch (e) {
      debugPrint('[FCM Permission Check Error] $e');
      return false;
    }
  }

  /// Request Notification Permissions explicitly from OS (iOS & Android 13+ POST_NOTIFICATIONS)
  Future<bool> requestNotificationPermission({
    BuildContext? context,
    bool showSettingsIfDenied = true,
  }) async {
    try {
      debugPrint('[FCM] Requesting notification permission...');
      
      // 1. Request via permission_handler for Android 13+ POST_NOTIFICATIONS & iOS
      if (!kIsWeb) {
        final currentStatus = await Permission.notification.status;
        
        if (currentStatus.isPermanentlyDenied) {
          debugPrint('[FCM] Notification permission permanently denied.');
          if (showSettingsIfDenied && context != null && context.mounted) {
            _showSettingsDialog(context);
          }
          isPermissionGrantedNotifier.value = false;
          return false;
        }

        final status = await Permission.notification.request();
        if (status.isPermanentlyDenied) {
          if (showSettingsIfDenied && context != null && context.mounted) {
            _showSettingsDialog(context);
          }
          isPermissionGrantedNotifier.value = false;
          return false;
        }
      }

      // 2. Request via Firebase Messaging instance
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final isGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      debugPrint('[FCM] Notification authorization result: ${settings.authorizationStatus}, granted=$isGranted');
      isPermissionGrantedNotifier.value = isGranted;

      if (isGranted) {
        await _fetchAndRegisterToken();
      }

      return isGranted;
    } catch (e) {
      debugPrint('[FCM Request Permission Error] $e');
      return false;
    }
  }

  /// Check permission and gracefully prompt on first launch or Home dashboard mount
  Future<void> checkAndPromptOnFirstLaunch({required BuildContext context}) async {
    final granted = await checkPermissionStatus();
    if (!granted && context.mounted) {
      // Delay slightly for smooth page entrance transition
      await Future.delayed(const Duration(milliseconds: 600));
      if (context.mounted) {
        await requestNotificationPermission(context: context, showSettingsIfDenied: false);
      }
    }
  }

  /// Retrieve FCM device registration token
  Future<void> _fetchAndRegisterToken() async {
    try {
      _currentToken = await FirebaseMessaging.instance.getToken();
      debugPrint('[FCM] Device Token: $_currentToken');
      if (_currentToken != null && _currentToken!.isNotEmpty) {
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
        debugPrint('[FCM] Token synced with PostgreSQL backend: ${res['success']}');
      } catch (e) {
        debugPrint('[FCM] Failed to sync token with backend: $e');
      }
    }
  }

  /// Show an In-App notification banner for foreground alerts
  void _showForegroundInAppAlert(RemoteMessage message) {
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null) return;

    final title = message.notification?.title ?? message.data['title'] ?? 'New Notification';
    final body = message.notification?.body ?? message.data['message'] ?? '';
    final actionRoute = message.data['actionRoute'] as String?;

    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: AppColors.surface,
        elevation: 8,
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active, color: AppColors.primaryBlue, size: 22),
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
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      body,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.3,
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
    final type = message.data['type'] as String?;

    if (actionRoute != null && actionRoute.isNotEmpty) {
      _navigate(actionRoute);
      return;
    }

    // Default route mapping based on PRD Sec 17 notification types
    switch (type) {
      case 'chat':
        _navigate(AppRouter.chat);
        break;
      case 'collaboration':
        _navigate(AppRouter.collaborations);
        break;
      case 'deal':
        _navigate(AppRouter.deals);
        break;
      case 'commission':
        _navigate(AppRouter.commissions);
        break;
      case 'property':
        _navigate(AppRouter.properties);
        break;
      default:
        _navigate(AppRouter.notifications);
        break;
    }
  }

  void _navigate(String route) {
    try {
      AppRouter.router.push(route);
    } catch (e) {
      debugPrint('[FCM Navigation Error] Could not navigate to $route: $e');
    }
  }

  /// Show user-friendly dialog prompting to enable notifications in device settings
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.notifications_off_outlined, color: AppColors.primaryBlue, size: 24),
            SizedBox(width: 8),
            Text('Enable Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Notifications are currently disabled. Enable them in your device settings to get instant updates on deals, co-broking collaboration requests, and buyer leads.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Not Now', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              openAppSettings();
            },
            child: const Text('Open Settings', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
