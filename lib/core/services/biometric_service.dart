import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';

/// Service managing device biometric & screen lock authentication
class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  /// ValueNotifier indicating whether the app is currently locked behind biometric / device screen lock
  final ValueNotifier<bool> isAppLocked = ValueNotifier<bool>(false);

  bool _isAuthenticating = false;
  bool get isAuthenticating => _isAuthenticating;

  /// Initialize lock state on app start
  void init() {
    AuthStorageService.onSessionCleared = unlockApp;
    if (AuthStorageService.isLoggedIn() && AuthStorageService.getBiometricLockEnabled()) {
      isAppLocked.value = true;
    } else {
      isAppLocked.value = false;
    }
  }

  /// Check whether the device hardware supports biometrics or device credentials (PIN/Pattern/Passcode)
  Future<bool> isDeviceSupported() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException catch (e) {
      debugPrint('[BiometricService] isDeviceSupported error: $e');
      return false;
    } catch (e) {
      debugPrint('[BiometricService] isDeviceSupported unexpected error: $e');
      return false;
    }
  }

  /// Get list of enrolled biometrics on device (e.g. fingerprint, face)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('[BiometricService] getAvailableBiometrics error: $e');
      return [];
    }
  }

  /// Authenticate user via Biometrics (Face ID / Fingerprint) with device PIN/Passcode fallback
  Future<bool> authenticate({
    String localizedReason = 'Please authenticate to access PropConnect',
  }) async {
    if (_isAuthenticating) {
      debugPrint('[BiometricService] Authentication already in progress, skipping duplicate call');
      return false;
    }

    _isAuthenticating = true;
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allows device PIN/Passcode/Pattern fallback
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );

      debugPrint('[BiometricService] Authentication result: $didAuthenticate');
      if (didAuthenticate) {
        isAppLocked.value = false;
      }
      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('[BiometricService] Authentication PlatformException: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[BiometricService] Authentication unexpected error: $e');
      return false;
    } finally {
      _isAuthenticating = false;
    }
  }

  /// Lock the app if user is logged in and biometric lock is enabled
  void lockApp() {
    if (_isAuthenticating) return;
    if (AuthStorageService.isLoggedIn() && AuthStorageService.getBiometricLockEnabled()) {
      if (!isAppLocked.value) {
        debugPrint('[BiometricService] Locking app due to app backgrounding / launch');
        isAppLocked.value = true;
      }
    }
  }

  /// Manually unlock the app (e.g. after successful login or logout)
  void unlockApp() {
    isAppLocked.value = false;
  }

  /// Trigger biometric unlock challenge
  Future<bool> triggerUnlockChallenge() async {
    if (!isAppLocked.value) return true;
    return await authenticate(
      localizedReason: 'Authenticate with Face ID, Fingerprint or Device Passcode to unlock PropConnect',
    );
  }
}
