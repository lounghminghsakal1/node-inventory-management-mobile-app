import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../data/models/stock_audit.dart';
import '../data/repositories/stock_audit_repository.dart';

// ── Repository Provider ───────────────────────────────────────────────────────

final stockAuditRepositoryProvider = Provider<StockAuditRepository>((ref) {
  return StockAuditRepository(ref.read(dioProvider));
});

// ── Listing State + Notifier ──────────────────────────────────────────────────

class StockAuditsState {
  final List<StockAuditDetail> audits;
  final bool isLoading;
  final bool isMoreLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final String? filterAuditType;
  final String? filterStatus;

  const StockAuditsState({
    this.audits = const [],
    this.isLoading = false,
    this.isMoreLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalCount = 0,
    this.filterAuditType,
    this.filterStatus = 'initiated_auditing',
  });

  StockAuditsState copyWith({
    List<StockAuditDetail>? audits,
    bool? isLoading,
    bool? isMoreLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    String? filterAuditType,
    String? filterStatus,
  }) =>
      StockAuditsState(
        audits: audits ?? this.audits,
        isLoading: isLoading ?? this.isLoading,
        isMoreLoading: isMoreLoading ?? this.isMoreLoading,
        error: error,
        currentPage: currentPage ?? this.currentPage,
        totalPages: totalPages ?? this.totalPages,
        totalCount: totalCount ?? this.totalCount,
        filterAuditType: filterAuditType ?? this.filterAuditType,
        filterStatus: filterStatus ?? this.filterStatus,
      );
}

class StockAuditsNotifier extends StateNotifier<StockAuditsState> {
  final StockAuditRepository _repo;

  StockAuditsNotifier(this._repo) : super(const StockAuditsState()) {
    load();
  }

  Future<void> load({int page = 1, bool isRefresh = false}) async {
    if (!mounted) return;
    if (page == 1) {
      if (isRefresh) {
        state = state.copyWith(error: null);
      } else {
        state = state.copyWith(isLoading: true, error: null, audits: []);
      }
    } else {
      if (state.isLoading || state.isMoreLoading || state.currentPage >= state.totalPages) return;
      state = state.copyWith(isMoreLoading: true, error: null);
    }
    try {
      final res = await _repo.getStockAudits(
        page: page,
        auditType: state.filterAuditType,
        status: state.filterStatus,
      );
      if (!mounted) return;
      final updated = page == 1 ? res.audits : [...state.audits, ...res.audits];
      state = state.copyWith(
        audits: updated,
        isLoading: false,
        isMoreLoading: false,
        currentPage: res.currentPage,
        totalPages: res.totalPages,
        totalCount: res.totalCount,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, isMoreLoading: false, error: e.toString());
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || state.isMoreLoading || state.currentPage >= state.totalPages) return;
    await load(page: state.currentPage + 1);
  }

  void setFilters({String? auditType, String? status}) {
    state = state.copyWith(
      filterAuditType: auditType,
      filterStatus: status,
      currentPage: 1, // Reset to page 1 on filter change
    );
    load();
  }
}

final stockAuditsProvider = StateNotifierProvider.autoDispose<StockAuditsNotifier, StockAuditsState>((ref) {
  return StockAuditsNotifier(ref.read(stockAuditRepositoryProvider));
});

// ── Detail Provider ───────────────────────────────────────────────────────────

final stockAuditDetailProvider =
    FutureProvider.family.autoDispose<StockAuditDetail?, String>((ref, id) async {
  return ref.read(stockAuditRepositoryProvider).getStockAuditDetail(id);
});

// ── Line Items State + Notifier ───────────────────────────────────────────────

class AuditLineItemsState {
  final List<AuditLineItem> items;
  final bool isLoading;
  final bool isMoreLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final int totalCount;

  const AuditLineItemsState({
    this.items = const [],
    this.isLoading = false,
    this.isMoreLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalCount = 0,
  });

  AuditLineItemsState copyWith({
    List<AuditLineItem>? items,
    bool? isLoading,
    bool? isMoreLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    int? totalCount,
  }) =>
      AuditLineItemsState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        isMoreLoading: isMoreLoading ?? this.isMoreLoading,
        error: error,
        currentPage: currentPage ?? this.currentPage,
        totalPages: totalPages ?? this.totalPages,
        totalCount: totalCount ?? this.totalCount,
      );
}

class AuditLineItemsNotifier extends StateNotifier<AuditLineItemsState> {
  final StockAuditRepository _repo;
  final String auditId;

  AuditLineItemsNotifier(this._repo, this.auditId)
      : super(const AuditLineItemsState()) {
    load();
  }

  Future<void> load({int page = 1}) async {
    if (!mounted) return;
    if (page == 1) {
      state = state.copyWith(isLoading: true, error: null, items: []);
    } else {
      if (state.isLoading || state.isMoreLoading || state.currentPage >= state.totalPages) return;
      state = state.copyWith(isMoreLoading: true, error: null);
    }
    try {
      final res = await _repo.getLineItems(auditId, page: page);
      if (!mounted) return;
      final updated = page == 1 ? res.items : [...state.items, ...res.items];
      state = state.copyWith(
        items: updated,
        isLoading: false,
        isMoreLoading: false,
        currentPage: res.currentPage,
        totalPages: res.totalPages,
        totalCount: res.totalCount,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, isMoreLoading: false, error: e.toString());
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || state.isMoreLoading || state.currentPage >= state.totalPages) return;
    await load(page: state.currentPage + 1);
  }

  /// Called after a successful countSku to update the local item in place.
  void updateItem(AuditLineItem updated) {
    if (!mounted) return;
    state = state.copyWith(
      items: state.items.map((i) => i.id == updated.id ? updated : i).toList(),
    );
  }
}

final auditLineItemsProvider = StateNotifierProvider.family
    .autoDispose<AuditLineItemsNotifier, AuditLineItemsState, String>((ref, auditId) {
  return AuditLineItemsNotifier(ref.read(stockAuditRepositoryProvider), auditId);
});

// ── Batch/Serial sub-providers ────────────────────────────────────────────────

final auditSkuBatchesProvider = FutureProvider.family
    .autoDispose<List<AuditBatch>, ({String auditId, String skuId})>((ref, p) async {
  return ref.read(stockAuditRepositoryProvider).getBatchesForSku(p.auditId, p.skuId);
});

final auditSkuSerialsProvider = FutureProvider.family
    .autoDispose<List<AuditSerial>, ({String auditId, String skuId})>((ref, p) async {
  return ref.read(stockAuditRepositoryProvider).getSerialsForSku(p.auditId, p.skuId);
});
