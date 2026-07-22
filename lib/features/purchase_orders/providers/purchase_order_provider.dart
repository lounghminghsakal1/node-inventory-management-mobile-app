import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../data/models/purchase_order_model.dart';
import '../data/repositories/purchase_order_repository.dart';

final purchaseOrderRepoProvider = Provider<PurchaseOrderRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return PurchaseOrderRepository(dio);
});

class PurchaseOrderListState {
  final List<PurchaseOrderModel> purchaseOrders;
  final bool isLoading;
  final bool isMoreLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final String? byVendorName;
  final int? byVendorId;
  final String? byPoNumber;
  final String? bySkuName;
  final String? byGrnNumber;
  final String? byStatus;
  final String? byGrnStatus;
  final String? fromDate;
  final String? toDate;

  const PurchaseOrderListState({
    this.purchaseOrders = const [],
    this.isLoading = false,
    this.isMoreLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalCount = 0,
    this.byVendorName,
    this.byVendorId,
    this.byPoNumber,
    this.bySkuName,
    this.byGrnNumber,
    this.byStatus,
    this.byGrnStatus,
    this.fromDate,
    this.toDate,
  });

  PurchaseOrderListState copyWith({
    List<PurchaseOrderModel>? purchaseOrders,
    bool? isLoading,
    bool? isMoreLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    String? byVendorName,
    int? byVendorId,
    String? byPoNumber,
    String? bySkuName,
    String? byGrnNumber,
    String? byStatus,
    String? byGrnStatus,
    String? fromDate,
    String? toDate,
  }) =>
      PurchaseOrderListState(
        purchaseOrders: purchaseOrders ?? this.purchaseOrders,
        isLoading: isLoading ?? this.isLoading,
        isMoreLoading: isMoreLoading ?? this.isMoreLoading,
        error: error,
        currentPage: currentPage ?? this.currentPage,
        totalPages: totalPages ?? this.totalPages,
        totalCount: totalCount ?? this.totalCount,
        byVendorName: byVendorName ?? this.byVendorName,
        byVendorId: byVendorId ?? this.byVendorId,
        byPoNumber: byPoNumber ?? this.byPoNumber,
        bySkuName: bySkuName ?? this.bySkuName,
        byGrnNumber: byGrnNumber ?? this.byGrnNumber,
        byStatus: byStatus ?? this.byStatus,
        byGrnStatus: byGrnStatus ?? this.byGrnStatus,
        fromDate: fromDate ?? this.fromDate,
        toDate: toDate ?? this.toDate,
      );
}

class PurchaseOrderListNotifier extends StateNotifier<PurchaseOrderListState> {
  final PurchaseOrderRepository _repo;

  PurchaseOrderListNotifier(this._repo) : super(const PurchaseOrderListState(byGrnStatus: 'qc_pending')) {
    load(byGrnStatus: 'qc_pending');
  }

