import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';

class UserPresenceService with WidgetsBindingObserver {
  static final UserPresenceService _instance = UserPresenceService._internal();
  factory UserPresenceService() => _instance;
  UserPresenceService._internal();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static CollectionReference get _presenceRef => _firestore.collection('presence');

  Timer? _heartbeatTimer;
  bool _isInitialized = false;

  /// Initializes the presence lifecycle tracker
  void init() {
    if (_isInitialized) return;
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
    setOnline(true);

    // Heartbeat every 60 seconds while active
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      setOnline(true);
    });
  }

  /// Called when the app lifecycle changes (foreground / background)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setOnline(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      setOnline(false);
    }
  }

  /// Sets the online/offline status for the currently authenticated user in Firestore
  static Future<void> setOnline(bool isOnline) async {
    try {
      final userData = AuthStorageService.getUserData();
      final userId = userData?['id']?.toString();
      if (userId == null || userId.isEmpty) return;

      await _presenceRef.doc(userId).set({
        'userId': userId,
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating presence: $e');
    }
  }

  /// Streams the real-time presence status of any user from Cloud Firestore
  static Stream<Map<String, dynamic>> streamPresence(String? userId) {
    if (userId == null || userId.isEmpty) {
      return Stream.value({'isOnline': false, 'statusText': 'Offline'});
    }

    return _presenceRef.doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return {'isOnline': false, 'statusText': 'Offline'};
      }

      final data = snapshot.data() as Map<String, dynamic>? ?? {};
      final bool rawOnline = data['isOnline'] == true;
      final rawTimestamp = data['lastSeen'];

      DateTime? lastSeenDate;
      if (rawTimestamp is Timestamp) {
        lastSeenDate = rawTimestamp.toDate();
      }

      // Check if connection is active (within 3 minutes if rawOnline is true)
      final now = DateTime.now();
      bool isActuallyOnline = false;
      if (rawOnline) {
        if (lastSeenDate != null) {
          final diff = now.difference(lastSeenDate).inMinutes;
          isActuallyOnline = diff <= 4;
        } else {
          isActuallyOnline = true;
        }
      }

      String statusText = 'Offline';
      if (isActuallyOnline) {
        statusText = 'Online';
      } else if (lastSeenDate != null) {
        final diff = now.difference(lastSeenDate);
        if (diff.inMinutes < 1) {
          statusText = 'Last seen just now';
        } else if (diff.inMinutes < 60) {
          statusText = 'Last seen ${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          statusText = 'Last seen ${diff.inHours}h ago';
        } else {
          final h = lastSeenDate.hour % 12 == 0 ? 12 : lastSeenDate.hour % 12;
          final m = lastSeenDate.minute.toString().padLeft(2, '0');
          final ampm = lastSeenDate.hour >= 12 ? 'PM' : 'AM';
          statusText = 'Last seen ${lastSeenDate.day}/${lastSeenDate.month} $h:$m $ampm';
        }
      }

      return {
        'isOnline': isActuallyOnline,
        'statusText': statusText,
      };
    });
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    setOnline(false);
    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
  }
}
