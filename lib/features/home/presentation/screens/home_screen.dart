import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/providers/data_providers.dart';
import 'package:propconnect/core/providers/user_role_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedAgency = 'Sunrise Properties';

  void _showAgencyPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Select Agency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.business),
                title: const Text('Sunrise Properties'),
                trailing: _selectedAgency == 'Sunrise Properties' ? const Icon(Icons.check, color: AppColors.primaryBlue) : null,
                onTap: () {
                  setState(() => _selectedAgency = 'Sunrise Properties');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.business_center),
                title: const Text('Global Real Estate'),
                trailing: _selectedAgency == 'Global Real Estate' ? const Icon(Icons.check, color: AppColors.primaryBlue) : null,
                onTap: () {
                  setState(() => _selectedAgency = 'Global Real Estate');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userRole = ref.watch(userRoleProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(context, userRole),
      body: SafeArea(
        child: CustomScrollView(
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
            _buildSectionTitle(context, 'Deal Pipeline', 'View All', onTap: () => context.go('/deals')),
            _buildDealPipeline(context, ref),
            const SliverToBoxAdapter(child: Gap(32)),
            _buildSectionTitle(context, 'Recent Deals', 'View All', onTap: () => context.go('/deals')),
            _buildRecentDeals(context, ref),
            SliverToBoxAdapter(child: const Gap(40)),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
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
          icon: const Badge(
            label: Text('5'),
            child: Icon(Icons.chat_bubble_outline, color: AppColors.textPrimary),
          ),
          onPressed: () => context.push('/chat'),
        ),
        IconButton(
          icon: const Badge(
            label: Text('12'),
            child: Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
          ),
          onPressed: () => context.push('/notifications'),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, UserRole role) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.8),
              child: const Text('AV', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Good Morning,', style: Theme.of(context).textTheme.bodyMedium),
                  Text('Amit Verma', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    role == UserRole.agencyAdmin ? 'Agency Admin' : 'Broker / Agent', 
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primaryBlue)
                  ),
                ],
              ),
            ),
            if (role == UserRole.agencyAdmin)
              GestureDetector(
                onTap: _showAgencyPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.business_outlined, size: 16, color: AppColors.textPrimary),
                      const Gap(8),
                      Text(
                        _selectedAgency.length > 15 ? '${_selectedAgency.substring(0, 12)}...' : _selectedAgency, 
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)
                      ),
                      const Gap(4),
                      const Icon(Icons.keyboard_arrow_down, size: 16),
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
    final properties = ref.watch(propertyProvider);
    final deals = ref.watch(dealProvider);
    
    // Calculate values based on role
    int myPropertiesCount = 0;
    int publicPropertiesCount = properties.where((p) => p.isPublic).length;
    int requestsCount = deals.where((d) => d.isRequest).length;
    int activeDealsCount = deals.where((d) => !d.isRequest).length;

    List<Map<String, dynamic>> metrics = [];

    if (role == UserRole.agencyAdmin) {
      myPropertiesCount = properties.where((p) => p.agencyName == 'Sunrise Properties').length;
      metrics = [
        {'title': 'Agency Properties', 'value': myPropertiesCount.toString(), 'icon': Icons.home_outlined, 'color': Colors.blue},
        {'title': 'Total Commission', 'value': '₹24.8L', 'icon': Icons.currency_rupee, 'color': Colors.red},
        {'title': 'Active Brokers', 'value': '5', 'icon': Icons.group, 'color': Colors.teal},
        {'title': 'Agency Deals', 'value': activeDealsCount.toString(), 'icon': Icons.description_outlined, 'color': Colors.orange},
        {'title': 'Public Listings', 'value': publicPropertiesCount.toString(), 'icon': Icons.public, 'color': Colors.green},
        {'title': 'Requests', 'value': requestsCount.toString(), 'icon': Icons.handshake_outlined, 'color': Colors.purple},
      ];
    } else {
      myPropertiesCount = properties.length ~/ 2; // Mocking specific broker properties
      metrics = [
        {'title': 'My Properties', 'value': myPropertiesCount.toString(), 'icon': Icons.home_outlined, 'color': Colors.blue},
        {'title': 'My Deals', 'value': activeDealsCount.toString(), 'icon': Icons.description_outlined, 'color': Colors.orange},
        {'title': 'My Commission', 'value': '₹6.5L', 'icon': Icons.currency_rupee, 'color': Colors.red},
        {'title': 'Collab Requests', 'value': requestsCount.toString(), 'icon': Icons.handshake_outlined, 'color': Colors.purple},
        {'title': 'Active Leads', 'value': '12', 'icon': Icons.person_outline, 'color': Colors.lightGreen},
        {'title': 'Public Search', 'value': publicPropertiesCount.toString(), 'icon': Icons.search, 'color': Colors.teal},
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
                  context.go('/deals');
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
    final requests = ref.watch(dealProvider).where((d) => d.isRequest).toList();

    if (requests.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('No pending requests.'),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final req = requests[index];
          return GestureDetector(
            onTap: () => context.go('/collaborations'),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.orange.withValues(alpha: 0.2),
                    child: Text(req.partnerBroker.substring(0, 2).toUpperCase(), style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(req.partnerBroker, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Broker', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(req.propertyName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        const Text('Requested today', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => ref.read(dealProvider.notifier).updateDealStatus(req.id, 'Approved'),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(4)),
                          child: const Icon(Icons.check, color: Colors.green, size: 16),
                        ),
                      ),
                      const Gap(8),
                      GestureDetector(
                        onTap: () => ref.read(dealProvider.notifier).updateDealStatus(req.id, 'Rejected'),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(border: Border.all(color: Colors.red), borderRadius: BorderRadius.circular(4)),
                          child: const Icon(Icons.close, color: Colors.red, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        childCount: requests.length > 3 ? 3 : requests.length, // Show max 3 on home screen
      ),
    );
  }

  Widget _buildDealPipeline(BuildContext context, WidgetRef ref) {
    final activeDeals = ref.watch(dealProvider).where((d) => !d.isRequest).toList();
    
    final siteVisits = activeDeals.where((d) => d.status.contains('Site Visit')).length;
    final negotiation = activeDeals.where((d) => d.status.contains('Negotiation')).length;
    final token = activeDeals.where((d) => d.status.contains('Token')).length;
    final agreement = activeDeals.where((d) => d.status.contains('Agreement')).length;
    final registry = activeDeals.where((d) => d.status.contains('Registry')).length;

    final stages = [
      {'name': 'Site Visit\nScheduled', 'count': siteVisits.toString(), 'icon': Icons.calendar_today, 'color': Colors.blue},
      {'name': 'Negotiation', 'count': negotiation.toString(), 'icon': Icons.handshake, 'color': Colors.purple},
      {'name': 'Token\nGenerated', 'count': token.toString(), 'icon': Icons.receipt, 'color': Colors.orange},
      {'name': 'Agreement\nSigned', 'count': agreement.toString(), 'icon': Icons.draw, 'color': Colors.green},
      {'name': 'Registry\nCompleted', 'count': registry.toString(), 'icon': Icons.home, 'color': Colors.teal},
    ];

    return SliverToBoxAdapter(
      child: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: stages.length,
          separatorBuilder: (context, index) => Container(
            width: 30,
            alignment: Alignment.center,
            child: const Divider(color: AppColors.border, thickness: 2),
          ),
          itemBuilder: (context, index) {
            final stage = stages[index];
            final color = stage['color'] as Color;
            return GestureDetector(
              onTap: () => context.go('/deals'),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(stage['icon'] as IconData, color: color, size: 20),
                  ),
                  const Gap(8),
                  Text(
                    stage['name'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, height: 1.1),
                  ),
                  const Gap(4),
                  Text(
                    stage['count'] as String,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
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
    final deals = ref.watch(dealProvider).where((d) => !d.isRequest).toList();

    if (deals.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('No active deals.'),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final deal = deals[index];
          // Assign color based on status roughly
          Color statusColor = Colors.purple;
          if (deal.status.contains('Token') || deal.status.contains('Agreement')) statusColor = Colors.green;
          if (deal.status.contains('Site Visit')) statusColor = Colors.blue;

          return GestureDetector(
            onTap: () => context.go('/deals'),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(deal.id, style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const Gap(12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(deal.propertyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text(deal.partnerBroker, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        deal.status,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Row(
                    children: [
                      Text(deal.amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
                    ],
                  ),
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
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20, right: 20),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: const Text('AV', style: TextStyle(color: AppColors.primaryBlue, fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    // ROLE TOGGLE SWITCH
                    Column(
                      children: [
                        Switch(
                          value: role == UserRole.agencyAdmin,
                          onChanged: (val) {
                            ref.read(userRoleProvider.notifier).toggleRole();
                          },
                          activeThumbColor: Colors.white,
                          activeTrackColor: Colors.teal.shade300,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.white30,
                        ),
                        Text(
                          role == UserRole.agencyAdmin ? 'Admin View' : 'Broker View',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const Gap(16),
                const Text('Amit Verma', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('amit@sunriseproperties.in', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const Gap(8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    role == UserRole.agencyAdmin ? 'Agency Admin' : 'Broker', 
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
                _buildDrawerItem(context, Icons.person, 'My Profile', false, route: '/profile'),
                
                // Admin Only Options
                if (role == UserRole.agencyAdmin) ...[
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
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out of your account?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              Navigator.pop(context); // close dialog
              context.go('/login'); // clear stack and go to login
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
