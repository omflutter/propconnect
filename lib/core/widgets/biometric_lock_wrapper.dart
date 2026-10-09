import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/network/api_service.dart';
import 'package:propconnect/core/routing/app_router.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';
import 'package:propconnect/core/services/biometric_service.dart';

/// Top-level wrapper widget that intercepts app lifecycle to lock/unlock screen
class BiometricLockWrapper extends StatefulWidget {
  final Widget child;

  const BiometricLockWrapper({super.key, required this.child});

  @override
  State<BiometricLockWrapper> createState() => _BiometricLockWrapperState();
}

class _BiometricLockWrapperState extends State<BiometricLockWrapper> with WidgetsBindingObserver {
  final BiometricService _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // If app started in locked state, prompt unlock on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_biometricService.isAppLocked.value) {
        _biometricService.triggerUnlockChallenge();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _biometricService.lockApp();
    } else if (state == AppLifecycleState.resumed) {
      if (_biometricService.isAppLocked.value) {
        _biometricService.triggerUnlockChallenge();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _biometricService.isAppLocked,
      builder: (context, isLocked, _) {
        return Stack(
          children: [
            widget.child,
            if (isLocked)
              const Positioned.fill(
                child: BiometricLockView(),
              ),
          ],
        );
      },
    );
  }
}

/// Standalone Fullscreen Biometric Lock View
class BiometricLockView extends StatefulWidget {
  const BiometricLockView({super.key});

  @override
  State<BiometricLockView> createState() => _BiometricLockViewState();
}

class _BiometricLockViewState extends State<BiometricLockView> {
  bool _isProcessing = false;

  Future<void> _handleUnlock() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await BiometricService().triggerUnlockChallenge();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out? You will need your password or phone OTP to sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.post('/auth/logout', {}).timeout(const Duration(seconds: 1));
      } catch (_) {}
      await AuthStorageService.clearSession();
      BiometricService().unlockApp();
      AppRouter.router.go(AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // App Brand / Lock Icon badge
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryBlueLight, AppColors.primaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const Gap(32),

              const Text(
                'PropConnect is Locked',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(12),

              const Text(
                'Biometric screen lock is enabled to protect your CRM listings, clients, and deal pipeline.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),

              // Unlock Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _handleUnlock,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.fingerprint_rounded, size: 24, color: Colors.white),
                  label: Text(
                    _isProcessing ? 'Verifying...' : 'Unlock with Device Lock',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const Gap(16),

              // Sign Out option
              TextButton(
                onPressed: _handleLogout,
                child: const Text(
                  'Sign out of account',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
