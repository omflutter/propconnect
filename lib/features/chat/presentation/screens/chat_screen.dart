import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/models/property_model.dart';
import 'package:propconnect/core/models/deal_model.dart';
import 'package:propconnect/core/network/api_service.dart';
import 'package:propconnect/core/providers/data_providers.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';
import 'package:propconnect/core/services/firestore_chat_service.dart';
import 'package:propconnect/core/services/user_presence_service.dart';
import 'package:propconnect/core/providers/user_role_provider.dart';

/// Chat types as per PRD Section 11:
/// - direct   : one-to-one between two brokers
/// - property : conversation anchored to a specific property listing (including active deal inquiries)
enum _ChatTab { all, direct, property }

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _conversations = [];
  _ChatTab _activeTab = _ChatTab.all;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _activeTab = _ChatTab.values[_tabController.index];
        });
      }
    });
    _fetchConversations();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchConversations() async {
    setState(() => _isLoading = true);
    try {
      final userData = AuthStorageService.getUserData();
      final currentUserId = userData?['id']?.toString() ?? '';
      if (currentUserId.isEmpty) {
        if (mounted) setState(() { _conversations = []; _isLoading = false; });
        return;
      }
      final res = await ApiService.get('/chat/conversations?userId=$currentUserId');
      if (res['success'] == true && res['data'] != null) {
        final list = (res['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (mounted) {
          setState(() {
            _conversations = list;
            _isLoading = false;
          });
        }
        int unreadTotal = 0;
        for (final item in list) {
          unreadTotal += (item['unreadCount'] as num? ?? 0).toInt();
        }
        ref.read(unreadMessagesProvider.notifier).updateCount(unreadTotal);
        return;
      }
    } catch (_) {}
    if (mounted) setState(() { _conversations = []; _isLoading = false; });
  }

  /// Decide the chat type of a conversation entry.
  /// PRD: Conversations are either 1-to-1 direct or property-anchored (including deal discussions).
  _ChatTab _inferChatType(Map<String, dynamic> conv) {
    final explicitType = conv['chatType']?.toString().toLowerCase();
    if (explicitType == 'direct') return _ChatTab.direct;
    if (explicitType == 'property' || explicitType == 'deal') return _ChatTab.property;

    final convId = conv['conversationId']?.toString() ?? '';
    final propertyId = conv['propertyId']?.toString() ?? '';
    final dealId = conv['dealId']?.toString() ?? '';

    if (convId.contains('_deal_') || convId.startsWith('deal_') || dealId.isNotEmpty) {
      return _ChatTab.property;
    }

    final parts = convId.split('_');
    if (convId.startsWith('prop_') || propertyId.isNotEmpty || (parts.length >= 4 && parts[0] == 'conv')) {
      return _ChatTab.property;
    }

    return _ChatTab.direct;
  }

  List<Map<String, dynamic>> _filterConversations(
      List<Map<String, dynamic>> rawList, String currentUserId) {
    final isBroker = AuthStorageService.getUserRole() == UserRole.broker;
    final rawAssigned = AuthStorageService.getUserData()?['assignedPropertyIds'] ??
        (AuthStorageService.getUserData()?['permissions'] is Map
            ? AuthStorageService.getUserData()!['permissions']['assignedPropertyIds']
            : null);
    final assignedIds = <String>{};
    if (rawAssigned is List) {
      for (final id in rawAssigned) {
        if (id != null) assignedIds.add(id.toString());
      }
    }

    final accessibleProps = ref.watch(accessiblePropertiesProvider);
    for (final p in accessibleProps) {
      if (p.id.isNotEmpty) assignedIds.add(p.id);
    }

    final accessibleDeals = ref.watch(accessibleDealsProvider);
    final accessibleDealIds = <String>{};
    for (final d in accessibleDeals) {
      if (d.id.isNotEmpty) accessibleDealIds.add(d.id);
      if (d.propertyId.isNotEmpty) assignedIds.add(d.propertyId);
    }

    return rawList.where((conv) {
      final convId = conv['conversationId']?.toString() ?? '';
      final chatType = _inferChatType(conv);

      // Broker RBAC
      if (isBroker) {
        // Direct participation check: must be a participant in ANY conversation shown
        final partnerId = conv['partnerId']?.toString() ?? '';
        final creatorId = conv['creatorId']?.toString() ?? '';
        final participants = conv['participants'];
        final isParticipant = (partnerId.isNotEmpty && partnerId != currentUserId) ||
            creatorId == currentUserId ||
            partnerId == currentUserId ||
            (participants is List && participants.map((e) => e.toString()).contains(currentUserId)) ||
            convId.contains('_$currentUserId') ||
            convId.contains('${currentUserId}_');

        if (!isParticipant) return false;

        // If Property chat: must be in broker's assigned properties or accessible deals
        if (chatType == _ChatTab.property) {
          String? propId = conv['propertyId']?.toString();
          String? dealId = conv['dealId']?.toString();
          if (dealId == null || dealId.isEmpty) {
            if (convId.contains('_deal_')) {
              dealId = convId.split('_deal_')[1];
            } else if (convId.startsWith('deal_')) {
              dealId = convId.replaceFirst('deal_', '');
            }
          }
          if (propId == null || propId.isEmpty) {
            final parts = convId.split('_');
            if (parts.length >= 4 && parts[0] == 'conv' && !convId.contains('_deal_')) {
              propId = parts.sublist(3).join('_');
            } else if (convId.startsWith('prop_')) {
              propId = convId.replaceFirst('prop_', '');
            }
          }
          final isPropAssigned = propId != null && propId.isNotEmpty && assignedIds.contains(propId);
          final isDealAssigned = dealId != null && dealId.isNotEmpty && accessibleDealIds.contains(dealId);
          if (!isPropAssigned && !isDealAssigned && (propId != null || dealId != null)) {
            return false;
          }
        }
      }

      // Tab filter
      if (_activeTab != _ChatTab.all) {
        if (chatType != _activeTab) return false;
      }

      // Search filter
      final query = _searchQuery.trim().toLowerCase();
      if (query.isEmpty) return true;
      final name = (conv['partnerName'] as String?)?.toLowerCase() ?? '';
      final msg = (conv['lastMessage'] as String?)?.toLowerCase() ?? '';
      final propTitle = (conv['propertyTitle'] as String?)?.toLowerCase() ?? '';
      final dealCode = (conv['dealCode'] as String?)?.toLowerCase() ?? '';
      final ctxTitle = (conv['contextTitle'] as String?)?.toLowerCase() ?? '';
      return name.contains(query) ||
          msg.contains(query) ||
          propTitle.contains(query) ||
          dealCode.contains(query) ||
          ctxTitle.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final userData = AuthStorageService.getUserData();
    final currentUserId = userData?['id']?.toString() ?? '';

    if (currentUserId.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildAppBar(),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_outlined, size: 48, color: AppColors.textSecondary),
              Gap(12),
              Text(
                'Please sign in to view your messages',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Search by broker, property, deal...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryBlue, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          // Tabs — All / Direct / Property / Deal (PRD Sec 11)
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryBlue,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primaryBlue,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'All Chats'),
                Tab(text: '1-to-1 Direct'),
                Tab(text: 'Property Chats'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Conversation List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreChatService.streamConversations(currentUserId),
              builder: (context, snapshot) {
                List<Map<String, dynamic>> rawList =
                    snapshot.hasData ? snapshot.data! : _conversations;

                if (snapshot.connectionState == ConnectionState.waiting &&
                    _isLoading &&
                    rawList.isEmpty) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryBlue));
                }

                final filteredList = _filterConversations(rawList, currentUserId);

                return RefreshIndicator(
                  onRefresh: _fetchConversations,
                  color: AppColors.primaryBlue,
                  child: filteredList.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          itemCount: filteredList.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1, indent: 76),
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            return _buildConversationTile(item, currentUserId);
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStartNewChatModal(context, currentUserId),
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add_comment_outlined, color: Colors.white, size: 20),
        label: const Text('New Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      centerTitle: false,
      title: const Text(
        'Broker Communication',
        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  Widget _buildEmptyState() {
    final labels = {
      _ChatTab.all: ('No Active Conversations', 'Start a direct chat with a broker, or message from any property.'),
      _ChatTab.direct: ('No Direct 1-to-1 Chats', 'Tap "New Chat" below to start a private conversation with any registered broker.'),
      _ChatTab.property: ('No Property Chats', 'Open any property listing and tap "Chat" to start a property inquiry or deal discussion.'),
    };
    final (title, subtitle) = labels[_activeTab]!;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _activeTab == _ChatTab.property
                    ? Icons.home_outlined
                    : Icons.forum_outlined,
                size: 48,
                color: AppColors.primaryBlue,
              ),
            ),
            const Gap(16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const Gap(8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const Gap(24),
            ElevatedButton.icon(
              onPressed: () {
                if (_activeTab == _ChatTab.property) {
                  context.go('/properties');
                } else {
                  final userData = AuthStorageService.getUserData();
                  final currentUserId = userData?['id']?.toString() ?? '1';
                  _showStartNewChatModal(context, currentUserId);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(
                _activeTab == _ChatTab.property
                    ? Icons.apartment_outlined
                    : Icons.add_comment_outlined,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                _activeTab == _ChatTab.property
                    ? 'Browse Properties'
                    : 'Start a Chat',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> item, String currentUserId) {
    final name = (item['partnerName'] as String?) ?? 'Broker';
    final lastMsg = (item['lastMessage'] as String?) ?? '';
    final rawTime = item['lastMessageTime'] as String?;
    final chatType = _inferChatType(item);
    final convId = item['conversationId']?.toString() ?? '';

    // Auto-resolve contextTitle, propertyId, dealId if missing
    String? contextTitle = item['contextTitle'] as String?;
    String? propertyId = item['propertyId']?.toString();
    String? dealId = item['dealId']?.toString();

    if (chatType == _ChatTab.property) {
      if (propertyId == null || propertyId.isEmpty) {
        final parts = convId.split('_');
        if (parts.length >= 4 && parts[0] == 'conv') {
          propertyId = parts.sublist(3).join('_');
        }
      }
      if (contextTitle == null || contextTitle.isEmpty) {
        if (propertyId != null && propertyId.isNotEmpty) {
          final props = ref.watch(propertyProvider);
          final prop = props.cast<PropertyModel?>().firstWhere(
            (p) => p != null && p.id == propertyId,
            orElse: () => null,
          );
          if (prop != null) {
            contextTitle = prop.title;
          }
        }
      }
      // If dealId exists or legacy convId with _deal_, resolve deal context and property
      if ((contextTitle == null || contextTitle.isEmpty) && (dealId != null || convId.contains('_deal_'))) {
        final dId = dealId ?? convId.split('_deal_').last;
        final deals = ref.watch(dealProvider);
        final deal = deals.cast<DealModel?>().firstWhere(
          (d) => d != null && (d.id == dId || d.dealCode == dId),
          orElse: () => null,
        );
        if (deal != null) {
          contextTitle = deal.propertyName.isNotEmpty ? deal.propertyName : 'Property Deal #${deal.dealCode.isNotEmpty ? deal.dealCode : deal.id}';
          if (propertyId == null || propertyId.isEmpty) {
            propertyId = deal.propertyId;
          }
        }
      }
    }

    // Format time
    String time = '';
    if (rawTime != null) {
      try {
        final dt = DateTime.parse(rawTime).toLocal();
        final now = DateTime.now();
        if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
          final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
          final m = dt.minute.toString().padLeft(2, '0');
          final ampm = dt.hour >= 12 ? 'PM' : 'AM';
          time = '$h:$m $ampm';
        } else {
          time = '${dt.day}/${dt.month}';
        }
      } catch (_) {}
    }

    final isUnread = (item['isUnread'] as bool?) ?? false;
    final unreadCount = (item['unreadCount'] as int?) ?? 0;
    final initials = name.isNotEmpty
        ? name.split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join('').toUpperCase()
        : 'B';

    const IconData contextIcon = Icons.home_outlined;
    const Color contextColor = Colors.teal;

    return ListTile(
      tileColor: isUnread ? Colors.white : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      leading: StreamBuilder<Map<String, dynamic>>(
        stream: UserPresenceService.streamPresence(item['partnerId']),
        builder: (context, presenceSnap) {
          final isOnline = presenceSnap.data?['isOnline'] as bool? ?? false;
          return Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
                child: Text(
                  initials,
                  style: const TextStyle(
                      color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              if (isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (chatType != _ChatTab.direct) ...[
                  const Gap(6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: contextColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: contextColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(contextIcon, size: 10, color: contextColor),
                        const Gap(3),
                        const Text(
                          'Property',
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: contextColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: isUnread ? AppColors.primaryBlue : AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contextTitle != null && contextTitle.isNotEmpty) ...[
              Row(
                children: [
                  Icon(contextIcon, size: 11, color: contextColor),
                  const Gap(4),
                  Expanded(
                    child: Text(
                      contextTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: contextColor,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(2),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    lastMsg,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                if (isUnread && unreadCount > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      onTap: () async {
        if (convId.isNotEmpty) {
          FirestoreChatService.markConversationAsRead(convId, currentUserId);
          ApiService.put('/chat/read/$convId', {'userId': currentUserId})
              .catchError((_) => <String, dynamic>{});
        }
        setState(() {
          item['isUnread'] = false;
          item['unreadCount'] = 0;
        });

        await context.push(
          '/chat/$convId',
          extra: {
            'partnerId': item['partnerId'],
            'partnerName': item['partnerName'],
            'agencyName': item['agencyName'],
            'chatType': chatType == _ChatTab.property
                ? 'property'
                : 'direct',
            'contextTitle': contextTitle ?? '',
            'propertyId': propertyId ?? '',
            'dealId': dealId ?? '',
          },
        );
        if (mounted) {
          _fetchConversations();
          ref.read(unreadMessagesProvider.notifier).fetchUnreadCount();
        }
      },
    );
  }

  /// Start a Direct 1-to-1 Chat with any platform broker/agent (PRD Section 11)
  void _showStartNewChatModal(BuildContext context, String currentUserId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _NewChatContactsSheet(
          currentUserId: currentUserId,
          onBrokerSelected: (contact) async {
            Navigator.pop(ctx);
            final targetId = contact['id']?.toString() ?? '';
            final targetName = contact['name'] as String? ?? 'Broker';
            final targetAgency = (contact['agency'] is Map ? contact['agency']['name'] : contact['agencyName']) as String? ?? 'Agency';

            final sorted = [currentUserId, targetId]..sort();
            final convId = 'conv_${sorted[0]}_${sorted[1]}';

            await context.push(
              '/chat/$convId',
              extra: {
                'partnerId': targetId,
                'partnerName': targetName,
                'agencyName': targetAgency,
                'chatType': 'direct',
                'contextTitle': 'Direct Broker Communication',
              },
            );

            if (mounted) {
              _fetchConversations();
              ref.read(unreadMessagesProvider.notifier).fetchUnreadCount();
            }
          },
        );
      },
    );
  }
}

/// Contacts sheet for starting 1-to-1 broker chat
class _NewChatContactsSheet extends StatefulWidget {
  final String currentUserId;
  final ValueChanged<Map<String, dynamic>> onBrokerSelected;

  const _NewChatContactsSheet({
    required this.currentUserId,
    required this.onBrokerSelected,
  });

  @override
  State<_NewChatContactsSheet> createState() => _NewChatContactsSheetState();
}

class _NewChatContactsSheetState extends State<_NewChatContactsSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      final res = await ApiService.get('/chat/contacts');
      if (res['success'] == true && res['data'] != null) {
        final list = (res['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((c) => c['id']?.toString() != widget.currentUserId)
            .toList();
        if (mounted) {
          setState(() {
            _contacts = list;
            _isLoading = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _contacts.where((c) {
      if (_query.isEmpty) return true;
      final name = (c['name'] as String?)?.toLowerCase() ?? '';
      final agency = (c['agency'] is Map ? c['agency']['name'] : c['agencyName']) as String? ?? '';
      return name.contains(_query.toLowerCase()) || agency.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person_add_alt_1_outlined, color: AppColors.primaryBlue),
                    Gap(8),
                    Text(
                      'Start New Message',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Text(
              'Select a broker or agency admin to start a 1-to-1 conversation.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const Gap(12),
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: 'Search by broker name or agency...',
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primaryBlue),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const Gap(12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
                  : filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'No brokers found',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (ctx, index) {
                            final c = filtered[index];
                            final name = (c['name'] as String?) ?? 'Broker';
                            final agency = (c['agency'] is Map ? c['agency']['name'] : c['agencyName']) as String? ?? 'Agency';
                            final role = (c['role'] as String?) ?? 'broker';
                            final initial = name.isNotEmpty ? name[0].toUpperCase() : 'B';

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
                                child: Text(
                                  initial,
                                  style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                    ),
                                  ),
                                  if (role == 'agency_admin')
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Admin',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                agency,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                              onTap: () => widget.onBrokerSelected(c),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
