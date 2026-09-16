import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/routing/app_router.dart';

class AgencyCelebrationDialog extends StatefulWidget {
  final String agencyName;
  final String? agencyCode;
  final String adminName;
  final String? adminEmail;
  final String? location;
  final String? subscriptionTier;
  final int? userQuota;
  final String? reraNumber;
  final String targetRoute;

  const AgencyCelebrationDialog({
    super.key,
    required this.agencyName,
    this.agencyCode,
    required this.adminName,
    this.adminEmail,
    this.location,
    this.subscriptionTier,
    this.userQuota,
    this.reraNumber,
    this.targetRoute = AppRouter.home,
  });

  static Future<void> show({
    required BuildContext context,
    required String agencyName,
    String? agencyCode,
    required String adminName,
    String? adminEmail,
    String? location,
    String? subscriptionTier,
    int? userQuota,
    String? reraNumber,
    String targetRoute = AppRouter.home,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AgencyCelebrationDialog(
        agencyName: agencyName,
        agencyCode: agencyCode,
        adminName: adminName,
        adminEmail: adminEmail,
        location: location,
        subscriptionTier: subscriptionTier,
        userQuota: userQuota,
        reraNumber: reraNumber,
        targetRoute: targetRoute,
      ),
    );
  }

  @override
  State<AgencyCelebrationDialog> createState() => _AgencyCelebrationDialogState();
}

class _AgencyCelebrationDialogState extends State<AgencyCelebrationDialog> {
  late ConfettiController _confettiController;
  Timer? _redirectTimer;
  int _remainingSeconds = 4;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));

    // Launch confetti and start auto-redirect timer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _confettiController.play();
        _startAutoRedirect();
      }
    });
  }

  void _startAutoRedirect() {
    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _proceedToWorkspace();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  void _proceedToWorkspace() {
    _redirectTimer?.cancel();
    if (mounted) {
      Navigator.of(context).pop();
      context.go(widget.targetRoute);
    }
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 20,
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Joyful Welcoming Hero Icon with Ambient Glow
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.celebration_rounded, color: Colors.white, size: 40),
                  ),
                  const Gap(18),

                  // Pill Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 14, color: Color(0xFF059669)),
                        Gap(6),
                        Text(
                          'AGENCY ONBOARDED',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF059669),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(12),

                  // Welcoming Headline
                  const Text(
                    'Welcome to PropConnect! 🎉',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(8),

                  // Warm Personalized Subtitle
                  Text(
                    'Congratulations, ${widget.adminName}!\n"${widget.agencyName}" is now active and ready for co-broking & deal closures.',
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(22),

                  // Clean & Elegant Identity Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.apartment_rounded, color: AppColors.primaryBlue, size: 24),
                        ),
                        const Gap(14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.agencyName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Gap(3),
                              const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                                  Gap(4),
                                  Text(
                                    'Workspace Ready • Principal Admin',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF059669),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(24),

                  // High-Conversion Primary Action
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                        shadowColor: AppColors.primaryBlue.withValues(alpha: 0.35),
                      ),
                      onPressed: _proceedToWorkspace,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Enter Workspace',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Gap(8),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const Gap(14),

                  // Auto-Redirect Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.textSecondary),
                        ),
                      ),
                      const Gap(8),
                      Text(
                        'Redirecting automatically in ${_remainingSeconds}s...',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Confetti Fireworks from Top Center
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirection: pi / 2, // Downwards
          blastDirectionality: BlastDirectionality.explosive,
          maxBlastForce: 25,
          minBlastForce: 8,
          emissionFrequency: 0.05,
          numberOfParticles: 40,
          gravity: 0.25,
          shouldLoop: false,
          colors: const [
            Color(0xFF10B981), // Emerald
            Color(0xFF2563EB), // Royal Blue
            Color(0xFFF59E0B), // Amber Gold
            Color(0xFFEC4899), // Pink
            Color(0xFF8B5CF6), // Purple
            Color(0xFF06B6D4), // Cyan
          ],
        ),
      ],
    );
  }
}
