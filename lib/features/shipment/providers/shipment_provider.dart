import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/order.dart';
import '../data/models/shipment.dart';
import '../data/models/shippable_line_item.dart';
import '../data/repositories/shipment_repository.dart';

// ── Shipment List State ───────────────────────────────────────────────────────
class ShipmentListState {
  final List<Shipment> shipments;
  final bool isLoading;
  final String? error;

  const ShipmentListState({
    this.shipments = const [],
    this.isLoading = false,
    this.error,
  });

  ShipmentListState copyWith({
    List<Shipment>? shipments,
    bool? isLoading,
    String? error,
  }) =>
      ShipmentListState(
        shipments: shipments ?? this.shipments,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class ShipmentListNotifier extends StateNotifier<ShipmentListState> {
  final ShipmentRepository _repo;

  ShipmentListNotifier(this._repo)
      : super(const ShipmentListState()) {
    load();
  }

  void load() {
    state = state.copyWith(
      shipments: _repo.getAll(),
      isLoading: false,
    );
  }

  Future<Shipment> createShipment({
    required Order order,
    required List<({Product product, int qty})> selectedItems,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final shipment = await _repo.createShipment(
        order: order,
        selectedItems: selectedItems,
      );
      state = state.copyWith(shipments: _repo.getAll(), isLoading: false);
      return shipment;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> createShipmentApi({
    required int orderId,
    required int nodeId,
    required List<Map<String, dynamic>> lineItems,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.createShipmentApi(
        orderId: orderId,
        nodeId: nodeId,
        lineItems: lineItems,
      );
      state = state.copyWith(shipments: _repo.getAll(), isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateStatus(String id, ShipmentStatus status) async {
    await _repo.updateStatus(id, status);
    state = state.copyWith(shipments: _repo.getAll());
  }

  Future<void> allocate(String id, List<ShipmentLineItem> items) async {
    await _repo.allocate(id, items);
    state = state.copyWith(shipments: _repo.getAll());
  }

  Future<void> dispatch(String id, DriverDetails driver) async {
    await _repo.dispatch(id, driver);
    state = state.copyWith(shipments: _repo.getAll());
  }

  Future<void> updateShipmentItems(String id, List<ShipmentLineItem> items) async {
    await _repo.updateShipmentItems(id, items);
    state = state.copyWith(shipments: _repo.getAll());
  }

  Future<void> markDelivered(String id) async {
    await _repo.markDelivered(shipmentId: id);
    state = state.copyWith(shipments: _repo.getAll());
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
final batchAvailabilityProvider = FutureProvider.family.autoDispose<
    List<BatchAvailabilityModel>,
    ({int nodeId, String skuId})>((ref, params) async {
  return ref
      .read(shipmentRepositoryProvider)
      .getBatchAvailability(nodeId: params.nodeId, skuId: params.skuId);
});

final untrackedAvailabilityProvider = FutureProvider.family.autoDispose<
    List<UntrackedAvailabilityModel>,
    ({int nodeId, String skuId})>((ref, params) async {
  return ref
      .read(shipmentRepositoryProvider)
      .getUntrackedAvailability(nodeId: params.nodeId, skuId: params.skuId);
});

final serialAvailabilityProvider = FutureProvider.family.autoDispose<
    List<SerialAvailabilityModel>,
    ({int nodeId, String skuId})>((ref, params) async {
  return ref
      .read(shipmentRepositoryProvider)
      .getSerialAvailability(nodeId: params.nodeId, skuId: params.skuId);
});
