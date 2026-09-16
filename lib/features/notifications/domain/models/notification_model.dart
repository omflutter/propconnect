class AppNotification {
  final int id;
  final String notificationCode;
  final int userId;
  final int? agencyId;
  final String title;
  final String message;
  final String type; // 'collaboration', 'deal', 'commission', 'subscription', 'system'
  final String? actionRoute;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final DateTime? readAt;
  final String channels;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.notificationCode,
    required this.userId,
    this.agencyId,
    required this.title,
    required this.message,
    required this.type,
    this.actionRoute,
    this.metadata,
    required this.isRead,
    this.readAt,
    required this.channels,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String());
    } catch (_) {
      parsedDate = DateTime.now();
    }

    DateTime? parsedReadAt;
    if (json['readAt'] != null) {
      try {
        parsedReadAt = DateTime.parse(json['readAt']);
      } catch (_) {}
    }

    return AppNotification(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      notificationCode: json['notificationCode'] ?? '',
      userId: json['userId'] is int ? json['userId'] : int.tryParse(json['userId'].toString()) ?? 0,
      agencyId: json['agencyId'] != null ? (json['agencyId'] is int ? json['agencyId'] : int.tryParse(json['agencyId'].toString())) : null,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'system',
      actionRoute: json['actionRoute'],
      metadata: json['metadata'] is Map<String, dynamic> ? json['metadata'] : null,
      isRead: json['isRead'] == true,
      readAt: parsedReadAt,
      channels: json['channels'] ?? 'in_app',
      createdAt: parsedDate,
    );
  }

  AppNotification copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id,
      notificationCode: notificationCode,
      userId: userId,
      agencyId: agencyId,
      title: title,
      message: message,
      type: type,
      actionRoute: actionRoute,
      metadata: metadata,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      channels: channels,
      createdAt: createdAt,
    );
  }
}