  Future<void> load({
    int page = 1,
    String? byVendorName,
    int? byVendorId,
    String? byPoNumber,
    String? bySkuName,
    String? byGrnNumber,
    String? byStatus,
    String? byGrnStatus,
    String? fromDate,
    String? toDate,
  }) async {
    if (!mounted) return;
    if (page == 1) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        byVendorName: byVendorName,
        byVendorId: byVendorId,
        byPoNumber: byPoNumber,
        bySkuName: bySkuName,
        byGrnNumber: byGrnNumber,
        byStatus: byStatus,
        byGrnStatus: byGrnStatus,
        fromDate: fromDate,
        toDate: toDate,
        purchaseOrders: [],
      );
    } else {
      if (state.isLoading || state.isMoreLoading || state.currentPage >= state.totalPages) return;
      state = state.copyWith(isMoreLoading: true, error: null);
    }
    try {
      final res = await _repo.getPurchaseOrdersApi(
        page: page,
        byVendorName: page == 1 ? byVendorName : (byVendorName ?? state.byVendorName),
        byVendorId: page == 1 ? byVendorId : (byVendorId ?? state.byVendorId),
        byPoNumber: page == 1 ? byPoNumber : (byPoNumber ?? state.byPoNumber),
        bySkuName: page == 1 ? bySkuName : (bySkuName ?? state.bySkuName),
        byGrnNumber: page == 1 ? byGrnNumber : (byGrnNumber ?? state.byGrnNumber),
        byStatus: page == 1 ? byStatus : (byStatus ?? state.byStatus),
        byGrnStatus: page == 1 ? byGrnStatus : (byGrnStatus ?? state.byGrnStatus),
        fromDate: page == 1 ? fromDate : (fromDate ?? state.fromDate),
        toDate: page == 1 ? toDate : (toDate ?? state.toDate),
      );
      if (!mounted) return;
      final updatedPos = page == 1 ? res.purchaseOrders : [...state.purchaseOrders, ...res.purchaseOrders];
      state = state.copyWith(
        purchaseOrders: updatedPos,
        isLoading: false,
        isMoreLoading: false,
        currentPage: res.currentPage,
        totalPages: res.totalPages,
        totalCount: res.totalCount,
        byVendorName: page == 1 ? byVendorName : (byVendorName ?? state.byVendorName),
        byVendorId: page == 1 ? byVendorId : (byVendorId ?? state.byVendorId),
        byPoNumber: page == 1 ? byPoNumber : (byPoNumber ?? state.byPoNumber),
        bySkuName: page == 1 ? bySkuName : (bySkuName ?? state.bySkuName),
        byGrnNumber: page == 1 ? byGrnNumber : (byGrnNumber ?? state.byGrnNumber),
        byStatus: page == 1 ? byStatus : (byStatus ?? state.byStatus),
        byGrnStatus: page == 1 ? byGrnStatus : (byGrnStatus ?? state.byGrnStatus),
        fromDate: page == 1 ? fromDate : (fromDate ?? state.fromDate),
        toDate: page == 1 ? toDate : (toDate ?? state.toDate),
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        isMoreLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || state.isMoreLoading || state.currentPage >= state.totalPages) return;
    await load(
      page: state.currentPage + 1,
      byVendorName: state.byVendorName,
      byVendorId: state.byVendorId,
      byPoNumber: state.byPoNumber,
      bySkuName: state.bySkuName,
      byGrnNumber: state.byGrnNumber,
      byStatus: state.byStatus,
      byGrnStatus: state.byGrnStatus,
      fromDate: state.fromDate,
      toDate: state.toDate,
    );
  }

  // Replaces the filter-owned fields with exactly what's passed in (including
  // null, to clear a field). The previous implementation merged each field
  // with `?? state.field` before calling load(), so clearing a field (e.g.
  // the PO number search) by passing null silently kept the old value
  // instead — both in the state bookkeeping and in the actual API request.
  void updateFilters({
    String? byVendorName,
    int? byVendorId,
    String? byPoNumber,
    String? bySkuName,
    String? byGrnNumber,
    String? byGrnStatus,
    String? fromDate,
    String? toDate,
  }) {
    state = PurchaseOrderListState(
      purchaseOrders: state.purchaseOrders,
      isLoading: state.isLoading,
      isMoreLoading: state.isMoreLoading,
      error: state.error,
      currentPage: state.currentPage,
      totalPages: state.totalPages,
      totalCount: state.totalCount,
      byVendorName: byVendorName,
      byVendorId: byVendorId,
      byPoNumber: byPoNumber,
      bySkuName: bySkuName,
      byGrnNumber: byGrnNumber,
      byStatus: null,
      byGrnStatus: byGrnStatus,
      fromDate: fromDate,
      toDate: toDate,
    );
    load(
      page: 1,
      byVendorName: byVendorName,
      byVendorId: byVendorId,
      byPoNumber: byPoNumber,
      bySkuName: bySkuName,
      byGrnNumber: byGrnNumber,
      byGrnStatus: byGrnStatus,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  void clearFilters() {
    state = PurchaseOrderListState(
      purchaseOrders: state.purchaseOrders,
      isLoading: state.isLoading,
      isMoreLoading: state.isMoreLoading,
      error: state.error,
      currentPage: state.currentPage,
      totalPages: state.totalPages,
      totalCount: state.totalCount,
      byVendorName: state.byVendorName,
      byVendorId: state.byVendorId,
      byStatus: state.byStatus,
      byGrnStatus: state.byGrnStatus,
      byPoNumber: null,
      bySkuName: null,
      byGrnNumber: null,
      fromDate: null,
      toDate: null,
    );
    load(page: 1);
  }
}

final purchaseOrderListProvider =
    StateNotifierProvider.autoDispose<PurchaseOrderListNotifier, PurchaseOrderListState>((ref) {
  return PurchaseOrderListNotifier(ref.read(purchaseOrderRepoProvider));
});

final purchaseOrderByIdProvider = FutureProvider.family.autoDispose<PurchaseOrderModel, int>((ref, id) async {
  final repo = ref.watch(purchaseOrderRepoProvider);
  return repo.getPurchaseOrderById(id);
});

final grnListForPoProvider = FutureProvider.family.autoDispose<List<GrnModel>, int>((ref, poId) async {
  final repo = ref.watch(purchaseOrderRepoProvider);
  return repo.getGrnsForPo(poId);
});

class GrnDetailNotifier extends AutoDisposeFamilyAsyncNotifier<GrnModel, int> {
  @override
  Future<GrnModel> build(int grnId) async {
    final repo = ref.watch(purchaseOrderRepoProvider);
    return repo.getGrnDetail(grnId);
  }

  // Seeds the cache directly from an update response so callers can avoid an
  // extra GET to refresh a single GRN's details.
  void setData(GrnModel grn) {
    state = AsyncValue.data(grn);
  }
}

final grnDetailProvider =
    AsyncNotifierProvider.family.autoDispose<GrnDetailNotifier, GrnModel, int>(
  GrnDetailNotifier.new,
);

final poSkuItemsProvider = FutureProvider.family.autoDispose<List<PoSkuItemModel>, int>((ref, poId) async {
  final repo = ref.watch(purchaseOrderRepoProvider);
  return repo.getPurchaseOrderSkuItems(poId);
});

class GrnController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  GrnController(this.ref) : super(const AsyncValue.data(null));

  Future<String?> uploadGrnDocument(String filePath, String fileName) async {
    try {
      final repo = ref.read(purchaseOrderRepoProvider);
      return await repo.uploadGrnDocument(filePath, fileName);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<GrnModel?> createGrn({
    required int poId,
    required String vendorInvoiceDate,
    required String vendorInvoiceNo,
    required String receivedDate,
    List<String>? vendorInvoiceS3Urls,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(purchaseOrderRepoProvider);
      final grn = await repo.createGrn(
        poId: poId,
        vendorInvoiceDate: vendorInvoiceDate,
        vendorInvoiceNo: vendorInvoiceNo,
        receivedDate: receivedDate,
        vendorInvoiceS3Urls: vendorInvoiceS3Urls,
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

  Future<void> deleteGrnLineItem(int grnId, int poId, int grnLineItemId) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(purchaseOrderRepoProvider);
      await repo.deleteGrnLineItem(grnId, grnLineItemId);
      ref.invalidate(grnDetailProvider(grnId));
      ref.invalidate(grnListForPoProvider(poId));
      ref.invalidate(poSkuItemsProvider(poId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateGrnLineItems(
    int grnId,
    int poId,
    List<GrnLineItemModel> items,
    GrnModel currentGrn,
  ) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(purchaseOrderRepoProvider);
      final updatedGrn = await repo.updateGrnLineItems(grnId, items, currentGrn);
      ref.read(grnDetailProvider(grnId).notifier).setData(updatedGrn);
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

  Future<void> submitQc(
    int grnId,
    int poId,
    List<GrnLineItemModel> items,
    GrnModel currentGrn, {
    Map<int, List<String>>? qcPhotosByLineItemId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(purchaseOrderRepoProvider);
      final updatedGrn = await repo.submitGrnQc(
        grnId,
        items,
        currentGrn,
        qcPhotosByLineItemId: qcPhotosByLineItemId,
      );
      ref.read(grnDetailProvider(grnId).notifier).setData(updatedGrn);
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
