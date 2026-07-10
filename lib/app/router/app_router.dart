import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:node_management_app/features/audit/presentation/screens/stock_audit_detail_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/node_selection/presentation/screens/node_selection_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/shipment/presentation/screens/shipment_list_screen.dart';
import '../../features/shipment/presentation/screens/create_shipment_screen.dart';
import '../../features/shipment/presentation/screens/shipment_detail_screen.dart';
import '../../features/shipment/presentation/screens/allocation_screen.dart';
import '../../features/shipment/presentation/screens/dispatch_screen.dart';
import '../../features/shipment/presentation/screens/good_bad_allocation_screen.dart';
import '../../features/shipment/data/models/shipment.dart';
import '../../features/shipment/providers/shipment_provider.dart';
import '../../features/orders/presentation/screens/order_list_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/purchase_orders/presentation/screens/purchase_order_list_screen.dart';
import '../../features/purchase_orders/presentation/screens/purchase_order_detail_screen.dart';
import '../../features/audit/presentation/screens/audit_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/inventory/presentation/screens/batch_inventory_detail_screen.dart';
import '../../features/inventory/presentation/screens/serial_inventory_detail_screen.dart';
import '../../features/adjustment/presentation/screens/adjustment_screen.dart';
import '../../core/widgets/app_shell.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// ── Router Notifier (bridges Riverpod → GoRouter refresh) ────────────────────
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  _RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.status != next.status) {
        notifyListeners();
      }
    });
  }
}

// ── Top-level redirect function (supports hot reload updates) ─────────────────
String? _appRedirect(BuildContext context, GoRouterState state, Ref ref) {
  final auth = ref.read(authProvider);
  final loc = state.matchedLocation;

  // Still checking stored session — don't redirect yet
  if (auth.status == AuthStatus.initial || auth.status == AuthStatus.checking) {
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
    if (loc == '/login') return '/home';
    if (loc == '/node-select' && state.uri.queryParameters['back'] != 'true') {
      return '/home';
    }
  }

  return null;
}

// ── Router Provider ───────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: '/login',
    redirect: (context, state) => _appRedirect(context, state, ref),
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, _) => const HomeScreen(),
              ),
            ],
          ),

          // Shipments (replaces Orders in bottom nav)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shipments',
                name: 'shipments',
                builder: (context, _) => const ShipmentListScreen(),
              ),
            ],
          ),

          // Purchase Orders (replaces GRN in bottom nav)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/purchase-orders',
                name: 'purchase-orders',
                builder: (context, _) => const PurchaseOrderListScreen(),
              ),
              GoRoute(path: '/grn', redirect: (_, _) => '/purchase-orders'),
            ],
          ),

          // Inventory (replaces Returns in bottom nav)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inventory',
                name: 'inventory',
                builder: (context, _) => const InventoryScreen(),
              ),
              GoRoute(path: '/returns', redirect: (_, _) => '/inventory'),
            ],
          ),

          // Audit
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/audit',
                name: 'audit',
                builder: (context, _) => const AuditScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/audit/:id',
        name: 'audit-detail',
        builder: (context, state) {
          return StockAuditDetailScreen(
            auditId: state.pathParameters['id']!
          );
        },
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
        path: '/purchase-orders/:id',
        name: 'purchase-order-detail',
        builder: (_, state) => PurchaseOrderDetailScreen(
          poId: int.tryParse(state.pathParameters['id']!) ?? 132,
        ),
      ),
      GoRoute(
        path: '/orders',
        name: 'orders-list',
        builder: (context, _) => const OrderListScreen(),
      ),
      GoRoute(
        path: '/inventory/batch/:id',
        name: 'batch-inventory-detail',
        builder: (_, state) => BatchInventoryDetailScreen(
          batchInventoryId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/inventory/serial/:id',
        name: 'serial-inventory-detail',
        builder: (_, state) => SerialInventoryDetailScreen(
          serialItemId: state.pathParameters['id']!,
        ),
      ),

      // ── Shipment sub-routes (pushed, no bottom nav) ───────────────────────
      GoRoute(
        path: '/shipments/create',
        name: 'shipment-create',
        builder: (context, state) => CreateShipmentScreen(
          orderId: state.uri.queryParameters['orderId'],
          orderNumber: state.uri.queryParameters['orderNumber'],
          customerName: state.uri.queryParameters['customerName'],
        ),
      ),
      GoRoute(
        path: '/shipments/:id',
        name: 'shipment-detail',
        builder: (_, state) =>
            ShipmentDetailScreen(shipmentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/shipments/:id/allocate',
        name: 'shipment-allocate',
        builder: (_, state) =>
            AllocationScreen(shipmentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/shipments/:id/dispatch',
        name: 'shipment-dispatch',
        builder: (_, state) =>
            DispatchScreen(shipmentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/shipments/:id/good_bad_allocation',
        name: 'shipment-return-allocation',
        builder: (_, state) => GoodBadAllocationScreen(
          shipmentId: state.pathParameters['id']!,
          shipment: state.extra is Shipment ? state.extra as Shipment : null,
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
      appBar: NodeOpsAppBar(
      ),
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.cardBorder, width: 1),
          ),
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
                  onTap: () => _onTap(context, 0),
                ),
                _NavItem(
                  index: 1,
                  current: navigationShell.currentIndex,
                  icon: Icons.local_shipping_outlined,
                  activeIcon: Icons.local_shipping_rounded,
                  label: 'Shipments',
                  onTap: () => _onTap(context, 1),
                ),
                _NavItem(
                  index: 2,
                  current: navigationShell.currentIndex,
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: 'Purchase Orders',
                  onTap: () => _onTap(context, 2),
                ),
                _NavItem(
                  index: 3,
                  current: navigationShell.currentIndex,
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2_rounded,
                  label: 'Inventory',
                  onTap: () => _onTap(context, 3),
                ),
                _NavItem(
                  index: 4,
                  current: navigationShell.currentIndex,
                  icon: Icons.fact_check_outlined,
                  activeIcon: Icons.fact_check_rounded,
                  label: 'Audit',
                  onTap: () => _onTap(context, 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    if (index == navigationShell.currentIndex) {
      navigationShell.goBranch(index, initialLocation: true);
      return;
    }
    switch (index) {
      case 0:
        GoRouter.of(context).go('/home');
        break;
      case 1:
        GoRouter.of(context).go('/shipments');
        break;
      case 2:
        GoRouter.of(context).go('/purchase-orders');
        break;
      case 3:
        GoRouter.of(context).go('/inventory');
        break;
      case 4:
        GoRouter.of(context).go('/audit');
        break;
      default:
        navigationShell.goBranch(index);
    }
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
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
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: isActive ? AppColors.primary : AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShipmentsAppBarAction extends ConsumerWidget {
  const _ShipmentsAppBarAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shipmentListProvider);
    if (state.shipments.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert_rounded,
        color: AppColors.textSecondary,
        size: 20,
      ),
      padding: EdgeInsets.zero,
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      onSelected: (val) {
        if (val == 'create') {
          showCreateShipmentThroughOrderModal(context, ref);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'create',
          child: Row(
            children: [
              const Icon(
                Icons.add_shopping_cart_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Create shipment through order',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
