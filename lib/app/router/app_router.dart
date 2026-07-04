import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/node_selection/presentation/screens/node_selection_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/shipment/presentation/screens/shipment_list_screen.dart';
import '../../features/shipment/presentation/screens/create_shipment_screen.dart';
import '../../features/shipment/presentation/screens/shipment_detail_screen.dart';
import '../../features/shipment/presentation/screens/allocation_screen.dart';
import '../../features/shipment/presentation/screens/dispatch_screen.dart';
import '../../features/orders/presentation/screens/order_list_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/grn/presentation/screens/grn_screen.dart';
import '../../features/audit/presentation/screens/audit_screen.dart';
import '../../features/returns/presentation/screens/returns_screen.dart';
import '../../features/adjustment/presentation/screens/adjustment_screen.dart';
import '../../core/widgets/app_shell.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// ── Router Notifier (bridges Riverpod → GoRouter refresh) ────────────────────
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  _RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (prev, next) => notifyListeners());
  }
}

// ── Router Provider ───────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: '/login',
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;

      // Still checking stored session — don't redirect yet
      if (auth.status == AuthStatus.initial ||
          auth.status == AuthStatus.checking) {
        return null;
      }

      // Not authenticated → send to login
      if (auth.status == AuthStatus.unauthenticated) {
        return loc == '/login' ? null : '/login';
      }

      // Authenticated but node not selected → send to node-select (mandatory)
      if (auth.status == AuthStatus.nodeRequired) {
        if (loc == '/node-select') return null;
        return '/node-select';
      }

      // Fully authenticated
      if (auth.status == AuthStatus.authenticated) {
        // Redirect away from login / mandatory node-select
        if (loc == '/login' || loc == '/node-select') return '/home';
      }

      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, _) => const LoginScreen(),
      ),

      // ── Node Selection (mandatory after login, or optional via AppBar) ───
      GoRoute(
        path: '/node-select',
        name: 'node-select',
        builder: (_, state) {
          final canGoBack = state.uri.queryParameters['back'] == 'true';
          return NodeSelectionScreen(canGoBack: canGoBack);
        },
      ),

      // ── Shell with bottom nav ─────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          // Home
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, _) => const HomeScreen(),
            ),
          ]),

          // Orders (replaces Shipments in bottom nav)
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/orders',
              name: 'orders',
              builder: (context, _) => const OrderListScreen(),
            ),
          ]),

          // GRN
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/grn',
              name: 'grn',
              builder: (context, _) => const GrnScreen(),
            ),
          ]),

          // Returns
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/returns',
              name: 'returns',
              builder: (context, _) => const ReturnsScreen(),
            ),
          ]),

          // Audit
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/audit',
              name: 'audit',
              builder: (context, _) => const AuditScreen(),
            ),
          ]),
        ],
      ),

      // ── Order sub-routes ──────────────────────────────────────────────────
      GoRoute(
        path: '/orders/:id',
        name: 'order-detail',
        builder: (_, state) => OrderDetailScreen(
          orderId: int.tryParse(state.pathParameters['id']!) ?? 263,
        ),
      ),
      GoRoute(
        path: '/shipments',
        name: 'shipments-list',
        builder: (context, _) => const ShipmentListScreen(),
      ),

      // ── Shipment sub-routes (pushed, no bottom nav) ───────────────────────
      GoRoute(
        path: '/shipments/create',
        name: 'shipment-create',
        builder: (context, state) => CreateShipmentScreen(
          orderId: state.uri.queryParameters['orderId'],
        ),
      ),
      GoRoute(
        path: '/shipments/:id',
        name: 'shipment-detail',
        builder: (_, state) => ShipmentDetailScreen(
          shipmentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/shipments/:id/allocate',
        name: 'shipment-allocate',
        builder: (_, state) => AllocationScreen(
          shipmentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/shipments/:id/dispatch',
        name: 'shipment-dispatch',
        builder: (_, state) => DispatchScreen(
          shipmentId: state.pathParameters['id']!,
        ),
      ),

      // ── Additional feature routes ─────────────────────────────────────────
      GoRoute(
        path: '/adjustment',
        name: 'adjustment',
        builder: (context, _) => const AdjustmentScreen(),
      ),
    ],
  );
});

// ── Bottom Nav Shell ──────────────────────────────────────────────────────────
class _ScaffoldWithNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const _ScaffoldWithNavBar({required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const NodeOpsAppBar(),
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _NavItem(
                  index: 0,
                  current: navigationShell.currentIndex,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  onTap: () => _onTap(0),
                ),
                _NavItem(
                  index: 1,
                  current: navigationShell.currentIndex,
                  icon: Icons.shopping_bag_outlined,
                  activeIcon: Icons.shopping_bag_rounded,
                  label: 'Orders',
                  onTap: () => _onTap(1),
                ),
                _NavItem(
                  index: 2,
                  current: navigationShell.currentIndex,
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2_rounded,
                  label: 'GRN',
                  onTap: () => _onTap(2),
                ),
                _NavItem(
                  index: 3,
                  current: navigationShell.currentIndex,
                  icon: Icons.assignment_return_outlined,
                  activeIcon: Icons.assignment_return_rounded,
                  label: 'Returns',
                  onTap: () => _onTap(3),
                ),
                _NavItem(
                  index: 4,
                  current: navigationShell.currentIndex,
                  icon: Icons.fact_check_outlined,
                  activeIcon: Icons.fact_check_rounded,
                  label: 'Audit',
                  onTap: () => _onTap(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int current;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.index,
    required this.current,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: isActive
                    ? BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      )
                    : null,
                child: Icon(
                  isActive ? activeIcon : icon,
                  size: 22,
                  color: isActive ? AppColors.primary : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: isActive ? AppColors.primary : AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
