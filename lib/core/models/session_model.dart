class SessionModel {
  final String id;
  final String deviceName;
  final String deviceType; // 'mobile' | 'tablet' | 'desktop' | 'web'
  final String os;
  final String appVersion;
  final String ipAddress;
  final String location;
  final String loginAt;
  final String lastActiveAt;
  final String expiresAt;
  final bool isCurrent;
  final String authMethod;
  final String status;

  SessionModel({
    required this.id,
    required this.deviceName,
    required this.deviceType,
    required this.os,
    required this.appVersion,
    required this.ipAddress,
    required this.location,
    required this.loginAt,
    required this.lastActiveAt,
    required this.expiresAt,
    required this.isCurrent,
    required this.authMethod,
    this.status = 'active',
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id']?.toString() ?? '',
      deviceName: json['deviceName']?.toString() ?? 'Device',
      deviceType: json['deviceType']?.toString() ?? 'mobile',
      os: json['os']?.toString() ?? 'Operating System',
      appVersion: json['appVersion']?.toString() ?? 'PropConnect App',
      ipAddress: json['ipAddress']?.toString() ?? '127.0.0.1',
      location: json['location']?.toString() ?? 'Unknown Location',
      loginAt: json['loginAt']?.toString() ?? '',
      lastActiveAt: json['lastActiveAt']?.toString() ?? 'Active now',
      expiresAt: json['expiresAt']?.toString() ?? '',
      isCurrent: json['isCurrent'] == true,
      authMethod: json['authMethod']?.toString() ?? 'JWT Bearer',
      status: json['status']?.toString() ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'os': os,
      'appVersion': appVersion,
      'ipAddress': ipAddress,
      'location': location,
      'loginAt': loginAt,
      'lastActiveAt': lastActiveAt,
      'expiresAt': expiresAt,
      'isCurrent': isCurrent,
      'authMethod': authMethod,
      'status': status,
    };
  }
}
