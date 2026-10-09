import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/network/api_service.dart';
import 'package:propconnect/core/routing/app_router.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  bool _isLoading = true;
  String _referralCode = '';
  int _coinsBalance = 0;
  int _referralCount = 0;
  List<Map<String, dynamic>> _referralsList = [];

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    final userData = AuthStorageService.getUserData();
    final agencyMap = userData?['agency'] as Map<String, dynamic>?;
    final agencyId = userData?['agencyId'] ?? agencyMap?['id'];
    final fallbackCode = agencyMap?['agencyCode'] ?? userData?['agencyCode'] ?? 'AG-001';
    final fallbackCoins = (agencyMap?['coinsBalance'] as num?)?.toInt() ?? 0;
    final fallbackCount = (agencyMap?['referralCount'] as num?)?.toInt() ?? 0;

    setState(() {
      _referralCode = (agencyMap?['referralCode'] as String?) ?? fallbackCode;
      _coinsBalance = fallbackCoins;
      _referralCount = fallbackCount;
    });

    if (agencyId != null) {
      try {
        final res = await ApiService.get('/agencies/$agencyId/referral');
        if (mounted && res['success'] == true && res['data'] != null) {
          final data = res['data'] as Map<String, dynamic>;
          final rawList = data['referrals'] as List? ?? [];

          setState(() {
            _referralCode = data['referralCode']?.toString() ?? _referralCode;
            _coinsBalance = (data['coinsBalance'] as num?)?.toInt() ?? _coinsBalance;
            _referralCount = (data['referralCount'] as num?)?.toInt() ?? _referralCount;
            _referralsList = rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            _isLoading = false;
          });

          // Update local session cache
          if (agencyMap != null) {
            agencyMap['referralCode'] = _referralCode;
            agencyMap['coinsBalance'] = _coinsBalance;
            agencyMap['referralCount'] = _referralCount;
            userData?['agency'] = agencyMap;
            await AuthStorageService.updateUserData(userData ?? {});
          }
          return;
        }
      } catch (err) {
        debugPrint('[ReferralScreen] Error fetching referral stats: $err');
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Referral code "$_referralCode" copied to clipboard!'),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareReferral() {
    final shareText =
        'Join PropConnect India — the verified B2B co-broking platform for real estate agencies!\n\n'
        'Use my agency referral code: $_referralCode to receive 500 PropCoins welcome bonus.\n\n'
        'Sign up now: https://propconnect-b89bd.web.app/register';

    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Referral invite link copied! Share via WhatsApp or SMS.'),
        backgroundColor: AppColors.primaryBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Refer & Earn (PropCoins)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 14)),
                const Gap(4),
                Text(
                  '$_coinsBalance Coins',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReferralData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeroReferralCard(),
                  const Gap(16),
                  _buildCoinsBalanceCard(),
                  const Gap(16),
                  _buildStatsRow(),
                  const Gap(24),
                  _buildHowItWorksCard(),
                  const Gap(24),
                  _buildReferralsHistorySection(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroReferralCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 24),
              ),
              const Gap(12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agency Referral Program',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Earn 1,000 PropCoins for every agency joining',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(20),
          const Text(
            'YOUR AGENCY REFERRAL CODE',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.8),
          ),
          const Gap(8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _referralCode.isNotEmpty ? _referralCode : 'PROP-AGENCY',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: AppColors.primaryBlue),
                  tooltip: 'Copy Code',
                  onPressed: _copyToClipboard,
                ),
              ],
            ),
          ),
          const Gap(16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareReferral,
                  icon: const Icon(Icons.share_rounded, size: 18, color: Colors.white),
                  label: const Text('Share Invite Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const Gap(10),
              ElevatedButton.icon(
                onPressed: _copyToClipboard,
                icon: const Icon(Icons.content_copy_rounded, size: 18, color: Colors.white),
                label: const Text('Copy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoinsBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: [
          BoxShadow(color: Colors.amber.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('🪙', style: TextStyle(fontSize: 28)),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$_coinsBalance PropCoins',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
                    ),
                    const Gap(6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '≈ ₹$_coinsBalance INR',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                      ),
                    ),
                  ],
                ),
                const Gap(3),
                const Text(
                  '1 PropCoin = ₹1. Redeemable on any SaaS membership!',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Gap(6),
          ElevatedButton(
            onPressed: () => context.push(AppRouter.subscription),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Redeem', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem('Agencies Referred', '$_referralCount', Icons.people_outline_rounded, const Color(0xFF3B82F6)),
        ),
        const Gap(12),
        Expanded(
          child: _buildStatItem('Coins Earned', '${_referralCount * 1000}', Icons.monetization_on_outlined, const Color(0xFFF59E0B)),
        ),
        const Gap(12),
        Expanded(
          child: _buildStatItem('SaaS Savings', '₹${_referralCount * 1000}', Icons.savings_outlined, const Color(0xFF10B981)),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const Gap(6),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const Gap(2),
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How Referral Coins Work', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const Gap(16),
          _buildStepRow(1, 'Share your code', 'Give your referral code to fellow real estate agency admins or partner brokerages.'),
          const Gap(14),
          _buildStepRow(2, 'They join & get bonus', 'When they onboard with your code, they get 500 bonus PropCoins immediately!'),
          const Gap(14),
          _buildStepRow(3, 'You get 1,000 PropCoins', '1,000 PropCoins (₹1,000) are instantly credited to your agency wallet for membership purchases.'),
        ],
      ),
    );
  }

  Widget _buildStepRow(int step, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
          child: Text('$step', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
              const Gap(2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReferralsHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Referred Agencies History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const Gap(10),
        if (_referralsList.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.handshake_outlined, size: 36, color: Colors.grey.shade400),
                  const Gap(8),
                  const Text('No agencies referred yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Gap(4),
                  const Text(
                    'Share your code with other agencies to earn your first 1,000 PropCoins!',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ..._referralsList.map((ref) {
            final name = ref['referredAgencyName']?.toString() ?? 'Partner Agency';
            final code = ref['referredAgencyCode']?.toString() ?? '';
            final coins = ref['coinsEarned']?.toString() ?? '1000';
            final dateStr = ref['createdAt']?.toString() ?? '';
            final formattedDate = dateStr.isNotEmpty ? dateStr.split('T').first : 'Recently';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                    child: const Icon(Icons.business_rounded, color: AppColors.primaryBlue, size: 20),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        Text('Joined on $formattedDate • $code', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+$coins 🪙',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF166534)),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
