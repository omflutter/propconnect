import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:propconnect/core/constants/app_colors.dart';
import 'package:propconnect/core/providers/data_providers.dart';
import 'package:propconnect/core/models/property_model.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';
import 'package:propconnect/core/services/firestore_chat_service.dart';
import 'package:propconnect/core/services/user_presence_service.dart';
import 'package:propconnect/core/network/api_service.dart';

class ChatDetailsScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String? partnerName;
  final String? partnerId;
  final String? agencyName;

  const ChatDetailsScreen({
    super.key,
    required this.chatId,
    this.partnerName,
    this.partnerId,
    this.agencyName,
  });

  @override
  ConsumerState<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends ConsumerState<ChatDetailsScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingHistory = true;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    final userData = AuthStorageService.getUserData();
    final currentUserId = userData?['id']?.toString() ?? '1';
    FirestoreChatService.markConversationAsRead(widget.chatId, currentUserId);
    _fetchPostgresHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchPostgresHistory() async {
    try {
      final res = await ApiService.get('/chat/messages/${widget.chatId}');
      if (res['success'] == true && res['data'] != null) {
        final userData = AuthStorageService.getUserData();
        final currentUserId = userData?['id']?.toString() ?? '1';

        final list = (res['data'] as List).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          final senderId = m['senderId']?.toString() ?? '';
          final rawTime = m['createdAt'] as String?;
          String formattedTime = 'Just now';
          if (rawTime != null) {
            try {
              final dt = DateTime.parse(rawTime).toLocal();
              final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
              final minute = dt.minute.toString().padLeft(2, '0');
              final ampm = dt.hour >= 12 ? 'PM' : 'AM';
              formattedTime = '$hour:$minute $ampm';
            } catch (_) {}
          }

          return {
            'id': m['id']?.toString() ?? '',
            'isMe': senderId == currentUserId,
            'text': m['messageText'] ?? '',
            'time': formattedTime,
            'type': m['attachmentType'] ?? 'text',
            'property': m['attachmentData'] != null ? PropertyModel.fromJson(Map<String, dynamic>.from(m['attachmentData'] as Map)) : null,
          };
        }).toList();

        if (mounted) {
          setState(() {
            _messages = list;
            _isLoadingHistory = false;
          });
          _scrollToBottom();
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _messages = [];
        _isLoadingHistory = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage({String type = 'text', Map<String, dynamic>? attachmentData, String? textOverride}) async {
    final text = textOverride ?? _messageController.text.trim();
    if (text.isEmpty && attachmentData == null) return;

    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:$minute $ampm';

    final userData = AuthStorageService.getUserData();
    final currentUserId = userData?['id']?.toString() ?? '1';
    final currentUserName = (userData?['name'] as String?) ?? 'Broker';
    final currentUserAgency = (userData?['agency']?['name'] as String?) ?? (userData?['agencyName'] as String?) ?? 'My Agency';

    final partnerId = widget.partnerId ?? '2';
    final partnerName = widget.partnerName ?? 'Partner Broker';
    final partnerAgency = widget.agencyName ?? 'Partner Agency';

    final newMsg = {
      'isMe': true,
      'text': text.isNotEmpty ? text : (type == 'property' ? 'Shared Property Card' : 'Attachment'),
      'time': timeStr,
      'type': type,
      'property': attachmentData != null && type == 'property' ? PropertyModel.fromJson(attachmentData) : null,
    };

    setState(() {
      _messages.add(newMsg);
      if (textOverride == null) _messageController.clear();
    });
    _scrollToBottom();

    // 1. Write to Cloud Firestore for millisecond real-time sync + dual-sync to PostgreSQL
    await FirestoreChatService.sendMessage(
      conversationId: widget.chatId,
      senderId: currentUserId,
      senderName: currentUserName,
      senderAgency: currentUserAgency,
      receiverId: partnerId,
      receiverName: partnerName,
      receiverAgency: partnerAgency,
      messageText: text.isNotEmpty ? text : (type == 'property' ? 'Shared Property Card' : 'Shared Attachment'),
      attachmentType: type,
      attachmentData: attachmentData,
    );

    ref.read(unreadMessagesProvider.notifier).fetchUnreadCount();
  }

  void _sendPropertyAttachment(PropertyModel property) {
    _sendMessage(
      type: 'property',
      attachmentData: property.toJson(),
      textOverride: 'Check out this property listing: ${property.title}',
    );
  }

  void _showPropertySelectionSheet() {
    final properties = ref.read(propertyProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.house_outlined, color: AppColors.primaryBlue, size: 22),
                      Gap(8),
                      Text('Select Property to Share', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Gap(12),
              Expanded(
                child: properties.isEmpty
                    ? const Center(child: Text('No properties available to share'))
                    : ListView.builder(
                        itemCount: properties.length,
                        itemBuilder: (context, index) {
                          final prop = properties[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: _buildCardImage(
                                      prop.images.isNotEmpty
                                          ? prop.images.first
                                          : 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?q=80&w=300',
                                    ),
                                  ),
                                ),
                                const Gap(12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        prop.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                      ),
                                      const Gap(3),
                                      Text(
                                        '${prop.price} • ${prop.location}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const Gap(10),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context); // close property sheet
                                    Navigator.pop(context); // close attachment menu
                                    _sendPropertyAttachment(prop);
                                  },
                                  icon: const Icon(Icons.send_rounded, size: 14, color: Colors.white),
                                  label: const Text('Share', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAttachmentMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              const Gap(24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttachmentIcon(context, Icons.insert_photo_outlined, 'Gallery', Colors.purple, onTap: () {
                    Navigator.pop(context);
                    _sendMessage(
                      type: 'image',
                      textOverride: '📷 Sent Property Photo Attachment',
                    );
                  }),
                  _buildAttachmentIcon(context, Icons.camera_alt_outlined, 'Camera', Colors.pink, onTap: () {
                    Navigator.pop(context);
                    _sendMessage(
                      type: 'image',
                      textOverride: '📷 Captured Live Property Photo',
                    );
                  }),
                  _buildAttachmentIcon(context, Icons.insert_drive_file_outlined, 'Document', Colors.blue, onTap: () {
                    Navigator.pop(context);
                    _sendMessage(
                      type: 'document',
                      textOverride: '📄 Shared Property Title Deed.pdf',
                    );
                  }),
                ],
              ),
              const Gap(20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttachmentIcon(context, Icons.location_on_outlined, 'Location', Colors.green, onTap: () {
                    Navigator.pop(context);
                    _sendMessage(
                      type: 'location',
                      textOverride: '📍 Shared Location Pin: Bandra West, Mumbai',
                    );
                  }),
                  _buildAttachmentIcon(context, Icons.home_outlined, 'Share Property', Colors.orange, onTap: _showPropertySelectionSheet),
                  const SizedBox(width: 60),
                ],
              ),
              const Gap(16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentIcon(BuildContext context, IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.pop(context),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const Gap(6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildCardImage(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFF1F5F9),
          child: const Center(
            child: Icon(Icons.apartment, size: 36, color: AppColors.primaryBlue),
          ),
        ),
      );
    } else if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFF1F5F9),
          child: const Center(
            child: Icon(Icons.apartment, size: 36, color: AppColors.primaryBlue),
          ),
        ),
      );
    } else {
      return Image.network(
        'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?q=80&w=600',
        fit: BoxFit.cover,
      );
    }
  }

  Widget _buildPropertyAttachmentCard(PropertyModel prop, bool isMe) {
    final imageSrc = prop.images.isNotEmpty
        ? prop.images.first
        : 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?q=80&w=600';

    return Container(
      width: 265,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/property-details/${prop.id}'),
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Property Image with Overlays
            Stack(
              children: [
                Container(
                  height: 125,
                  width: double.infinity,
                  color: const Color(0xFFF1F5F9),
                  child: _buildCardImage(imageSrc),
                ),
                // Top-left Type Tag
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: prop.type == 'Rent' ? const Color(0xFF10B981) : AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4),
                      ],
                    ),
                    child: Text(
                      'For ${prop.type}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                // Top-right BHK Tag
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      prop.bhk,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            // Details & High-Visibility Action Button
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Price
                  Text(
                    prop.price,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryBlue,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Gap(3),

                  // Title
                  Text(
                    prop.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(4),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 13, color: AppColors.textSecondary),
                      const Gap(3),
                      Expanded(
                        child: Text(
                          prop.location,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Gap(12),

                  // PROMINENT, HIGH-VISIBILITY ACTION BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/property-details/${prop.id}');
                      },
                      icon: const Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.white),
                      label: const Text(
                        'View Property Details',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shadowColor: AppColors.primaryBlue.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userData = AuthStorageService.getUserData();
    final currentUserId = userData?['id']?.toString() ?? '1';

    final displayName = widget.partnerName ?? 'Broker';
    final partnerAgency = widget.agencyName ?? 'Partner Broker';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'B';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        title: StreamBuilder<Map<String, dynamic>>(
          stream: UserPresenceService.streamPresence(widget.partnerId),
          builder: (context, presenceSnap) {
            final presence = presenceSnap.data ?? {'isOnline': false, 'statusText': 'Offline'};
            final isOnline = presence['isOnline'] as bool? ?? false;
            final statusText = presence['statusText'] as String? ?? 'Offline';

            return Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryBlue,
                      radius: 18,
                      child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Row(
                        children: [
                          Icon(Icons.circle, color: isOnline ? Colors.green : Colors.grey.shade400, size: 8),
                          const Gap(4),
                          Expanded(
                            child: Text(
                              '$statusText • $partnerAgency',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.primaryBlue),
            onSelected: (value) {
              if (value == 'clear') {
                setState(() {
                  _messages.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat history cleared')));
              } else if (value == 'View Profile' && widget.partnerId != null) {
                context.push('/broker-details/${widget.partnerId}?isInternal=false');
              }
            },
            itemBuilder: (context) => [
              if (widget.partnerId != null)
                const PopupMenuItem(value: 'View Profile', child: Text('View Broker Profile')),
              const PopupMenuItem(value: 'clear', child: Text('Clear Chat History')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreChatService.streamMessages(widget.chatId, currentUserId),
              builder: (context, snapshot) {
                List<Map<String, dynamic>> displayMessages = [];
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  displayMessages = snapshot.data!;
                } else if (_messages.isNotEmpty) {
                  displayMessages = _messages;
                }

                if (snapshot.connectionState == ConnectionState.waiting && _isLoadingHistory && displayMessages.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
                }

                if (displayMessages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                            child: Text(
                              initial,
                              style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 24),
                            ),
                          ),
                          const Gap(16),
                          Text(
                            'Say hello to $displayName!',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const Gap(6),
                          const Text(
                            'Start a collaboration discussion, share properties, or exchange documents.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: displayMessages.length,
                  itemBuilder: (context, index) {
                    final message = displayMessages[index];
                    final isMe = message['isMe'] as bool;
                    final prop = message['property'] as PropertyModel?;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14.0),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe) ...[
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primaryBlue,
                              child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const Gap(8),
                          ],
                          Flexible(
                            child: Container(
                              padding: prop != null
                                  ? const EdgeInsets.all(6)
                                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? AppColors.primaryBlue : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                                ),
                                border: isMe ? null : Border.all(color: AppColors.border),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 3)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  if (prop != null) ...[
                                    _buildPropertyAttachmentCard(prop, isMe),
                                  ],
                                  if (message['text'] != null &&
                                      (message['text'] as String).isNotEmpty &&
                                      !message['text'].toString().startsWith('Check out this property listing:') &&
                                      message['text'] != 'Shared Property Card' &&
                                      message['text'] != 'Shared Attachment')
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: prop != null ? 6.0 : 0.0, vertical: prop != null ? 4.0 : 0.0),
                                      child: Text(
                                        message['text'] as String,
                                        style: TextStyle(
                                          color: isMe ? Colors.white : AppColors.textPrimary,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  const Gap(4),
                                  Padding(
                                    padding: EdgeInsets.only(right: prop != null ? 6.0 : 0.0, left: prop != null ? 6.0 : 0.0),
                                    child: Text(
                                      message['time'] as String,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isMe ? Colors.white70 : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input Area Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showAttachmentMenu(context),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: AppColors.primaryBlue, size: 22),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const Gap(10),
                  GestureDetector(
                    onTap: () => _sendMessage(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
