import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/order.dart';
import '../data/models/shipment.dart';
import '../data/models/shippable_line_item.dart';
import '../data/repositories/shipment_repository.dart';

// ── Shipment List State ───────────────────────────────────────────────────────
class ShipmentListState {
  final List<Shipment> shipments;
  final bool isLoading;
  final bool isMoreLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final int totalCount;

  const ShipmentListState({
    this.shipments = const [],
    this.isLoading = false,
    this.isMoreLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalCount = 0,
  });

  ShipmentListState copyWith({
    List<Shipment>? shipments,
    bool? isLoading,
    bool? isMoreLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    int? totalCount,
  }) =>
      ShipmentListState(
        shipments: shipments ?? this.shipments,
        isLoading: isLoading ?? this.isLoading,
        isMoreLoading: isMoreLoading ?? this.isMoreLoading,
        error: error,
        currentPage: currentPage ?? this.currentPage,
        totalPages: totalPages ?? this.totalPages,
        totalCount: totalCount ?? this.totalCount,
      );
}

class ShipmentListNotifier extends StateNotifier<ShipmentListState> {
  final ShipmentRepository _repo;

  ShipmentListNotifier(this._repo)
      : super(const ShipmentListState()) {
    load();
  }

  Future<void> load({
    int page = 1,
    String? byStatus,
    String? byOrderNumber,
    String? byCustomerCode,
    String? byShipmentType,
    String? fromDate,
    String? toDate,
  }) async {
    if (!mounted) return;
    if (page == 1) {
      state = state.copyWith(isLoading: true, error: null);
    } else {
      if (state.isLoading || state.isMoreLoading || state.currentPage >= state.totalPages) return;
      state = state.copyWith(isMoreLoading: true, error: null);
    }
    try {
      final res = await _repo.getShipmentsApi(
        page: page,
        byStatus: byStatus,
        byOrderNumber: byOrderNumber,
        byCustomerCode: byCustomerCode,
        byShipmentType: byShipmentType,
        fromDate: fromDate,
        toDate: toDate,
      );
      if (!mounted) return;
      final updatedShipments = page == 1 ? res.shipments : [...state.shipments, ...res.shipments];
      state = state.copyWith(
        shipments: updatedShipments,
        isLoading: false,
        isMoreLoading: false,
        currentPage: res.currentPage,
        totalPages: res.totalPages,
        totalCount: res.totalCount,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        shipments: _repo.getAll(),
        isLoading: false,
        isMoreLoading: false,
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || state.isMoreLoading || state.currentPage >= state.totalPages) return;
    await load(page: state.currentPage + 1);
  }

  Future<Shipment> createShipment({
    required Order order,
    required List<({Product product, int qty})> selectedItems,
  }) async {
    if (!mounted) {
      return _repo.createShipment(order: order, selectedItems: selectedItems);
    }
    state = state.copyWith(isLoading: true);
    try {
      final shipment = await _repo.createShipment(
        order: order,
        selectedItems: selectedItems,
      );
      if (mounted) {
        state = state.copyWith(shipments: _repo.getAll(), isLoading: false);
      }
      return shipment;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
      rethrow;
    }
  }

  Future<void> createShipmentApi({
    required int orderId,
    required int nodeId,
    required List<Map<String, dynamic>> lineItems,
  }) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);
    try {
      await _repo.createShipmentApi(
        orderId: orderId,
        nodeId: nodeId,
        lineItems: lineItems,
      );
      if (mounted) {
        state = state.copyWith(shipments: _repo.getAll(), isLoading: false);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
      rethrow;
    }
  }

  Future<void> updateStatus(String id, ShipmentStatus status) async {
    await _repo.updateStatus(id, status);
    if (mounted) {
      state = state.copyWith(shipments: _repo.getAll());
    }
  }

  Future<void> allocate(String id, List<ShipmentLineItem> items) async {
    await _repo.allocate(id, items);
    if (mounted) {
      state = state.copyWith(shipments: _repo.getAll());
    }
  }

  Future<void> dispatch(String id, DriverDetails driver) async {
    await _repo.dispatch(id, driver);
    if (mounted) {
      state = state.copyWith(shipments: _repo.getAll());
    }
  }

  Future<void> updateShipmentItems(String id, List<ShipmentLineItem> items) async {
    await _repo.updateShipmentItems(id, items);
    if (mounted) {
      state = state.copyWith(shipments: _repo.getAll());
    }
  }

  Future<void> markDelivered(String id, [Map<String, dynamic>? payload]) async {
    await _repo.markDelivered(shipmentId: id, payload: payload);
    if (mounted) {
      state = state.copyWith(shipments: _repo.getAll());
    }
  }
}

final shipmentListProvider =
    StateNotifierProvider.autoDispose<ShipmentListNotifier, ShipmentListState>((ref) {
  return ShipmentListNotifier(ref.read(shipmentRepositoryProvider));
});

// ── Single Shipment Provider ──────────────────────────────────────────────────
final shipmentByIdProvider = FutureProvider.family.autoDispose<Shipment?, String>((ref, id) async {
  return ref.read(shipmentRepositoryProvider).getShipmentById(id);
});

// ── Orders Provider ───────────────────────────────────────────────────────────
final confirmedOrdersProvider = Provider.autoDispose<List<Order>>((ref) {
  return ref.read(shipmentRepositoryProvider).getConfirmedOrders();
});

// ── Shippable Line Items Provider ─────────────────────────────────────────────
final shippableLineItemsProvider = FutureProvider.family.autoDispose<
    List<ShippableLineItem>,
    ({int nodeId, int orderId})>((ref, params) async {
  return ref
      .read(shipmentRepositoryProvider)
      .getShippableLineItems(nodeId: params.nodeId, orderId: params.orderId);
});

// ── Allocation Availability Providers ─────────────────────────────────────────
final lineItemsAvailabilityProvider = FutureProvider.family.autoDispose<
    List<LineItemAvailabilityModel>,
    String>((ref, shipmentId) async {
  return ref
      .read(shipmentRepositoryProvider)
      .getLineItemsAvailability(shipmentId: shipmentId);
});

final batchAvailabilityProvider = FutureProvider.family.autoDispose<
    List<BatchAvailabilityModel>,
    ({String shipmentId, String skuId})>((ref, params) async {
  return ref
      .read(shipmentRepositoryProvider)
      .getBatchAvailability(shipmentId: params.shipmentId, skuId: params.skuId);
});

final untrackedAvailabilityProvider = FutureProvider.family.autoDispose<
    List<UntrackedAvailabilityModel>,
    ({String shipmentId, String skuId})>((ref, params) async {
  return ref
      .read(shipmentRepositoryProvider)
      .getUntrackedAvailability(shipmentId: params.shipmentId, skuId: params.skuId);
});

final serialAvailabilityProvider = FutureProvider.family.autoDispose<
    List<SerialAvailabilityModel>,
    ({String shipmentId, String skuId})>((ref, params) async {
  return ref
      .read(shipmentRepositoryProvider)
      .getSerialAvailability(shipmentId: params.shipmentId, skuId: params.skuId);
});

final returnAllocationInfoProvider = FutureProvider.family.autoDispose<
    List<Map<String, dynamic>>, String>((ref, shipmentId) async {
  return ref
      .read(shipmentRepositoryProvider)
      .getReturnAllocationInfo(shipmentId);
});

