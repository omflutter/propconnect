import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:propconnect/core/models/property_model.dart';
import 'package:propconnect/core/network/api_service.dart';

class FirestoreChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference get _conversationsRef => _firestore.collection('conversations');

  /// Streams real-time conversation list for the given user from Cloud Firestore
  static Stream<List<Map<String, dynamic>>> streamConversations(String userId) {
    return _conversationsRef
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final participants = List<String>.from(data['participants'] ?? []);
            final partnerId = participants.firstWhere((id) => id != userId, orElse: () => '');
            final namesMap = Map<String, dynamic>.from(data['participantNames'] ?? {});
            final agenciesMap = Map<String, dynamic>.from(data['participantAgencies'] ?? {});
            final unreadMap = Map<String, dynamic>.from(data['unreadCounts'] ?? {});

            final updatedAt = data['updatedAt'] is Timestamp
                ? (data['updatedAt'] as Timestamp).toDate()
                : (data['createdAt'] is Timestamp
                    ? (data['createdAt'] as Timestamp).toDate()
                    : DateTime.now());

            final unreadCount = (unreadMap[userId] as num? ?? 0).toInt();

            return {
              'conversationId': doc.id,
              'partnerId': partnerId,
              'partnerName': namesMap[partnerId] ?? 'Broker',
              'agencyName': agenciesMap[partnerId] ?? 'Partner Agency',
              'lastMessage': data['lastMessage'] ?? '',
              'lastMessageTime': updatedAt.toIso8601String(),
              'updatedAt': updatedAt,
              'isUnread': unreadCount > 0,
              'unreadCount': unreadCount,
            };
          }).toList();

          // Sort client-side by most recent
          list.sort((a, b) => (b['updatedAt'] as DateTime).compareTo(a['updatedAt'] as DateTime));
          return list;
        });
  }

  /// Streams real-time messages for a specific conversation from Cloud Firestore
  static Stream<List<Map<String, dynamic>>> streamMessages(String conversationId, String currentUserId) {
    return _conversationsRef
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            final senderId = data['senderId']?.toString() ?? '';
            final rawCreated = data['createdAt'];
            DateTime dt = DateTime.now();
            if (rawCreated is Timestamp) {
              dt = rawCreated.toDate();
            }

            final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
            final minute = dt.minute.toString().padLeft(2, '0');
            final ampm = dt.hour >= 12 ? 'PM' : 'AM';
            final timeStr = '$hour:$minute $ampm';

            return {
              'id': doc.id,
              'isMe': senderId == currentUserId,
              'text': data['messageText'] ?? '',
              'time': timeStr,
              'type': data['attachmentType'] ?? 'text',
              'property': (data['attachmentType'] == 'property' && data['attachmentData'] != null)
                  ? PropertyModel.fromJson(Map<String, dynamic>.from(data['attachmentData'] as Map))
                  : null,
              'attachmentData': data['attachmentData'],
              'isRead': data['isRead'] ?? false,
            };
          }).toList();
        });
  }

  /// Streams real-time total unread count for the given user from Cloud Firestore
  static Stream<int> streamTotalUnreadCount(String userId) {
    return _conversationsRef
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (final doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final unreadMap = Map<String, dynamic>.from(data['unreadCounts'] ?? {});
            total += (unreadMap[userId] as num? ?? 0).toInt();
          }
          return total;
        });
  }

  /// Sends a message: writes to Cloud Firestore in real time AND syncs with PostgreSQL
  static Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String senderAgency,
    required String receiverId,
    required String receiverName,
    required String receiverAgency,
    required String messageText,
    String attachmentType = 'text',
    Map<String, dynamic>? attachmentData,
  }) async {
    try {
      final convDoc = _conversationsRef.doc(conversationId);
      final messagesCol = convDoc.collection('messages');

      // 1. Add message document to Firestore
      await messagesCol.add({
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'messageText': messageText,
        'attachmentType': attachmentType,
        'attachmentData': attachmentData,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Set/Update conversation document in Firestore
      await convDoc.set({
        'conversationId': conversationId,
        'participants': [senderId, receiverId],
        'participantNames': {
          senderId: senderName,
          receiverId: receiverName,
        },
        'participantAgencies': {
          senderId: senderAgency,
          receiverId: receiverAgency,
        },
        'lastMessage': messageText.isNotEmpty ? messageText : 'Shared Attachment',
        'lastSenderId': senderId,
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCounts': {
          senderId: 0,
          receiverId: FieldValue.increment(1),
        },
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore sendMessage error: $e');
    }

    // 3. Dual-sync to Cloud PostgreSQL backend in background
    try {
      await ApiService.post('/chat/send', {
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'messageText': messageText,
        'attachmentType': attachmentType,
        'attachmentData': attachmentData,
      });
    } catch (e) {
      debugPrint('PostgreSQL sync error: $e');
    }
  }

  /// Marks conversation as read in Cloud Firestore
  static Future<void> markConversationAsRead(String conversationId, String userId) async {
    try {
      final convDoc = _conversationsRef.doc(conversationId);
      await convDoc.set({
        'unreadCounts': {
          userId: 0,
        },
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error marking conversation read: $e');
    }
  }
}
