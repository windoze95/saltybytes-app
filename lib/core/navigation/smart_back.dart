import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A back button that never strands the user: pops when there is somewhere
/// to pop to, and otherwise goes to [fallback]. Deep links (shared recipe
/// links, universal links) land on full-screen routes as the ONLY stack
/// entry — the default AppBar shows no back button there, and go_router's
/// pop() would throw.
Widget smartBackLeading(BuildContext context, {String fallback = '/home'}) {
  return BackButton(
    onPressed: () {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(fallback);
      }
    },
  );
}
