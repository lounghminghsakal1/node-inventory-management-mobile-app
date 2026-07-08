import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../data/models/purchase_order_model.dart';
import '../data/repositories/purchase_order_repository.dart';

final purchaseOrderRepoProvider = Provider<PurchaseOrderRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return PurchaseOrderRepository(dio);
});

final purchaseOrderListProvider = FutureProvider.autoDispose<List<PurchaseOrderModel>>((ref) async {
  final repo = ref.watch(purchaseOrderRepoProvider);
  return repo.getPurchaseOrders();
});

final purchaseOrderByIdProvider = FutureProvider.family.autoDispose<PurchaseOrderModel, int>((ref, id) async {
  final repo = ref.watch(purchaseOrderRepoProvider);
  return repo.getPurchaseOrderById(id);
});

final grnListForPoProvider = FutureProvider.family.autoDispose<List<GrnModel>, int>((ref, poId) async {
  final repo = ref.watch(purchaseOrderRepoProvider);
  return repo.getGrnsForPo(poId);
});

final grnDetailProvider = FutureProvider.family.autoDispose<GrnModel, int>((ref, grnId) async {
  final repo = ref.watch(purchaseOrderRepoProvider);
  return repo.getGrnDetail(grnId);
});

final poSkuItemsProvider = FutureProvider.family.autoDispose<List<PoSkuItemModel>, int>((ref, poId) async {
  final repo = ref.watch(purchaseOrderRepoProvider);
  return repo.getPurchaseOrderSkuItems(poId);
});

class GrnController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  GrnController(this.ref) : super(const AsyncValue.data(null));

  Future<GrnModel?> createGrn({
    required int poId,
    required String vendorInvoiceDate,
    required String vendorInvoiceNo,
    required String receivedDate,
    String? vendorInvoiceS3Url,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(purchaseOrderRepoProvider);
      final grn = await repo.createGrn(
        poId: poId,
        vendorInvoiceDate: vendorInvoiceDate,
        vendorInvoiceNo: vendorInvoiceNo,
        receivedDate: receivedDate,
        vendorInvoiceS3Url: vendorInvoiceS3Url,
      );
      ref.invalidate(grnListForPoProvider(poId));
      ref.invalidate(purchaseOrderByIdProvider(poId));
      state = const AsyncValue.data(null);
      return grn;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> updateGrnLineItems(int grnId, int poId, List<GrnLineItemModel> items) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(purchaseOrderRepoProvider);
      await repo.updateGrnLineItems(grnId, items);
      ref.invalidate(grnDetailProvider(grnId));
      ref.invalidate(grnListForPoProvider(poId));
      ref.invalidate(poSkuItemsProvider(poId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateStatus(int grnId, int poId, String newStatus) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(purchaseOrderRepoProvider);
      await repo.updateGrnStatus(grnId, newStatus);
      ref.invalidate(grnDetailProvider(grnId));
      ref.invalidate(grnListForPoProvider(poId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> submitQc(int grnId, int poId, List<GrnLineItemModel> items) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(purchaseOrderRepoProvider);
      await repo.submitGrnQc(grnId, items);
      ref.invalidate(grnDetailProvider(grnId));
      ref.invalidate(grnListForPoProvider(poId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<bool> checkSerialExists(String serial, [int productSkuId = 0]) async {
    final repo = ref.read(purchaseOrderRepoProvider);
    return repo.checkSerialExists(serial, productSkuId);
  }

  Future<bool> validateSerial(String serial, [int productSkuId = 0]) async {
    final repo = ref.read(purchaseOrderRepoProvider);
    return repo.validateSerial(serial, productSkuId);
  }
}

final grnControllerProvider = StateNotifierProvider<GrnController, AsyncValue<void>>((ref) {
  return GrnController(ref);
});
