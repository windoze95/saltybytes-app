import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = Provider<ThemeMode>((ref) {
  // themeMode was removed from UserSettings; always use system theme.
  return ThemeMode.system;
});
