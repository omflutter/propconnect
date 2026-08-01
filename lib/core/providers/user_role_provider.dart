import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserRole {
  agencyAdmin,
  broker,
}

class UserRoleNotifier extends Notifier<UserRole> {
  @override
  UserRole build() {
    return UserRole.agencyAdmin; // Default state for prototype
  }

  void toggleRole() {
    state = state == UserRole.agencyAdmin ? UserRole.broker : UserRole.agencyAdmin;
  }

  void setRole(UserRole role) {
    state = role;
  }
}

final userRoleProvider = NotifierProvider<UserRoleNotifier, UserRole>(() {
  return UserRoleNotifier();
});
