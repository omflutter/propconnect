import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:propconnect/core/services/auth_storage_service.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final savedMode = AuthStorageService.getThemeMode();
    if (savedMode == 'dark') {
      return ThemeMode.dark;
    } else if (savedMode == 'system') {
      return ThemeMode.system;
    }
    return ThemeMode.light;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    final modeStr = mode == ThemeMode.dark
        ? 'dark'
        : (mode == ThemeMode.system ? 'system' : 'light');
    AuthStorageService.setThemeMode(modeStr);
  }

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});
