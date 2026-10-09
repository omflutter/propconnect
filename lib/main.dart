import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_preview/device_preview.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:propconnect/firebase_options.dart';
import 'package:propconnect/core/theme/app_theme.dart';
import 'package:propconnect/core/routing/app_router.dart';
import 'package:propconnect/core/constants/app_strings.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';
import 'package:propconnect/core/services/user_presence_service.dart';
import 'package:propconnect/core/services/push_notification_service.dart';
import 'package:propconnect/core/services/biometric_service.dart';
import 'package:propconnect/core/widgets/biometric_lock_wrapper.dart';

import 'package:propconnect/core/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase Cloud Services
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }
  
  // Initialize persistent auth session storage
  await AuthStorageService.init();
  AuthStorageService.loadSessionIntoServices();

  // Track real-time presence (Online / Offline)
  UserPresenceService().init();

  // PRD Sec 17: Initialize Push Notifications & FCM Device Permissions
  PushNotificationService().initialize();

  // Initialize Biometric Screen Lock State
  BiometricService().init();

  // DevicePreview is only enabled for Web development preview, disabled on mobile devices (Android / iOS)
  final bool enableDevicePreview = kIsWeb && !kReleaseMode;

  runApp(
    ProviderScope(
      child: DevicePreview(
        enabled: enableDevicePreview,
        builder: (context) => PropConnectApp(useDevicePreview: enableDevicePreview),
      ),
    ),
  );
}

class PropConnectApp extends ConsumerWidget {
  final bool useDevicePreview;

  const PropConnectApp({super.key, this.useDevicePreview = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
      locale: useDevicePreview ? DevicePreview.locale(context) : null,
      builder: (context, child) {
        final previewChild = useDevicePreview ? DevicePreview.appBuilder(context, child) : child;
        return BiometricLockWrapper(child: previewChild ?? const SizedBox.shrink());
      },
    );
  }
}

