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
  final String byShipmentType;
  final String? byStatus;
  final bool? byFullyAllocated;
  final String? byOrderNumber;
  final String? byShipmentNumber;
  final String? bySkuName;
  final String? bySkuCode;
  final String? fromDate;
  final String? toDate;

  const ShipmentListState({
    this.shipments = const [],
    this.isLoading = false,
    this.isMoreLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalCount = 0,
    this.byShipmentType = 'forward_shipment',
    this.byStatus,
    this.byFullyAllocated,
    this.byOrderNumber,
    this.byShipmentNumber,
    this.bySkuName,
    this.bySkuCode,
    this.fromDate,
    this.toDate,
  });

  ShipmentListState copyWith({
    List<Shipment>? shipments,
    bool? isLoading,
    bool? isMoreLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    String? byShipmentType,
    String? byStatus,
    bool? byFullyAllocated,
    String? byOrderNumber,
    String? byShipmentNumber,
    String? bySkuName,
    String? bySkuCode,
    String? fromDate,
    String? toDate,
  }) =>
      ShipmentListState(
        shipments: shipments ?? this.shipments,
        isLoading: isLoading ?? this.isLoading,
        isMoreLoading: isMoreLoading ?? this.isMoreLoading,
        error: error,
        currentPage: currentPage ?? this.currentPage,
        totalPages: totalPages ?? this.totalPages,
        totalCount: totalCount ?? this.totalCount,
        byShipmentType: byShipmentType ?? this.byShipmentType,
        byStatus: byStatus ?? this.byStatus,
        byFullyAllocated: byFullyAllocated ?? this.byFullyAllocated,
        byOrderNumber: byOrderNumber ?? this.byOrderNumber,
        byShipmentNumber: byShipmentNumber ?? this.byShipmentNumber,
        bySkuName: bySkuName ?? this.bySkuName,
        bySkuCode: bySkuCode ?? this.bySkuCode,
        fromDate: fromDate ?? this.fromDate,
        toDate: toDate ?? this.toDate,
      );
}

class ShipmentListNotifier extends StateNotifier<ShipmentListState> {
  final ShipmentRepository _repo;

  ShipmentListNotifier(this._repo)
      : super(const ShipmentListState()) {
    load(byShipmentType: 'forward_shipment');
  }

  Future<void> load({
    int page = 1,
    String? byShipmentType,
    String? byStatus,
    bool? byFullyAllocated,
    String? byOrderNumber,
    String? byShipmentNumber,
    String? byCustomerCode,
    String? bySkuName,
    String? bySkuCode,
    String? fromDate,
    String? toDate,
  }) async {
    if (!mounted) return;
    final targetShipmentType = byShipmentType ?? state.byShipmentType;

    if (page == 1) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        byShipmentType: targetShipmentType,
        byStatus: byStatus ?? state.byStatus,
        byFullyAllocated: byFullyAllocated ?? state.byFullyAllocated,
        byOrderNumber: byOrderNumber ?? state.byOrderNumber,
        byShipmentNumber: byShipmentNumber ?? state.byShipmentNumber,
        bySkuName: bySkuName ?? state.bySkuName,
        bySkuCode: bySkuCode ?? state.bySkuCode,
        fromDate: fromDate ?? state.fromDate,
        toDate: toDate ?? state.toDate,
        shipments: []
      );
    } else {
      if (state.isLoading || state.isMoreLoading || state.currentPage >= state.totalPages) return;
      state = state.copyWith(isMoreLoading: true, error: null,);
    }

    try {
      final res = await _repo.getShipmentsApi(
        page: page,
        byStatus: state.byStatus,
        byFullyAllocated: state.byFullyAllocated,
        byOrderNumber: state.byOrderNumber,
        byCustomerCode: byCustomerCode,
        byShipmentType: targetShipmentType,
        fromDate: state.fromDate,
        toDate: state.toDate,
        byShipmentNumber: state.byShipmentNumber,
        bySkuName: state.bySkuName,
        bySkuCode: state.bySkuCode,
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
        byShipmentType: targetShipmentType,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        shipments: page == 1 ? _repo.getAll() : state.shipments,
        isLoading: false,
        isMoreLoading: false,
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || state.isMoreLoading || state.currentPage >= state.totalPages) return;
    await load(page: state.currentPage + 1, byShipmentType: state.byShipmentType);
  }

  void updateFilters({
    String? byStatus,
    String? byOrderNumber,
    String? byShipmentNumber,
    String? bySkuName,
    String? bySkuCode,
    String? fromDate,
    String? toDate,
  }) {
    state = state.copyWith(
      byStatus: byStatus,
      byOrderNumber: byOrderNumber,
      byShipmentNumber: byShipmentNumber,
      bySkuName: bySkuName,
      bySkuCode: bySkuCode,
      fromDate: fromDate,
      toDate: toDate,
    );
    load(page: 1);
  }
  
  void clearFilters() {
    state = ShipmentListState(
      shipments: state.shipments,
      isLoading: state.isLoading,
      isMoreLoading: state.isMoreLoading,
      error: state.error,
      currentPage: state.currentPage,
      totalPages: state.totalPages,
      totalCount: state.totalCount,
      byShipmentType: state.byShipmentType,
      byStatus: state.byStatus,
      byFullyAllocated: state.byFullyAllocated,
      byOrderNumber: null,
      byShipmentNumber: null,
      bySkuName: null,
      bySkuCode: null,
      fromDate: null,
      toDate: null,
    );
    load(page: 1);
  }

  // Sets (or clears, when passed null) the status filter driven by the Home
  // screen's pending-actions tiles. copyWith can't null a field back out (it
  // falls back to the current value), so this rebuilds the state directly —
  // this is the only way to independently null either field.
  void setStatusFilter({String? byStatus, bool? byFullyAllocated}) {
    state = ShipmentListState(
      shipments: state.shipments,
      isLoading: state.isLoading,
      isMoreLoading: state.isMoreLoading,
      error: state.error,
      currentPage: state.currentPage,
      totalPages: state.totalPages,
      totalCount: state.totalCount,
      byShipmentType: state.byShipmentType,
      byStatus: byStatus,
      byFullyAllocated: byFullyAllocated,
      byOrderNumber: state.byOrderNumber,
      byShipmentNumber: state.byShipmentNumber,
      bySkuName: state.bySkuName,
      bySkuCode: state.bySkuCode,
      fromDate: state.fromDate,
      toDate: state.toDate,
    );
    load(page: 1);
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

final returnRemainingProvider = FutureProvider.family.autoDispose<
    List<Map<String, dynamic>>, String>((ref, shipmentId) async {
  return ref
      .read(shipmentRepositoryProvider)
      .getReturnRemaining(shipmentId);
});

final returnAllocationInfoProvider = FutureProvider.family.autoDispose<
    List<Map<String, dynamic>>, String>((ref, shipmentId) async {
  return ref
      .read(shipmentRepositoryProvider)
      .getReturnRemaining(shipmentId);
});

