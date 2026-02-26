import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_provider.dart';

final themeModeProvider = Provider<ThemeMode>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return ThemeMode.system;
  switch (user.settings.themeMode) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
});
