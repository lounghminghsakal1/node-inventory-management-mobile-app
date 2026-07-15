// lib/core/widgets/back_to_home_scope.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Wrap a branch-root screen's Scaffold with this.
/// Swipe-back / system-back on this screen goes to Home instead of
/// popping the Navigator (which would otherwise close the app).
class BackToHomeScope extends StatelessWidget {
  final Widget child;
  const BackToHomeScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final location = GoRouterState.of(context).matchedLocation;
        if (location == '/home') {
          SystemNavigator.pop();
        } else {
          context.go('/home');
        }
      },
      child: child,
    );
  }
}