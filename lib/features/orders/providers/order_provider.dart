import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../data/models/order_model.dart';
import '../data/repositories/order_repository.dart';

// ── Providers ─────────────────────────────────────────────────────────────────
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return OrderRepository(dio);
});

final orderListLoadingMoreProvider = StateProvider<bool>((ref) => false);
final orderListHasMoreProvider = StateProvider<bool>((ref) => true);

final orderListProvider =
    AsyncNotifierProvider.autoDispose<OrderListNotifier, List<OrderSummary>>(
      OrderListNotifier.new,
    );

class OrderListNotifier extends AutoDisposeAsyncNotifier<List<OrderSummary>> {
  late OrderRepository _repo;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  Future<List<OrderSummary>> build() async {
    _repo = ref.watch(orderRepositoryProvider);
    _currentPage = 1;
    _totalPages = 1;

    // Reset pagination state
    Future.microtask(() {
      if (ref.exists(orderListLoadingMoreProvider)) {
        ref.read(orderListLoadingMoreProvider.notifier).state = false;
      }
      if (ref.exists(orderListHasMoreProvider)) {
        ref.read(orderListHasMoreProvider.notifier).state = true;
      }
    });

    final res = await _repo.getOrders(page: 1);
    _currentPage = res.meta.currentPage;
    _totalPages = res.meta.totalPages;

    Future.microtask(() {
      if (ref.exists(orderListHasMoreProvider)) {
        ref.read(orderListHasMoreProvider.notifier).state =
            _currentPage < _totalPages;
      }
    });

    return res.orders;
  }

  Future<void> loadMore() async {
    final isLoadingMore = ref.read(orderListLoadingMoreProvider);
    final hasMore = ref.read(orderListHasMoreProvider);

    if (isLoadingMore || !hasMore || _currentPage >= _totalPages) return;

    ref.read(orderListLoadingMoreProvider.notifier).state = true;
    try {
      final nextPage = _currentPage + 1;
      final res = await _repo.getOrders(page: nextPage);
      _currentPage = res.meta.currentPage;
      _totalPages = res.meta.totalPages;

      ref.read(orderListHasMoreProvider.notifier).state =
          _currentPage < _totalPages;

      final currentList = state.value ?? [];
      state = AsyncValue.data([...currentList, ...res.orders]);
    } catch (e) {
      debugPrint('Failed to load more orders: $e');
    } finally {
      ref.read(orderListLoadingMoreProvider.notifier).state = false;
    }
  }
}

/// Returns detail for the given order ID by calling GET /orders/$id.
final orderDetailProvider = FutureProvider.family.autoDispose<OrderDetail, int>((
  ref,
  id,
) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getOrderDetail(id);
});
