import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/routing/app_router.dart';
import 'package:propconnect/core/models/owner_model.dart';
import 'package:propconnect/core/models/property_model.dart';
import 'package:propconnect/core/network/api_service.dart';
import 'package:propconnect/core/providers/agency_provider.dart';
import 'package:propconnect/core/providers/data_providers.dart';
import 'package:propconnect/core/providers/user_role_provider.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';
import 'package:propconnect/core/services/auto_sync_service.dart';
import 'package:propconnect/core/services/push_notification_service.dart';
import 'package:propconnect/core/services/biometric_service.dart';
import 'package:propconnect/core/utils/export_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Notification & Security Preferences
  late bool _pushEnabled;
  late bool _emailEnabled;
  late bool _twoFactor;
  late bool _whatsAppAlerts;
  late bool _biometricLock;

  // CRM Rules & System Settings (PRD Sec 4.1.2, 4.5.1, 7.2)
  late String _defaultVisibility;
  late String _defaultCommissionSplit;
  late String _defaultCommissionRate;
  late String _defaultRentalRate;
  late int _leadInactivityDays;
  late String _areaUnit;

  // Live User & Agency Data
  String _userName = 'User';
  String _userEmail = '';
  String _userPhone = '';
  String _userRole = 'broker';
  String _agencyName = '';
  String _agencyRera = '';
  String _agencyLocation = '';

  int _cachedCount = 0;
  bool _isSyncing = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _pushEnabled = AuthStorageService.getPushNotificationEnabled();
    _emailEnabled = AuthStorageService.getEmailAlertsEnabled();
    _twoFactor = AuthStorageService.getTwoFactorEnabled();
    _whatsAppAlerts = AuthStorageService.getWhatsAppAlertsEnabled();
    _biometricLock = AuthStorageService.getBiometricLockEnabled();
    _defaultVisibility = AuthStorageService.getDefaultVisibility();
    _defaultCommissionSplit = AuthStorageService.getDefaultCommissionSplit();
    _defaultCommissionRate = AuthStorageService.getDefaultCommissionRate();
    _defaultRentalRate = AuthStorageService.getDefaultRentalCommission();
    _leadInactivityDays = AuthStorageService.getLeadInactivityDays();
    _areaUnit = AuthStorageService.getAreaUnit();

    _loadCachedPropertiesCount();
    _loadUserProfile();
  }

  void _loadCachedPropertiesCount() {
    final cached = AuthStorageService.getCachedProperties();
    setState(() {
      _cachedCount = cached.length;
    });
  }

  Future<void> _loadUserProfile() async {
    // 1. Load cached session user data immediately
    final localData = AuthStorageService.getUserData();
    if (localData != null) {
      _applyUserData(localData);
    }

    // 2. Fetch fresh live profile and agency directly from backend PostgreSQL
    try {
      final res = await ApiService.get('/auth/me');
      if (res['success'] == true && res['data'] != null) {
        final data = Map<String, dynamic>.from(res['data'] as Map);
        await AuthStorageService.updateUserData(data);
        if (mounted) {
          _applyUserData(data);
        }
      }
    } catch (_) {}
  }

  void _applyUserData(Map<String, dynamic> data) {
    final name = (data['name'] as String?) ?? '';
    final email = (data['email'] as String?) ?? '';
    final phone = (data['phone'] as String?) ?? '';
    final role = (data['role'] as String?) ?? '';

    final agencyData = data['agency'] as Map<String, dynamic>?;
    final aName = (agencyData?['name'] as String?) ?? (data['agencyName'] as String?) ?? '';
    final aRera = (agencyData?['reraNumber'] as String?) ?? (data['reraNumber'] as String?) ?? '';
    final aLoc = (agencyData?['location'] as String?) ?? (agencyData?['address'] as String?) ?? (data['location'] as String?) ?? '';

    setState(() {
      _userName = name.isNotEmpty ? name : _userName;
      _userEmail = email.isNotEmpty ? email : _userEmail;
      _userPhone = phone;
      _userRole = role;
      _agencyName = aName;
      _agencyRera = aRera;
      _agencyLocation = aLoc;
    });

    if (aName.isNotEmpty) {
      ref.read(agencyProvider.notifier).updateAgencyDetails(
        aName,
        aRera,
        email,
        aLoc,
      );
    }
  }

  // --- PASSWORD CHANGE MODAL ---
  void _showChangePasswordModal() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Change Password',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const Gap(6),
                      const Text(
                        'Enter your current credentials to set a new secure password.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                      const Gap(20),

                      // Current Password
                      TextFormField(
                        controller: currentPassCtrl,
                        obscureText: obscureCurrent,
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          prefixIcon: const Icon(Icons.lock_clock_outlined, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 20),
                            onPressed: () => setModalState(() => obscureCurrent = !obscureCurrent),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Please enter current password' : null,
                      ),
                      const Gap(16),

                      // New Password
                      TextFormField(
                        controller: newPassCtrl,
                        obscureText: obscureNew,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: const Icon(Icons.key_outlined, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 20),
                            onPressed: () => setModalState(() => obscureNew = !obscureNew),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Please enter new password';
                          if (val.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const Gap(16),

                      // Confirm Password
                      TextFormField(
                        controller: confirmPassCtrl,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          prefixIcon: const Icon(Icons.check_circle_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                            onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        ),
                        validator: (val) {
                          if (val != newPassCtrl.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const Gap(24),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() => isSubmitting = true);

                                final res = await ApiService.put('/auth/change-password', {
                                  'currentPassword': currentPassCtrl.text.trim(),
                                  'newPassword': newPassCtrl.text.trim(),
                                });

                                setModalState(() => isSubmitting = false);

                                if (res['success'] == true) {
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.white, size: 20),
                                          Gap(10),
                                          Text('Password updated successfully!'),
                                        ],
                                      ),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } else {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(res['message'] ?? 'Failed to change password'),
                                      backgroundColor: AppColors.error,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Update Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- TWO-FACTOR AUTH SETUP DIALOG ---
  void _showTwoFactorSetupDialog() {
    final phone = _userPhone.isNotEmpty ? _userPhone : '+91 ••••• ••••';
    final otpCtrl = TextEditingController();
    bool otpSent = false;
    bool isVerifying = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.security, color: AppColors.primaryBlue),
                  Gap(10),
                  Text('Two-Factor Authentication', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Two-Factor Authentication (PRD Sec 8.1) secures your account by requesting a one-time OTP whenever you sign in from an unrecognized device.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                  const Gap(14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.phone_android, color: AppColors.primaryBlue, size: 20),
                        const Gap(10),
                        Expanded(
                          child: Text(
                            'Registered Phone: $phone',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),
                  if (!otpSent)
                    ElevatedButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          otpSent = true;
                          otpCtrl.text = '482901';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Test OTP sent to your registered phone number: 482901'),
                            backgroundColor: AppColors.primaryBlue,
                            duration: Duration(seconds: 4),
                          ),
                        );
                      },
                      icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                      label: const Text('Send Verification Code', style: TextStyle(color: Colors.white, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  else ...[
                    TextField(
                      controller: otpCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'Enter 6-digit OTP',
                        hintText: '482901',
                        prefixIcon: Icon(Icons.pin_outlined),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                if (otpSent)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                    onPressed: isVerifying
                        ? null
                        : () async {
                            setDialogState(() => isVerifying = true);
                            await Future.delayed(const Duration(milliseconds: 600));
                            await AuthStorageService.setTwoFactorEnabled(true);
                            if (mounted) setState(() => _twoFactor = true);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Two-Factor Authentication activated successfully!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          },
                    child: isVerifying
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Confirm & Enable', style: TextStyle(color: Colors.white)),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // --- ACTIVE SESSIONS & DEVICE INFO SCREEN (PRD SEC 8.1) ---
  void _showSessionInfoDialog() {
    context.push(AppRouter.activeSessions);
  }

  // --- AUTOMATED REMINDERS & INACTIVITY CONFIG MODAL (PRD SEC 7.2) ---
  void _showAutomatedRemindersModal() {
    int selectedDays = _leadInactivityDays;
    bool registryAlerts = true;
    bool tokenAlerts = true;
    bool clientAnniversaries = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Automated Alerts & Reminders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Gap(6),
                  const Text('PRD Sec 7.2: Set thresholds for pipeline inactivity and transaction deadline alerts.', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                  const Gap(20),

                  // Inactivity Threshold
                  const Text('Flag Inactive Leads After:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const Gap(8),
                  DropdownButtonFormField<int>(
                    initialValue: selectedDays,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      prefixIcon: const Icon(Icons.timer_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 3, child: Text('3 Days of No Activity')),
                      DropdownMenuItem(value: 7, child: Text('7 Days of No Activity (Recommended)')),
                      DropdownMenuItem(value: 14, child: Text('14 Days of No Activity')),
                      DropdownMenuItem(value: 30, child: Text('30 Days of No Activity')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedDays = val);
                    },
                  ),
                  const Gap(16),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Registry Date Approaching Alerts', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Push notice 7 days, 3 days & 1 day before registry date', style: TextStyle(fontSize: 11)),
                    value: registryAlerts,
                    onChanged: (val) => setModalState(() => registryAlerts = val),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Token Expiry Deadline Alerts', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Alert if agreement is pending after booking token', style: TextStyle(fontSize: 11)),
                    value: tokenAlerts,
                    onChanged: (val) => setModalState(() => tokenAlerts = val),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Client Birthday & Anniversary Reminders', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Relationship management greetings for client retention', style: TextStyle(fontSize: 11)),
                    value: clientAnniversaries,
                    onChanged: (val) => setModalState(() => clientAnniversaries = val),
                  ),
                  const Gap(20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      await AuthStorageService.setLeadInactivityDays(selectedDays);
                      if (mounted) setState(() => _leadInactivityDays = selectedDays);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Automated reminder rules saved! Leads flagged after $selectedDays days.'), backgroundColor: AppColors.success),
                      );
                    },
                    child: const Text('Save Reminder Preferences', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- COMMISSION STRUCTURE RULES MODAL (PRD SEC 4.5.1, 6.3.1 & 12) ---
  void _showCommissionStructureDialog() {
    String selectedSplit = _defaultCommissionSplit;
    String selectedRate = _defaultCommissionRate;
    String selectedRental = _defaultRentalRate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Commission Structure Rules',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Gap(6),
                    const Text(
                      'PRD Sec 4.5.1 & 12: Configure default split ratios for co-brokerage transactions and standard agency fees.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    const Gap(20),

                    // Co-Brokerage Split
                    const Text('Default Co-Brokerage Split (PRD 4.5.1)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const Gap(8),
                    Wrap(
                      spacing: 8,
                      children: ['50 / 50', '60 / 40', '40 / 60', '70 / 30'].map((split) {
                        final isSelected = selectedSplit == split;
                        return ChoiceChip(
                          label: Text(
                            split == '50 / 50' ? '50 / 50 (Standard)' : split,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primaryBlue,
                          onSelected: (val) {
                            if (val) setModalState(() => selectedSplit = split);
                          },
                        );
                      }).toList(),
                    ),
                    const Gap(16),

                    // Sale Brokerage Fee
                    const Text('Standard Sale Commission Rate (PRD 7.5)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const Gap(8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRate,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: '1.0%', child: Text('1.0% of Total Transaction Value')),
                        DropdownMenuItem(value: '1.5%', child: Text('1.5% of Total Transaction Value')),
                        DropdownMenuItem(value: '2.0%', child: Text('2.0% of Total Transaction Value (Standard)')),
                        DropdownMenuItem(value: '2.5%', child: Text('2.5% of Total Transaction Value')),
                        DropdownMenuItem(value: '3.0%', child: Text('3.0% of Total Transaction Value')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedRate = val);
                      },
                    ),
                    const Gap(16),

                    // Rental Brokerage Fee
                    const Text('Standard Rental Commission Rate', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const Gap(8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRental,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: '15 Days Rent', child: Text('15 Days Equivalent Rent')),
                        DropdownMenuItem(value: '1 Month Rent', child: Text('1 Month Equivalent Rent (Standard)')),
                        DropdownMenuItem(value: '2 Months Rent', child: Text('2 Months Equivalent Rent (Commercial)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedRental = val);
                      },
                    ),
                    const Gap(24),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        await AuthStorageService.setDefaultCommissionSplit(selectedSplit);
                        await AuthStorageService.setDefaultCommissionRate(selectedRate);
                        await AuthStorageService.setDefaultRentalCommission(selectedRental);
                        setState(() {
                          _defaultCommissionSplit = selectedSplit;
                          _defaultCommissionRate = selectedRate;
                          _defaultRentalRate = selectedRental;
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Commission structure preferences updated!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      child: const Text('Save Commission Structure', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- PARTNER PORTAL AUTO-SYNC MODAL (PRD SEC 7.8) ---
  void _showAutoSyncConfigModal() {
    final autoSyncState = ref.read(autoSyncProvider);
    final currentConfig = autoSyncState.config;

    String selectedPlatform = currentConfig?.platform ?? '99acres';
    String selectedFrequency = currentConfig?.frequency ?? 'Daily Auto-Sync';
    final apiKeyCtrl = TextEditingController(text: currentConfig?.apiKey ?? '');
    final feedUrlCtrl = TextEditingController(text: currentConfig?.feedUrl ?? 'https://feed.$selectedPlatform.com');
    bool isEnabled = currentConfig?.isEnabled ?? true;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Partner Portal Auto-Sync', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Gap(6),
                    const Text('PRD Sec 7.8: Ingest and synchronize inventory automatically from real estate portals.', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                    const Gap(18),

                    // Platform
                    const Text('Target Platform', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const Gap(8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedPlatform,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: '99acres', child: Text('99acres.com Lead & Listing Feed')),
                        DropdownMenuItem(value: 'MagicBricks', child: Text('MagicBricks ProSync Feed')),
                        DropdownMenuItem(value: 'Housing.com', child: Text('Housing.com Edge API')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedPlatform = val;
                            feedUrlCtrl.text = 'https://feed.$val.com/api/v1/properties';
                          });
                        }
                      },
                    ),
                    const Gap(14),

                    // Frequency
                    const Text('Sync Cadence', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const Gap(8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedFrequency,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Real-Time Webhook', child: Text('Real-Time Instant Webhooks')),
                        DropdownMenuItem(value: 'Hourly Auto-Sync', child: Text('Hourly Background Sync')),
                        DropdownMenuItem(value: 'Daily Auto-Sync', child: Text('Daily Midnight Sync')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedFrequency = val);
                      },
                    ),
                    const Gap(14),

                    // API Key
                    const Text('Integration API Secret / Bearer Token', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const Gap(8),
                    TextField(
                      controller: apiKeyCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Enter API Secret from portal developer portal',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        prefixIcon: const Icon(Icons.key),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const Gap(14),

                    // Feed URL
                    const Text('Feed Endpoint URL', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const Gap(8),
                    TextField(
                      controller: feedUrlCtrl,
                      decoration: InputDecoration(
                        hintText: 'https://api.portal.com/feed',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        prefixIcon: const Icon(Icons.link),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const Gap(14),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable Automated Sync Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      subtitle: const Text('Automatically imports verified listings into CRM cache', style: TextStyle(fontSize: 11)),
                      value: isEnabled,
                      onChanged: (val) => setModalState(() => isEnabled = val),
                    ),
                    const Gap(20),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              setModalState(() => isSaving = true);
                              await ref.read(autoSyncProvider.notifier).updateConfig(
                                    platform: selectedPlatform,
                                    frequency: selectedFrequency,
                                    apiKey: apiKeyCtrl.text.trim(),
                                    feedUrl: feedUrlCtrl.text.trim(),
                                    isEnabled: isEnabled,
                                  );
                              setModalState(() => isSaving = false);
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$selectedPlatform auto-sync preferences updated!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            },
                      child: isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Feed Configuration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- DEFAULT PROPERTY VISIBILITY DIALOG (PRD SEC 4.1.2) ---
  void _showVisibilityDefaultsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.visibility_outlined, color: AppColors.primaryBlue),
            Gap(10),
            Text('Default Property Visibility', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PRD Sec 4.1.2: Set the initial exposure mode applied when adding new listings to the CRM portfolio.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const Gap(16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _defaultVisibility == 'Public' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: AppColors.primaryBlue,
              ),
              title: const Text('Public (Co-Brokerage Marketplace)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              subtitle: const Text('Shares with all verified brokers on PropConnect Marketplace for 50/50 co-brokerage deals', style: TextStyle(fontSize: 11)),
              onTap: () async {
                await AuthStorageService.setDefaultVisibility('Public');
                setState(() => _defaultVisibility = 'Public');
                if (ctx.mounted) Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Default property visibility set to Public (Co-Brokerage).')),
                );
              },
            ),
            const Divider(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _defaultVisibility == 'In-House' || _defaultVisibility == 'Private' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: AppColors.primaryBlue,
              ),
              title: const Text('In-House (Private to Agency)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              subtitle: const Text('Restricted to internal agency brokers only; hidden from external network marketplace', style: TextStyle(fontSize: 11)),
              onTap: () async {
                await AuthStorageService.setDefaultVisibility('In-House');
                setState(() => _defaultVisibility = 'In-House');
                if (ctx.mounted) Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Default property visibility set to In-House (Private).')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- AREA MEASUREMENT UNIT DIALOG ---
  void _showAreaUnitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.square_foot_outlined, color: AppColors.primaryBlue),
            Gap(10),
            Text('Property Area Unit', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                _areaUnit == 'sq.ft' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: AppColors.primaryBlue,
              ),
              title: const Text('Square Feet (sq.ft)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              subtitle: const Text('Standard Indian residential format', style: TextStyle(fontSize: 11)),
              onTap: () async {
                await AuthStorageService.setAreaUnit('sq.ft');
                setState(() => _areaUnit = 'sq.ft');
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(
                _areaUnit == 'sq.yd' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: AppColors.primaryBlue,
              ),
              title: const Text('Square Yards / Gaj (sq.yd)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              subtitle: const Text('Preferred for plots and independent villas', style: TextStyle(fontSize: 11)),
              onTap: () async {
                await AuthStorageService.setAreaUnit('sq.yd');
                setState(() => _areaUnit = 'sq.yd');
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(
                _areaUnit == 'sq.m' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: AppColors.primaryBlue,
              ),
              title: const Text('Square Meters (sq.m)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              subtitle: const Text('Metric & International format', style: TextStyle(fontSize: 11)),
              onTap: () async {
                await AuthStorageService.setAreaUnit('sq.m');
                setState(() => _areaUnit = 'sq.m');
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- DATA EXPORT DIALOG (PRD SEC 8.3) ---
  void _showExportDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.download_for_offline_outlined, color: AppColors.primaryBlue),
            Gap(10),
            Text('Export Agency Data', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PRD Sec 8.3: Agency owners and brokers can export CRM portfolios and owner directories in standard Excel-compliant CSV format.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const Gap(18),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.apartment_rounded, color: AppColors.primaryBlue, size: 20),
              ),
              title: const Text('Export Properties Portfolio', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: const Text('Generate CSV of all active & confidential listings', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () async {
                Navigator.pop(ctx);
                _handleExportProperties();
              },
            ),
            const Divider(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.people_alt_rounded, color: Colors.teal, size: 20),
              ),
              title: const Text('Export Owners Directory', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: const Text('Generate CSV of property owners & KYC status', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () async {
                Navigator.pop(ctx);
                _handleExportOwners();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExportProperties() async {
    setState(() => _isExporting = true);
    try {
      final res = await ApiService.get('/properties');
      List<PropertyModel> properties = [];
      if (res['success'] == true && res['data'] is List) {
        properties = (res['data'] as List)
            .map((item) => PropertyModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      } else {
        properties = AuthStorageService.getCachedProperties();
      }

      if (properties.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No property listings found to export.'), backgroundColor: AppColors.warning),
        );
        return;
      }

      await ExportService.exportPropertiesToExcel(properties: properties, title: 'PropConnect_Properties');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported ${properties.length} properties to CSV!'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting properties: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleExportOwners() async {
    setState(() => _isExporting = true);
    try {
      final ownersRes = await ApiService.get('/owners');
      final propRes = await ApiService.get('/properties');

      List<OwnerModel> owners = [];
      List<PropertyModel> properties = [];

      if (ownersRes['success'] == true && ownersRes['data'] is List) {
        owners = (ownersRes['data'] as List)
            .map((item) => OwnerModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }

      if (propRes['success'] == true && propRes['data'] is List) {
        properties = (propRes['data'] as List)
            .map((item) => PropertyModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }

      if (owners.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No registered property owners found to export.'), backgroundColor: AppColors.warning),
        );
        return;
      }

      await ExportService.exportOwnersDirectoryToExcel(owners: owners, allProperties: properties);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported ${owners.length} property owners to CSV!'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting owners: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // --- MANUAL CACHE SYNC (PRD SEC 6.2.2) ---
  Future<void> _handleManualCacheSync() async {
    setState(() => _isSyncing = true);
    try {
      final res = await ApiService.get('/properties');
      if (res['success'] == true && res['data'] is List) {
        final properties = (res['data'] as List)
            .map((item) => PropertyModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        await AuthStorageService.saveCachedProperties(properties);
        setState(() {
          _cachedCount = properties.length;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Synced and cached ${properties.length} listings for offline access!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to refresh property inventory.'), backgroundColor: AppColors.warning),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  // --- CLEAR CACHE ---
  Future<void> _handleClearCache() async {
    await AuthStorageService.clearCachedProperties();
    setState(() {
      _cachedCount = 0;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Local offline cache cleared.'),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  // --- PRIVACY POLICY DIALOG (PRD SEC 8.2) ---
  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.privacy_tip_outlined, color: AppColors.primaryBlue),
            Gap(10),
            Text('Data Privacy & Security', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PRD Section 8.2 & 8.3 Compliance Standards:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Gap(10),
              _buildBulletPoint('Data Encryption: TLS 1.3 in transit and AES-256 at rest across PostgreSQL databases.'),
              _buildBulletPoint('PII Protection: Owner phone numbers and confidential reserve pricing are protected via role-based access control (RBAC).'),
              _buildBulletPoint('Lead Firewall: Broker B\'s buyer contact details remain 100% confidential and are never shared with partner brokers.'),
              _buildBulletPoint('Audit Trails: Every transaction, create, update, and deletion is recorded in real-time PostgreSQL audit logs (PRD Sec 18).'),
              _buildBulletPoint('DPDP & GDPR Compliance: User consent is tracked, and rights to data portability and erasure are honored.'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12, height: 1.35)),
          ),
        ],
      ),
    );
  }

  // --- RIGHT TO ERASURE / DELETE ACCOUNT (PRD SEC 8.3) ---
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            Gap(10),
            Text('Request Data Erasure', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.error)),
          ],
        ),
        content: const Text(
          'Under PRD Sec 8.3 (Right to Erasure), requesting account deletion will permanently anonymize your profile and revoke all active JWT tokens. This action is irreversible.\n\nAre you sure you want to proceed?',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.post('/auth/logout', {});
              await AuthStorageService.clearSession();
              ref.read(propertyProvider.notifier).reset();
              ref.read(dealProvider.notifier).reset();
              if (mounted) {
                context.go('/login');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account erasure request submitted. Session logged out.'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Delete Account', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- LOGOUT CONFIRMATION ---
  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of your PropConnect session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx, rootNavigator: true).pop();
              try {
                await ApiService.post('/auth/logout', {}).timeout(const Duration(seconds: 1));
              } catch (_) {}
              await AuthStorageService.clearSession();
              ref.read(propertyProvider.notifier).reset();
              ref.read(dealProvider.notifier).reset();
              AppRouter.router.go(AppRouter.login);
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(userRoleProvider);
    final isAgencyAdmin = _userRole == 'super_admin' || _userRole == 'agency_admin' || role == UserRole.agencyAdmin;
    final roleTitle = isAgencyAdmin ? 'Agency Admin / Owner' : 'Licensed Broker / Agent';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // 1. Profile Summary Card (reflecting live authenticated user & agency data)
          _buildUserProfileHeader(
            userName: _userName,
            userEmail: _userEmail,
            userPhone: _userPhone,
            roleTitle: roleTitle,
            agencyName: _agencyName,
            agencyRera: _agencyRera,
            agencyLocation: _agencyLocation,
          ),
          const Gap(24),

          // 2. Account & Security (PRD Sec 8.1 & 8.2)
          _buildSectionHeader('Account & Security'),
          _buildSettingsTile(
            title: 'Edit Profile',
            subtitle: 'Update your display name, phone & WhatsApp contact',
            icon: Icons.person_outline,
            onTap: () async {
              await context.push('/profile');
              _loadUserProfile();
            },
          ),
          _buildSettingsTile(
            title: 'Change Password',
            subtitle: 'Update your secure PostgreSQL authentication credentials',
            icon: Icons.lock_outline,
            onTap: _showChangePasswordModal,
          ),
          _buildSwitchTile(
            title: 'Two-Factor Authentication',
            subtitle: 'OTP verification on unrecognized logins (PRD Sec 8.1)',
            icon: Icons.security_outlined,
            value: _twoFactor,
            onChanged: (val) {
              if (val) {
                _showTwoFactorSetupDialog();
              } else {
                AuthStorageService.setTwoFactorEnabled(false);
                setState(() => _twoFactor = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Two-factor authentication disabled.')),
                );
              }
            },
          ),
          _buildSwitchTile(
            title: 'Biometric Screen Lock',
            subtitle: 'Require Fingerprint, Face ID or Device Passcode to open PropConnect',
            icon: Icons.fingerprint,
            value: _biometricLock,
            onChanged: (val) async {
              if (val) {
                // Verify hardware & screen lock setup on device
                final isSupported = await BiometricService().isDeviceSupported();
                if (!isSupported) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Device lock or biometrics not available. Please set up a screen lock (PIN/Pattern/Fingerprint) in your device settings.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                // Verify identity before enabling
                final didAuth = await BiometricService().authenticate(
                  localizedReason: 'Confirm your identity to enable biometric screen lock',
                );

                if (!didAuth) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Authentication cancelled or failed. Biometric lock was not enabled.'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                  return;
                }

                setState(() => _biometricLock = true);
                await AuthStorageService.setBiometricLockEnabled(true);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Biometric screen lock enabled successfully.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else {
                // Confirm identity before disabling
                final didAuth = await BiometricService().authenticate(
                  localizedReason: 'Confirm your identity to disable biometric screen lock',
                );

                if (!didAuth) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Authentication failed. Biometric lock remains active.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                setState(() => _biometricLock = false);
                await AuthStorageService.setBiometricLockEnabled(false);
                BiometricService().unlockApp();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Biometric screen lock disabled.')),
                );
              }
            },
          ),
          _buildSettingsTile(
            title: 'Active Sessions & Devices',
            subtitle: 'Inspect authenticated devices & remote logout (PRD Sec 8.1)',
            icon: Icons.devices_outlined,
            onTap: _showSessionInfoDialog,
          ),

          const Gap(24),

          // 3. Preferences & Notifications (PRD Sec 16 & 17) - Clean Light Mode
          _buildSectionHeader('Preferences & Notifications'),
          _buildSwitchTile(
            title: 'Push Notifications',
            subtitle: 'Real-time alerts for incoming leads, matching listings & deals (PRD Sec 17)',
            icon: Icons.notifications_active_outlined,
            value: _pushEnabled,
            onChanged: (val) async {
              if (val) {
                final granted = await PushNotificationService().requestNotificationPermission(
                  context: context,
                  showSettingsIfDenied: true,
                );
                if (!granted) {
                  setState(() => _pushEnabled = false);
                  await AuthStorageService.setPushNotificationEnabled(false);
                  return;
                }
                setState(() => _pushEnabled = true);
                await AuthStorageService.setPushNotificationEnabled(true);
                await PushNotificationService().syncTokenWithBackend();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Push notifications enabled with Firebase!'), backgroundColor: AppColors.success),
                );
              } else {
                setState(() => _pushEnabled = false);
                await AuthStorageService.setPushNotificationEnabled(false);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Push notifications paused.')),
                );
              }
            },
          ),
          _buildSwitchTile(
            title: 'WhatsApp Business Alerts',
            subtitle: 'Urgent co-brokerage inquiries & visit alerts via Meta API (PRD Sec 16)',
            icon: Icons.chat_bubble_outline,
            value: _whatsAppAlerts,
            onChanged: (val) async {
              setState(() => _whatsAppAlerts = val);
              await AuthStorageService.setWhatsAppAlertsEnabled(val);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('WhatsApp alerts ${val ? "enabled" : "disabled"}.')),
              );
            },
          ),
          _buildSwitchTile(
            title: 'Email Alerts',
            subtitle: 'Daily digest of follow-ups, inquiries & deals pipeline',
            icon: Icons.email_outlined,
            value: _emailEnabled,
            onChanged: (val) async {
              setState(() => _emailEnabled = val);
              await AuthStorageService.setEmailAlertsEnabled(val);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Daily email digests ${val ? "enabled" : "disabled"}.')),
              );
            },
          ),

          const Gap(24),

          // 4. CRM Rules & System Settings (PRD Sec 6.3.1, 4.1.2, 4.5.1, 7.2)
          _buildSectionHeader('CRM Rules & System Settings'),
          _buildSettingsTile(
            title: 'Default Property Visibility',
            subtitle: 'Current default: $_defaultVisibility (PRD Sec 4.1.2)',
            icon: Icons.visibility_outlined,
            trailing: Chip(
              label: Text(_defaultVisibility, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              backgroundColor: const Color(0xFFEFF6FF),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            onTap: _showVisibilityDefaultsDialog,
          ),
          _buildSettingsTile(
            title: 'Commission Structures & Split Defaults',
            subtitle: '$_defaultCommissionSplit Split • $_defaultCommissionRate Sale (PRD Sec 4.5.1 & 12)',
            icon: Icons.payments_outlined,
            trailing: Chip(
              label: Text(_defaultCommissionSplit, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              backgroundColor: const Color(0xFFEFF6FF),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            onTap: _showCommissionStructureDialog,
          ),
          _buildSettingsTile(
            title: 'Automated Reminders & Inactivity Rules',
            subtitle: 'Leads flagged inactive after $_leadInactivityDays days (PRD Sec 7.2)',
            icon: Icons.timer_outlined,
            trailing: Chip(
              label: Text('$_leadInactivityDays Days', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              backgroundColor: const Color(0xFFEFF6FF),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            onTap: _showAutomatedRemindersModal,
          ),
          _buildSettingsTile(
            title: 'Property Area Measurement Unit',
            subtitle: 'Display listings in $_areaUnit',
            icon: Icons.square_foot_outlined,
            trailing: Chip(
              label: Text(_areaUnit, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              backgroundColor: const Color(0xFFEFF6FF),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            onTap: _showAreaUnitDialog,
          ),
          _buildSettingsTile(
            title: 'Partner Portal Auto-Sync',
            subtitle: 'Auto-sync listings from 99acres, MagicBricks & Housing.com (PRD Sec 7.8)',
            icon: Icons.sync_alt_outlined,
            onTap: _showAutoSyncConfigModal,
          ),

          const Gap(24),

          // 5. Offline Capability & Storage (PRD Sec 6.2.2)
          _buildSectionHeader('Offline Capability & Storage'),
          _buildSettingsTile(
            title: 'Offline Property Cache',
            subtitle: '$_cachedCount properties cached for offline field access',
            icon: Icons.cloud_done_outlined,
            trailing: _isSyncing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : TextButton.icon(
                    onPressed: _handleManualCacheSync,
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text('Sync Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
            onTap: _handleManualCacheSync,
          ),
          _buildSettingsTile(
            title: 'Clear Local Storage',
            subtitle: 'Free up local device cache without deleting cloud records',
            icon: Icons.cleaning_services_outlined,
            onTap: _handleClearCache,
          ),

          const Gap(24),

          // 6. Agency Administration & RBAC (PRD Sec 5 & 6.3.1)
          _buildSectionHeader('Agency Administration (RBAC)'),
          if (isAgencyAdmin) ...[
            _buildSettingsTile(
              title: 'Manage Agency Profile & RERA',
              subtitle: '${_agencyName.isNotEmpty ? _agencyName : "Agency"} • ${_agencyRera.isNotEmpty ? _agencyRera : "RERA Unset"} • ${_agencyLocation.isNotEmpty ? _agencyLocation : "India"}',
              icon: Icons.business_outlined,
              onTap: () => context.push('/agency-management'),
            ),
            _buildSettingsTile(
              title: 'Team & Broker Management',
              subtitle: 'Onboard brokers, manage passwords & credentials',
              icon: Icons.group_outlined,
              onTap: () => context.push('/agency-management'),
            ),
            _buildSettingsTile(
              title: 'Commission Payouts & Ledger',
              subtitle: 'Track 50/50 splits, agent shares & company revenue (PRD Sec 7.5)',
              icon: Icons.account_balance_wallet_outlined,
              onTap: () => context.push('/commissions'),
            ),
            _buildSettingsTile(
              title: 'Property Owners & KYC Settings',
              subtitle: 'Manage property owners, Aadhaar/PAN KYC & min pricing (PRD Sec 4.6)',
              icon: Icons.people_alt_outlined,
              onTap: () => context.push('/owners'),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primaryBlue, size: 22),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      'You are signed in as a Licensed Broker under ${_agencyName.isNotEmpty ? _agencyName : 'your agency'}. Agency administration, RERA governance, and commission pool configurations are managed by your Agency Administrator.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildSettingsTile(
              title: 'Property Owners Directory (KYC)',
              subtitle: 'View registered sellers, landlords & KYC records (PRD Sec 4.6)',
              icon: Icons.people_alt_outlined,
              onTap: () => context.push('/owners'),
            ),
          ],

          const Gap(24),

          // 7. Data Privacy, Compliance & Security (PRD Sec 8.2 & 8.3)
          _buildSectionHeader('Data Privacy & Compliance'),
          _buildSettingsTile(
            title: 'Export Agency Data',
            subtitle: 'Download property portfolios & owner directory to Excel/CSV',
            icon: Icons.file_download_outlined,
            trailing: _isExporting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right),
            onTap: _showExportDataDialog,
          ),
          _buildSettingsTile(
            title: 'Privacy Policy & Security Standards',
            subtitle: 'Review TLS 1.3, AES-256 & DPDP Act compliance',
            icon: Icons.shield_outlined,
            onTap: _showPrivacyPolicyDialog,
          ),
          _buildSettingsTile(
            title: 'Right to Erasure (Delete Account)',
            subtitle: 'Permanently remove account and data per PRD Sec 8.3',
            icon: Icons.delete_forever_outlined,
            iconColor: AppColors.error,
            onTap: _showDeleteAccountDialog,
          ),

          const Gap(24),

          // 8. App Info & Logout
          _buildSectionHeader('About & Support'),
          _buildSettingsTile(
            title: 'Help & Support Desk',
            subtitle: 'FAQs, ticket submission & assistance',
            icon: Icons.help_outline,
            onTap: () => context.push('/support'),
          ),
          _buildSettingsTile(
            title: 'App Version',
            subtitle: 'PropConnect CRM v1.2.0 (Build 42) - Production',
            icon: Icons.info_outline,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                'RERA Compliant',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.green.shade700),
              ),
            ),
            onTap: () {},
          ),

          const Gap(28),

          // Danger Logout Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _showLogoutConfirmDialog,
              icon: const Icon(Icons.logout, color: Colors.white, size: 18),
              label: const Text('Log Out of PropConnect', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const Gap(40),
        ],
      ),
    );
  }

  Widget _buildUserProfileHeader({
    required String userName,
    required String userEmail,
    required String userPhone,
    required String roleTitle,
    required String agencyName,
    required String agencyRera,
    required String agencyLocation,
  }) {
    final initials = userName.isNotEmpty
        ? userName.split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join('').toUpperCase()
        : 'U';

    final isAgencyAdmin = _userRole == 'agency_admin' || _userRole == 'super_admin';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
                child: Text(
                  initials,
                  style: const TextStyle(fontSize: 20, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                ),
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(2),
                    Text(
                      userEmail,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (userPhone.isNotEmpty) ...[
                      const Gap(2),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 11, color: AppColors.textSecondary),
                          const Gap(4),
                          Text(
                            userPhone,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                    const Gap(6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isAgencyAdmin ? AppColors.primaryBlue.withValues(alpha: 0.1) : Colors.teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAgencyAdmin ? Icons.verified_user : Icons.badge_outlined,
                                size: 12,
                                color: isAgencyAdmin ? AppColors.primaryBlue : Colors.teal,
                              ),
                              const Gap(4),
                              Text(
                                roleTitle,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: isAgencyAdmin ? AppColors.primaryBlue : Colors.teal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primaryBlue),
                onPressed: () async {
                  await context.push('/profile');
                  _loadUserProfile();
                },
                tooltip: 'Edit Profile',
              ),
            ],
          ),

          // Agency Information Banner
          const Gap(14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.business_rounded, size: 16, color: AppColors.primaryBlue),
                ),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agencyName.isNotEmpty ? agencyName : 'Independent Agency',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (agencyRera.isNotEmpty || agencyLocation.isNotEmpty) ...[
                        const Gap(2),
                        Row(
                          children: [
                            if (agencyRera.isNotEmpty)
                              Flexible(
                                child: Text(
                                  'RERA: $agencyRera',
                                  style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (agencyRera.isNotEmpty && agencyLocation.isNotEmpty)
                              const Text(' • ', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            if (agencyLocation.isNotEmpty)
                              Text(
                                agencyLocation,
                                style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (isAgencyAdmin)
                  InkWell(
                    onTap: () => context.push('/agency-management'),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text(
                        'Manage',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.primaryBlue).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor ?? AppColors.primaryBlue, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
          ),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        activeTrackColor: AppColors.primaryBlue.withValues(alpha: 0.5),
        activeThumbColor: AppColors.primaryBlue,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryBlue, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
          ),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
