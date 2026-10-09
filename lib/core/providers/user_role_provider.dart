import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';

enum UserRole {
  agencyAdmin,
  broker,
}

class UserRoleNotifier extends Notifier<UserRole> {
  @override
  UserRole build() {
    return AuthStorageService.getUserRole();
  }

  void toggleRole() {
    state = state == UserRole.agencyAdmin ? UserRole.broker : UserRole.agencyAdmin;
    AuthStorageService.saveUserRole(state);
  }

  void setRole(UserRole role) {
    state = role;
    AuthStorageService.saveUserRole(role);
  }
}

final userRoleProvider = NotifierProvider<UserRoleNotifier, UserRole>(() {
  return UserRoleNotifier();
});
