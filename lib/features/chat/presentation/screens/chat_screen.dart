import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/network/api_service.dart';
import 'package:propconnect/core/providers/data_providers.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';
import 'package:propconnect/core/services/firestore_chat_service.dart';
import 'package:propconnect/core/services/user_presence_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchConversations() async {
    setState(() => _isLoading = true);
    try {
      final userData = AuthStorageService.getUserData();
      final currentUserId = userData?['id']?.toString() ?? '1';
      final res = await ApiService.get('/chat/conversations?userId=$currentUserId');
      if (res['success'] == true && res['data'] != null) {
        final list = (res['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (mounted) {
          setState(() {
            _conversations = list;
            _isLoading = false;
          });
        }
        // Update unread count in provider
        int unreadTotal = 0;
        for (final item in list) {
          unreadTotal += (item['unreadCount'] as num? ?? 0).toInt();
        }
        ref.read(unreadMessagesProvider.notifier).updateCount(unreadTotal);
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _conversations = [];
        _isLoading = false;
      });
    }
  }

  /// Opens a modal showing real registered brokers to start a conversation
  void _showNewChatDialog() async {
    final userData = AuthStorageService.getUserData();
    final currentUserId = userData?['id']?.toString() ?? '1';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String brokerSearch = '';
        List<dynamic> allBrokers = [];
        bool loadingBrokers = true;

        return StatefulBuilder(
          builder: (context, setModalState) {
            if (loadingBrokers) {
              ApiService.get('/brokers').then((res) {
                if (res['success'] == true && res['data'] != null) {
                  final list = (res['data'] as List).where((b) {
                    final bId = b['id']?.toString() ?? '';
                    return bId != currentUserId; // Do not list oneself
                  }).toList();
                  if (ctx.mounted) {
                    setModalState(() {
                      allBrokers = list;
                      loadingBrokers = false;
                    });
                  }
                } else {
                  if (ctx.mounted) {
                    setModalState(() {
                      allBrokers = [];
                      loadingBrokers = false;
                    });
                  }
                }
              }).catchError((_) {
                if (ctx.mounted) {
                  setModalState(() {
                    allBrokers = [];
                    loadingBrokers = false;
                  });
                }
              });
            }

            final filteredBrokers = allBrokers.where((b) {
              final q = brokerSearch.trim().toLowerCase();
              if (q.isEmpty) return true;
              final bName = (b['name'] as String? ?? '').toLowerCase();
              final aName = (b['agency']?['name'] as String? ?? '').toLowerCase();
              return bName.contains(q) || aName.contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Gap(16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Start New Conversation',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Gap(8),
                  const Text(
                    'Select a verified broker to start a direct message thread.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                  const Gap(16),
                  TextField(
                    onChanged: (val) => setModalState(() => brokerSearch = val),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search broker or agency name...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: AppColors.primaryBlue, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: loadingBrokers
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
                        : filteredBrokers.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person_search_outlined, size: 48, color: Colors.grey.shade400),
                                      const Gap(12),
                                      const Text('No Brokers Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      const Gap(4),
                                      const Text('No registered brokers match your search.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filteredBrokers.length,
                                separatorBuilder: (context, index) => const Divider(height: 1, indent: 64),
                                itemBuilder: (context, index) {
                                  final b = filteredBrokers[index];
                                  final bId = b['id']?.toString() ?? '';
                                  final bName = (b['name'] as String?) ?? 'Broker';
                                  final aName = (b['agency']?['name'] as String?) ?? 'Independent Broker';
                                  final role = (b['adminRoleTitle'] as String?) ?? 'Broker';
                                  final initial = bName.isNotEmpty ? bName[0].toUpperCase() : 'B';

                                  return StreamBuilder<Map<String, dynamic>>(
                                    stream: UserPresenceService.streamPresence(bId),
                                    builder: (context, presenceSnap) {
                                      final isOnline = presenceSnap.data?['isOnline'] as bool? ?? false;
                                      final statusText = presenceSnap.data?['statusText'] as String? ?? 'Offline';

                                      return ListTile(
                                        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                        leading: Stack(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                                              child: Text(initial, style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                                            ),
                                            if (isOnline)
                                              Positioned(
                                                bottom: 0,
                                                right: 0,
                                                child: Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration: BoxDecoration(
                                                    color: Colors.green,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: Colors.white, width: 1.5),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        title: Text(bName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                                        subtitle: Row(
                                          children: [
                                            Icon(Icons.circle, color: isOnline ? Colors.green : Colors.grey.shade400, size: 7),
                                            const Gap(4),
                                            Expanded(
                                              child: Text(
                                                '$statusText • $role • $aName',
                                                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          final sorted = [currentUserId, bId]..sort();
                                          final convId = 'conv_${sorted[0]}_${sorted[1]}';
                                          context.push(
                                            '/chat/$convId',
                                            extra: {
                                              'partnerId': bId,
                                              'partnerName': bName,
                                              'agencyName': aName,
                                            },
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userData = AuthStorageService.getUserData();
    final currentUserId = userData?['id']?.toString() ?? '1';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: const Text('Messages', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square, color: AppColors.primaryBlue),
            tooltip: 'New Message',
            onPressed: _showNewChatDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Search conversations...',
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const Divider(height: 1),

          // Real-time Conversation List via Cloud Firestore Stream with PostgreSQL fallback
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreChatService.streamConversations(currentUserId),
              builder: (context, snapshot) {
                List<Map<String, dynamic>> rawList = [];
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  rawList = snapshot.data!;
                } else {
                  rawList = _conversations;
                }

                if (snapshot.connectionState == ConnectionState.waiting && _isLoading && rawList.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
                }

                final filteredList = rawList.where((conv) {
                  final query = _searchQuery.trim().toLowerCase();
                  if (query.isEmpty) return true;
                  final name = (conv['partnerName'] as String?)?.toLowerCase() ?? '';
                  final msg = (conv['lastMessage'] as String?)?.toLowerCase() ?? '';
                  return name.contains(query) || msg.contains(query);
                }).toList();

                return RefreshIndicator(
                  onRefresh: _fetchConversations,
                  color: AppColors.primaryBlue,
                  child: filteredList.isEmpty
                      ? Center(
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
                                  child: const Icon(Icons.forum_outlined, size: 48, color: AppColors.primaryBlue),
                                ),
                                const Gap(16),
                                const Text(
                                  'No Conversations Yet',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const Gap(8),
                                const Text(
                                  'You have not exchanged messages with any partner brokers yet. Connect with brokers to collaborate on properties and deals.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                                ),
                                const Gap(24),
                                ElevatedButton.icon(
                                  onPressed: _showNewChatDialog,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.add_comment_outlined, color: Colors.white, size: 18),
                                  label: const Text('Start a Conversation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filteredList.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, indent: 76),
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            final name = (item['partnerName'] as String?) ?? 'Broker';
                            final lastMsg = (item['lastMessage'] as String?) ?? '';
                            final rawTime = item['lastMessageTime'] as String?;
                            String time = 'Just now';
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
                                          style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 15),
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
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
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
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
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
                                          fontSize: 13,
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
                              ),
                              onTap: () {
                                FirestoreChatService.markConversationAsRead(item['conversationId'], currentUserId);
                                context.push(
                                  '/chat/${item['conversationId']}',
                                  extra: {
                                    'partnerId': item['partnerId'],
                                    'partnerName': item['partnerName'],
                                    'agencyName': item['agencyName'],
                                  },
                                );
                              },
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatDialog,
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }
}
