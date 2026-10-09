import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/providers/data_providers.dart';
import 'package:propconnect/core/providers/agency_provider.dart';
import 'package:propconnect/core/providers/user_role_provider.dart';
import 'package:propconnect/core/network/api_service.dart';
import 'package:propconnect/core/routing/app_router.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';
import 'package:propconnect/core/services/push_notification_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.wait([
        ref.read(propertyProvider.notifier).fetchProperties(),
        ref.read(dealProvider.notifier).fetchDeals(),
        ref.read(commissionProvider.notifier).fetchCommissions(),
        ref.read(unreadMessagesProvider.notifier).fetchUnreadCount(),
        ref.read(unreadNotificationsProvider.notifier).fetchUnreadCount(),
        AuthStorageService.refreshSession(),
      ]);
      PushNotificationService().checkAndPromptOnFirstLaunch(context: context);
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning,';
    if (hour >= 12 && hour < 17) return 'Good Afternoon,';
    if (hour >= 17 && hour < 21) return 'Good Evening,';
    return 'Good Night,';
  }


  @override
  Widget build(BuildContext context) {
    final userRole = ref.watch(userRoleProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(context, userRole),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              ref.read(propertyProvider.notifier).fetchProperties(),
              ref.read(dealProvider.notifier).fetchDeals(),
              ref.read(commissionProvider.notifier).fetchCommissions(),
              ref.read(unreadMessagesProvider.notifier).fetchUnreadCount(),
              ref.read(unreadNotificationsProvider.notifier).fetchUnreadCount(),
              AuthStorageService.refreshSession(),
            ]);
          },
          color: AppColors.primaryBlue,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
            _buildAppBar(context),
            SliverToBoxAdapter(child: const Gap(16)),
            _buildHeader(context, userRole),
            SliverToBoxAdapter(child: const Gap(16)),
            _buildSearchBar(context),
            SliverToBoxAdapter(child: const Gap(24)),
            _buildMetricsGrid(context, ref, userRole),
            SliverToBoxAdapter(child: const Gap(24)),
            _buildPromoBanner(context),
            SliverToBoxAdapter(child: const Gap(24)),
            _buildSectionTitle(context, 'Collaboration Requests', 'View All', onTap: () => context.go('/collaborations')),
            _buildCollaborationRequests(context, ref),
            const SliverToBoxAdapter(child: Gap(32)),
            _buildSectionTitle(context, 'Deal Pipeline', 'View All', onTap: () {
              ref.read(selectedDealStageProvider.notifier).setStage('All');
              context.go('/deals?stage=All');
            }),
            _buildDealPipeline(context, ref),
            const SliverToBoxAdapter(child: Gap(32)),
            _buildSectionTitle(context, 'Recent Deals', 'View All', onTap: () {
              ref.read(selectedDealStageProvider.notifier).setStage('All');
              context.go('/deals?stage=All');
            }),
            _buildRecentDeals(context, ref),
            SliverToBoxAdapter(child: const Gap(40)),
          ],
        ),
      ),
    ),
  );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    final unreadMessagesCount = ref.watch(unreadMessagesProvider);
    final unreadNotificationsCount = ref.watch(unreadNotificationsProvider);

    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.textPrimary),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.business, color: AppColors.primaryBlue),
          Gap(8),
          Text(
            'PropConnect',
            style: TextStyle(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: unreadMessagesCount > 0
              ? Badge(
                  label: Text('$unreadMessagesCount'),
                  child: const Icon(Icons.chat_outlined, color: AppColors.textPrimary),
                )
              : const Icon(Icons.chat_outlined, color: AppColors.textPrimary),
          onPressed: () async {
            await context.push('/chat');
            ref.read(unreadMessagesProvider.notifier).fetchUnreadCount();
          },
        ),
        IconButton(
          icon: unreadNotificationsCount > 0
              ? Badge(
                  label: Text('$unreadNotificationsCount'),
                  child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                )
              : const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
          onPressed: () async {
            await context.push('/notifications');
            ref.read(unreadNotificationsProvider.notifier).fetchUnreadCount();
          },
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, UserRole role) {
    final userData = AuthStorageService.getUserData();
    final userName = (userData?['name'] as String?) ?? 'User';
    final rawRole = (userData?['role'] as String?) ?? '';
    final userAgencyName = (userData?['agency']?['name'] as String?) ?? (userData?['agencyName'] as String?) ?? 'My Agency';
    final roleTitle = (userData?['adminRoleTitle'] as String?) ??
        (rawRole == 'super_admin'
            ? 'Super Admin (Full Access)'
            : (role == UserRole.agencyAdmin ? 'Agency Admin' : 'Broker / Agent'));

    final userInitials = userName.trim().isNotEmpty
        ? userName
            .trim()
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map((w) => w[0])
            .take(2)
            .join('')
            .toUpperCase()
        : 'U';

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.8),
              child: Text(userInitials, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getGreeting(), style: Theme.of(context).textTheme.bodyMedium),
                  Text(userName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    roleTitle, 
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primaryBlue)
                  ),
                ],
              ),
            ),
            if (role == UserRole.agencyAdmin)
              GestureDetector(
                onTap: () => context.push('/agency-management'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.08),
                    border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.business, size: 14, color: AppColors.primaryBlue),
                      const Gap(6),
                      Text(
                        userAgencyName.length > 18 ? '${userAgencyName.substring(0, 15)}...' : userAgencyName, 
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)
                      ),
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                readOnly: true,
                onTap: () => context.go('/search'),
                decoration: InputDecoration(
                  hintText: 'Search properties, brokers...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.iconColor),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
            const Gap(12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                onPressed: () => context.go('/search'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, WidgetRef ref, UserRole role) {
    final properties = ref.watch(accessiblePropertiesProvider);
    final allProperties = ref.watch(propertyProvider);
    final isPropertiesLoading = ref.watch(isPropertiesLoadingProvider);
    final deals = ref.watch(accessibleDealsProvider);
    final agency = ref.watch(agencyProvider);
    // Accessible properties strictly respects RBAC & Agency isolation
    final myProperties = properties;

    // Calculate real values based on backend data
    final String propertiesDisplay = (isPropertiesLoading && properties.isEmpty) ? '...' : myProperties.length.toString();
    final String publicPropertiesDisplay = (isPropertiesLoading && properties.isEmpty) ? '...' : myProperties.where((p) => p.isPublic).length.toString();
    final String allPublicDisplay = (isPropertiesLoading && allProperties.isEmpty) ? '...' : allProperties.where((p) => p.isPublic).length.toString();
    int requestsCount = deals.where((d) => d.isRequest).length;
    int activeDealsCount = deals.where((d) => !d.isRequest).length;
    final brokersCount = agency.brokers.length;

    List<Map<String, dynamic>> metrics = [];

    if (role == UserRole.agencyAdmin) {
      metrics = [
        {'title': 'Agency Properties', 'value': propertiesDisplay, 'icon': Icons.home_outlined, 'color': Colors.blue},
        {'title': 'Total Commission', 'value': '₹0', 'icon': Icons.currency_rupee, 'color': Colors.red},
        {'title': 'Active Brokers', 'value': brokersCount.toString(), 'icon': Icons.group, 'color': Colors.teal},
        {'title': 'Agency Deals', 'value': activeDealsCount.toString(), 'icon': Icons.description_outlined, 'color': Colors.orange},
        {'title': 'Public Listings', 'value': publicPropertiesDisplay, 'icon': Icons.public, 'color': Colors.green},
        {'title': 'Requests', 'value': requestsCount.toString(), 'icon': Icons.handshake_outlined, 'color': Colors.purple},
      ];
    } else {
      metrics = [
        {'title': 'My Properties', 'value': propertiesDisplay, 'icon': Icons.home_outlined, 'color': Colors.blue},
        {'title': 'My Deals', 'value': activeDealsCount.toString(), 'icon': Icons.description_outlined, 'color': Colors.orange},
        {'title': 'My Commission', 'value': '₹0', 'icon': Icons.currency_rupee, 'color': Colors.red},
        {'title': 'Collab Requests', 'value': requestsCount.toString(), 'icon': Icons.handshake_outlined, 'color': Colors.purple},
        {'title': 'Active Leads', 'value': '0', 'icon': Icons.person_outline, 'color': Colors.lightGreen},
        {'title': 'Public Search', 'value': allPublicDisplay, 'icon': Icons.search, 'color': Colors.teal},
      ];
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 120,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 110,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final metric = metrics[index];
            final color = metric['color'] as Color;
            return GestureDetector(
              onTap: () {
                if (metric['title']!.contains('Properties')) {
                  context.go('/properties');
                } else if (metric['title']!.contains('Deals')) {
                  ref.read(selectedDealStageProvider.notifier).setStage('All');
                  context.go('/deals?stage=All');
                } else if (metric['title']!.contains('Collab') || metric['title']!.contains('Requests')) {
                  context.push('/collaborations');
                } else if (metric['title']!.contains('Commission')) {
                  context.push('/commissions');
                } else if (metric['title']!.contains('Leads')) {
                  context.push('/leads');
                } else if (metric['title']!.contains('Brokers')) {
                  context.push('/agency-management');
                } else if (metric['title']!.contains('Search')) {
                  context.go('/search');
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(metric['icon'] as IconData, color: color, size: 20),
                    ),
                    const Gap(8),
                    Text(
                      metric['title'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, height: 1.1),
                    ),
                    const Gap(4),
                    Text(
                      metric['value'] as String,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: metrics.length,
        ),
      ),
    );
  }

  Widget _buildPromoBanner(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryBlueLight, AppColors.primaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connect. Collaborate.\nClose More Deals.',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.2),
                    ),
                    const Gap(8),
                    const Text(
                      'Work with trusted brokers and grow your business.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const Gap(16),
                    ElevatedButton(
                      onPressed: () => context.go('/search'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Explore Properties >', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
              const Icon(Icons.hub, color: Colors.white30, size: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, String actionText, {required VoidCallback onTap}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: onTap,
              child: Text(actionText, style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollaborationRequests(BuildContext context, WidgetRef ref) {
    final allRequests = ref.watch(accessibleDealsProvider).where((d) => d.isRequest).toList();

    if (allRequests.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('No active collaboration requests.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
      );
    }

    // Sort: Incoming Pending (Action Required) first, then other incoming, then sent
    final requests = [...allRequests]..sort((a, b) {
      final aPriority = (a.isIncomingRequest && a.status == 'Pending') ? 0 : (a.isIncomingRequest ? 1 : 2);
      final bPriority = (b.isIncomingRequest && b.status == 'Pending') ? 0 : (b.isIncomingRequest ? 1 : 2);
      return aPriority.compareTo(bPriority);
    });

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final req = requests[index];
          final isIncoming = req.isIncomingRequest;
          final isPending = req.status == 'Pending';
          final isApproved = req.status == 'Approved';

          final brokerInitial = req.partnerBroker.trim().isNotEmpty
              ? req.partnerBroker.trim().substring(0, 1).toUpperCase()
              : 'B';

          return GestureDetector(
            onTap: () => context.go('/collaborations'),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isIncoming && isPending ? Colors.orange.shade300 : AppColors.border,
                  width: isIncoming && isPending ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Direction Chip + Status Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Direction Tag
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isIncoming ? const Color(0xFFEFF6FF) : const Color(0xFFFAF5FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isIncoming ? const Color(0xFFBFDBFE) : const Color(0xFFE9D5FF),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
                                size: 11,
                                color: isIncoming ? const Color(0xFF1D4ED8) : const Color(0xFF7E22CE),
                              ),
                              const Gap(4),
                              Flexible(
                                child: Text(
                                  isIncoming
                                      ? 'Incoming from ${req.partnerAgency.isNotEmpty ? req.partnerAgency : 'Partner'}'
                                      : 'Sent to ${req.partnerAgency.isNotEmpty ? req.partnerAgency : 'Partner'}',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: isIncoming ? const Color(0xFF1D4ED8) : const Color(0xFF7E22CE),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Gap(8),
                      // Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isPending
                              ? (isIncoming ? Colors.orange.shade50 : const Color(0xFFFFFBEB))
                              : (isApproved ? Colors.green.shade50 : Colors.red.shade50),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isPending
                                ? (isIncoming ? Colors.orange.shade200 : Colors.amber.shade200)
                                : (isApproved ? Colors.green.shade200 : Colors.red.shade200),
                          ),
                        ),
                        child: Text(
                          isPending
                              ? (isIncoming ? 'Action Required' : 'Awaiting Partner')
                              : (isApproved ? 'Approved' : 'Declined'),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isPending
                                ? (isIncoming ? Colors.orange.shade800 : Colors.amber.shade900)
                                : (isApproved ? Colors.green.shade800 : Colors.red.shade800),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(8),

                  // Middle Row: Avatar + Property Info + Budget
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isIncoming
                            ? Colors.blue.withValues(alpha: 0.12)
                            : Colors.purple.withValues(alpha: 0.12),
                        child: Text(
                          brokerInitial,
                          style: TextStyle(
                            color: isIncoming ? AppColors.primaryBlue : Colors.purple.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              req.propertyName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Gap(2),
                            Text(
                              '${req.partnerBroker} • ${req.partnerAgency}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Gap(8),
                      Text(
                        req.expectedBudget?.isNotEmpty == true
                            ? req.expectedBudget!
                            : (req.amount.isNotEmpty ? req.amount : '₹0'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.primaryBlue),
                      ),
                    ],
                  ),

                  // Bottom Action / Informational Bar
                  const Gap(8),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const Gap(6),
                  if (isIncoming && isPending) ...[
                    // Action Buttons ONLY for Actionable Incoming Pending Requests
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            'Respond to collaboration:',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                ref.read(dealProvider.notifier).respondRequest(req.id, 'reject');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Collaboration ${req.id} Declined.')),
                                );
                              },
                              icon: const Icon(Icons.close, size: 13, color: Colors.red),
                              label: const Text('Decline', style: TextStyle(fontSize: 11.5, color: Colors.red, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.red.shade200),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const Gap(8),
                            ElevatedButton.icon(
                              onPressed: () {
                                ref.read(dealProvider.notifier).respondRequest(req.id, 'approve');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Collaboration ${req.id} Approved! Active deal created.')),
                                );
                              },
                              icon: const Icon(Icons.check, size: 13, color: Colors.white),
                              label: const Text('Approve', style: TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ] else if (!isIncoming) ...[
                    // Outgoing request status notice (NO approve/reject buttons)
                    Row(
                      children: [
                        Icon(
                          isPending
                              ? Icons.schedule
                              : (isApproved ? Icons.check_circle_outline : Icons.cancel_outlined),
                          size: 13,
                          color: isPending
                              ? Colors.amber.shade800
                              : (isApproved ? Colors.green.shade700 : Colors.red.shade700),
                        ),
                        const Gap(5),
                        Expanded(
                          child: Text(
                            isPending
                                ? 'Waiting for ${req.partnerBroker} to review and respond'
                                : (isApproved ? 'Partner accepted! Active in Deal Pipeline' : 'Partner was unable to co-broker on this request'),
                            style: TextStyle(
                              fontSize: 11,
                              color: isPending
                                  ? Colors.amber.shade900
                                  : (isApproved ? Colors.green.shade800 : Colors.red.shade800),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 15, color: AppColors.textSecondary),
                      ],
                    ),
                  ] else ...[
                    // Incoming already responded notice
                    Row(
                      children: [
                        Icon(
                          isApproved ? Icons.check_circle_outline : Icons.cancel_outlined,
                          size: 13,
                          color: isApproved ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                        const Gap(5),
                        Expanded(
                          child: Text(
                            isApproved
                                ? 'You approved this request • Deal active in pipeline'
                                : 'You declined this collaboration request',
                            style: TextStyle(
                              fontSize: 11,
                              color: isApproved ? Colors.green.shade800 : Colors.red.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 15, color: AppColors.textSecondary),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
        childCount: requests.length > 3 ? 3 : requests.length,
      ),
    );
  }

  Widget _buildDealPipeline(BuildContext context, WidgetRef ref) {
    final activeDeals = ref.watch(accessibleDealsProvider).where((d) => !d.isRequest).toList();

    final stages = [
      {
        'name': 'Inquiry',
        'stage': 'Inquiry',
        'count': activeDeals.where((d) => d.normalizedStage == 'Inquiry').length.toString(),
        'icon': Icons.help_outline,
        'color': Colors.indigo,
      },
      {
        'name': 'Site Visit\nScheduled',
        'stage': 'Site Visit',
        'count': activeDeals.where((d) => d.normalizedStage == 'Site Visit').length.toString(),
        'icon': Icons.calendar_today,
        'color': Colors.blue,
      },
      {
        'name': 'Negotiation',
        'stage': 'Negotiation',
        'count': activeDeals.where((d) => d.normalizedStage == 'Negotiation').length.toString(),
        'icon': Icons.handshake,
        'color': Colors.purple,
      },
      {
        'name': 'Token\nGenerated',
        'stage': 'Token / Booking',
        'count': activeDeals.where((d) => d.normalizedStage == 'Token / Booking').length.toString(),
        'icon': Icons.receipt,
        'color': Colors.orange,
      },
      {
        'name': 'Agreement\nSigned',
        'stage': 'Agreement to Sell',
        'count': activeDeals.where((d) => d.normalizedStage == 'Agreement to Sell').length.toString(),
        'icon': Icons.draw,
        'color': Colors.green,
      },
      {
        'name': 'Loan\nProcessing',
        'stage': 'Loan Processing',
        'count': activeDeals.where((d) => d.normalizedStage == 'Loan Processing').length.toString(),
        'icon': Icons.account_balance,
        'color': Colors.deepOrange,
      },
      {
        'name': 'Registry\nCompleted',
        'stage': 'Registry',
        'count': activeDeals.where((d) => d.normalizedStage == 'Registry').length.toString(),
        'icon': Icons.home,
        'color': Colors.teal,
      },
      {
        'name': 'Possession\nHandover',
        'stage': 'Possession',
        'count': activeDeals.where((d) => d.normalizedStage == 'Possession').length.toString(),
        'icon': Icons.key,
        'color': Colors.amber.shade800,
      },
      {
        'name': 'Deal\nClosed',
        'stage': 'Deal Closed',
        'count': activeDeals.where((d) => d.normalizedStage == 'Deal Closed').length.toString(),
        'icon': Icons.check_circle,
        'color': Colors.green.shade800,
      },
    ];

    return SliverToBoxAdapter(
      child: Container(
        height: 105,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: stages.length,
          separatorBuilder: (context, index) => Container(
            width: 24,
            alignment: Alignment.center,
            child: const Divider(color: AppColors.border, thickness: 1.5),
          ),
          itemBuilder: (context, index) {
            final stage = stages[index];
            final color = stage['color'] as Color;
            final count = stage['count'] as String;
            final stageKey = stage['stage'] as String;

            return GestureDetector(
              onTap: () {
                ref.read(selectedDealStageProvider.notifier).setStage(stageKey);
                context.go('/deals?stage=${Uri.encodeComponent(stageKey)}');
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Badge(
                    isLabelVisible: count != '0',
                    label: Text(count, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    backgroundColor: color,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(stage['icon'] as IconData, color: color, size: 20),
                    ),
                  ),
                  const Gap(6),
                  Text(
                    stage['name'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, height: 1.1),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecentDeals(BuildContext context, WidgetRef ref) {
    final deals = ref.watch(accessibleDealsProvider).where((d) => !d.isRequest).toList();

    if (deals.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('No active deals in pipeline.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final deal = deals[index];
          Color statusColor = Colors.purple;
          if (deal.status.contains('Token') || deal.status.contains('Agreement')) statusColor = Colors.green;
          if (deal.status.contains('Site Visit')) statusColor = Colors.blue;

          return GestureDetector(
            onTap: () {
              final stage = deal.normalizedStage;
              ref.read(selectedDealStageProvider.notifier).setStage(stage);
              context.go('/deals?stage=${Uri.encodeComponent(stage)}');
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      deal.dealCode.isNotEmpty ? deal.dealCode : deal.id,
                      style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deal.propertyName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(2),
                        Text(
                          '${deal.partnerBroker} • ${deal.partnerAgency}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Gap(8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        deal.amount.isNotEmpty ? deal.amount : '₹0',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          deal.status,
                          style: TextStyle(color: statusColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Gap(4),
                  const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),
          );
        },
        childCount: deals.length > 3 ? 3 : deals.length,
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, UserRole role) {
    final userData = AuthStorageService.getUserData();
    final userName = (userData?['name'] as String?) ?? 'User';
    final userEmail = (userData?['email'] as String?) ?? '';
    final rawRole = (userData?['role'] as String?) ?? '';
    final roleTitle = (userData?['adminRoleTitle'] as String?) ??
        (rawRole == 'super_admin'
            ? 'Super Admin (Full Access)'
            : (role == UserRole.agencyAdmin ? 'Agency Admin' : 'Broker'));

    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryBlueLight, AppColors.primaryBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.business,
                        size: 32,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                Text(userName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                if (userEmail.isNotEmpty)
                  Text(userEmail, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const Gap(8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    roleTitle, 
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(context, Icons.home, 'Home', true),
                _buildDrawerItem(context, Icons.handshake, 'Collaborations', false, route: '/collaborations'),
                _buildDrawerItem(context, Icons.account_balance_wallet_outlined, 'Settlements', false, route: '/settlements'),
                _buildDrawerItem(context, Icons.card_giftcard_rounded, 'Refer & Earn (Coins)', false, route: '/referral'),
                _buildDrawerItem(context, Icons.person, 'My Profile', false, route: '/profile'),
                
                // Admin Only Options
                if (role == UserRole.agencyAdmin) ...[
                  _buildDrawerItem(context, Icons.people_alt_outlined, 'Property Owners & Settings', false, route: '/owners'),
                  _buildDrawerItem(context, Icons.group, 'Agency & Team Management', false, route: '/agency-management'),
                  _buildDrawerItem(context, Icons.payment, 'Subscription & Billing', false, route: '/subscription'),
                  _buildDrawerItem(context, Icons.bar_chart, 'Reports & Analytics', false, route: '/analytics'),
                ],
                
                const Divider(height: 32),
                _buildDrawerItem(context, Icons.help_outline, 'Help & Support', false, route: '/support'),
                _buildDrawerItem(context, Icons.settings, 'Settings', false, route: '/settings'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: _buildDrawerItem(
              context, 
              Icons.logout, 
              'Logout', 
              false, 
              isDestructive: true,
              onTap: () {
                _scaffoldKey.currentState?.closeDrawer();
                _showLogoutConfirmDialog(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, bool isSelected, {bool isDestructive = false, String? route, VoidCallback? onTap}) {
    Color itemColor = isDestructive ? Colors.red : (isSelected ? AppColors.primaryBlue : AppColors.textPrimary);
    return ListTile(
      leading: Icon(icon, color: itemColor),
      title: Text(
        title,
        style: TextStyle(
          color: itemColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primaryBlue.withValues(alpha: 0.05),
      onTap: onTap ?? () {
        _scaffoldKey.currentState?.closeDrawer();
        if (route != null) {
          context.push(route);
        }
      },
    );
  }

  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out of your account?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx, rootNavigator: true).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              Navigator.of(dialogCtx, rootNavigator: true).pop(); // close dialog
              try {
                await ApiService.post('/auth/logout', {}).timeout(const Duration(seconds: 1));
              } catch (_) {}
              await AuthStorageService.clearSession(); // clear persistent session
              ref.read(propertyProvider.notifier).reset();
              ref.read(dealProvider.notifier).reset();
              AppRouter.router.go(AppRouter.login); // unconditionally navigate to login
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
