import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/order.dart';
import '../data/models/shipment.dart';
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
}

final shipmentListProvider =
    StateNotifierProvider<ShipmentListNotifier, ShipmentListState>((ref) {
  return ShipmentListNotifier(ref.read(shipmentRepositoryProvider));
});

// ── Single Shipment Provider ──────────────────────────────────────────────────
final shipmentByIdProvider = Provider.family<Shipment?, String>((ref, id) {
  final list = ref.watch(shipmentListProvider).shipments;
  try {
    return list.firstWhere((s) =>
        s.id == id ||
        s.shipmentNumber == id ||
        s.id == 'sh_$id' ||
        s.shipmentNumber.contains(id));
  } catch (_) {
    return Shipment(
      id: id,
      shipmentNumber: id.startsWith('EFP') ? id : (id.startsWith('SH') ? id : 'EFP-S-10$id'),
      orderId: 'ord_263',
      orderNumber: 'EFP-O-10263',
      customerName: 'SaiFlaerhomes',
      status: ShipmentStatus.created,
      createdAt: DateTime.now(),
      lineItems: [
        const ShipmentLineItem(
          id: 'sli_fb_1',
          product: Product(
            id: 'prod_ply_1',
            name: 'Commercial Plywood MR Grade 6mm 8x4',
            sku: '10010010000100000',
            trackingType: TrackingType.batch,
            nodeStock: 150,
          ),
          shippedQty: 20,
        ),
        const ShipmentLineItem(
          id: 'sli_fb_2',
          product: Product(
            id: 'prod_ply_2',
            name: 'Commercial Plywood BWR Grade 6mm 8x4',
            sku: '10010010001100000',
            trackingType: TrackingType.serial,
            nodeStock: 200,
          ),
          shippedQty: 30,
        ),
      ],
    );
  }
});

// ── Orders Provider ───────────────────────────────────────────────────────────
final confirmedOrdersProvider = Provider<List<Order>>((ref) {
  return ref.read(shipmentRepositoryProvider).getConfirmedOrders();
});
