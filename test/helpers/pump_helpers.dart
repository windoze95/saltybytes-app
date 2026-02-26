import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:saltybytes_app/core/theme/app_theme.dart';

/// Wraps [child] in a MaterialApp + ProviderScope with the SaltyBytes theme,
/// suitable for widget tests that need a full Material environment.
Widget testApp(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    ),
  );
}

/// Same as [testApp] but places [child] as the home Scaffold directly
/// (no extra Scaffold wrapper).
Widget testAppScaffold(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    ),
  );
}
