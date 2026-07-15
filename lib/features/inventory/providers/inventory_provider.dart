import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/batch_inventory_model.dart';
import '../data/models/serial_inventory_model.dart';
import '../data/models/node_inventory_model.dart';
import '../data/models/node_inventory_ledger_model.dart';
import '../data/repositories/inventory_repository.dart';

// ── Batch Inventory List State & Notifier ─────────────────────────────────────
class BatchInventoryListState {
  final List<BatchInventoryModel> items;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final String? bySkuName;
  final String? bySkuCode;
  final String? byBatchId;
  final bool availableOnly;

  const BatchInventoryListState({
    this.items = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalCount = 0,
    this.bySkuName,
    this.bySkuCode,
    this.byBatchId,
    this.availableOnly = true,
  });

  bool get hasMore => currentPage < totalPages;

  BatchInventoryListState copyWith({
    List<BatchInventoryModel>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    String? bySkuName,
    String? bySkuCode,
    String? byBatchId,
    bool? availableOnly,
    bool clearError = false,
  }) {
    return BatchInventoryListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      bySkuName: bySkuName ?? this.bySkuName,
      bySkuCode: bySkuCode ?? this.bySkuCode,
      byBatchId: byBatchId ?? this.byBatchId,
      availableOnly: availableOnly ?? this.availableOnly,
    );
  }
}

class BatchInventoryListNotifier extends StateNotifier<BatchInventoryListState> {
  final InventoryRepository _repository;

  BatchInventoryListNotifier(this._repository) : super(const BatchInventoryListState()) {
    fetchInitial();
  }

  Future<void> fetchInitial({
    String? bySkuName,
    String? bySkuCode,
    String? byBatchId,
    bool? availableOnly,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      bySkuName: bySkuName ?? state.bySkuName,
      bySkuCode: bySkuCode ?? state.bySkuCode,
      byBatchId: byBatchId ?? state.byBatchId,
      availableOnly: availableOnly ?? state.availableOnly,
    );

    try {
      final res = await _repository.getBatchInventories(
        bySkuName: state.bySkuName,
        bySkuCode: state.bySkuCode,
        byBatchId: state.byBatchId,
        availableInventory: state.availableOnly ? true : null,
        page: 1,
      );

      state = state.copyWith(
        items: res.batchInventories,
        isLoading: false,
        currentPage: res.meta.currentPage,
        totalPages: res.meta.totalPages,
        totalCount: res.meta.totalCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || state.isLoadingMore || state.currentPage >= state.totalPages) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);
    final nextPage = state.currentPage + 1;

    try {
      final res = await _repository.getBatchInventories(
        bySkuName: state.bySkuName,
        bySkuCode: state.bySkuCode,
        byBatchId: state.byBatchId,
        availableInventory: state.availableOnly ? true : null,
        page: nextPage,
      );

      state = state.copyWith(
        items: [...state.items, ...res.batchInventories],
        isLoadingMore: false,
        currentPage: res.meta.currentPage,
        totalPages: res.meta.totalPages,
        totalCount: res.meta.totalCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void updateFilters({
    String? bySkuName,
    String? bySkuCode,
    String? byBatchId,
    bool? availableOnly,
  }) {
    fetchInitial(
      bySkuName: bySkuName,
      bySkuCode: bySkuCode,
      byBatchId: byBatchId,
      availableOnly: availableOnly,
    );
  }

  void clearFilters() {
    state = const BatchInventoryListState(availableOnly: true);
    fetchInitial();
  }
}

final batchInventoryListProvider = StateNotifierProvider<BatchInventoryListNotifier, BatchInventoryListState>((ref) {
  final repo = ref.read(inventoryRepositoryProvider);
  return BatchInventoryListNotifier(repo);
});

// ── Serial Inventory List State & Notifier ────────────────────────────────────
class SerialInventoryListState {
  final List<SerialInventoryModel> items;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final String? bySkuItemNumber;
  final String? bySkuName;
  final String? bySkuCode;
  final String byStatus;

  const SerialInventoryListState({
    this.items = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalCount = 0,
    this.bySkuItemNumber,
    this.bySkuName,
    this.bySkuCode,
    this.byStatus = 'all',
  });

  bool get hasMore => currentPage < totalPages;

  SerialInventoryListState copyWith({
    List<SerialInventoryModel>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    String? bySkuItemNumber,
    String? bySkuName,
    String? bySkuCode,
    String? byStatus,
    bool clearError = false,
  }) {
    return SerialInventoryListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      bySkuItemNumber: bySkuItemNumber ?? this.bySkuItemNumber,
      bySkuName: bySkuName ?? this.bySkuName,
      bySkuCode: bySkuCode ?? this.bySkuCode,
      byStatus: byStatus ?? this.byStatus,
    );
  }
}

class SerialInventoryListNotifier extends StateNotifier<SerialInventoryListState> {
  final InventoryRepository _repository;

  SerialInventoryListNotifier(this._repository) : super(const SerialInventoryListState()) {
    fetchInitial();
  }

  Future<void> fetchInitial({
    String? bySkuItemNumber,
    String? bySkuName,
    String? bySkuCode,
    String? byStatus,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      bySkuItemNumber: bySkuItemNumber ?? state.bySkuItemNumber,
      bySkuName: bySkuName ?? state.bySkuName,
      bySkuCode: bySkuCode ?? state.bySkuCode,
      byStatus: byStatus ?? state.byStatus,
    );

    try {
      final res = await _repository.getSerialInventories(
        bySkuItemNumber: state.bySkuItemNumber,
        bySkuName: state.bySkuName,
        bySkuCode: state.bySkuCode,
        byStatus: state.byStatus == 'all' ? null : state.byStatus,
        page: 1,
      );

      state = state.copyWith(
        items: res.skuItems,
        isLoading: false,
        currentPage: res.meta.currentPage,
        totalPages: res.meta.totalPages,
        totalCount: res.meta.totalCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || state.isLoadingMore || state.currentPage >= state.totalPages) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);
    final nextPage = state.currentPage + 1;

    try {
      final res = await _repository.getSerialInventories(
        bySkuItemNumber: state.bySkuItemNumber,
        bySkuName: state.bySkuName,
        bySkuCode: state.bySkuCode,
        byStatus: state.byStatus == 'all' ? null : state.byStatus,
        page: nextPage,
      );

      state = state.copyWith(
        items: [...state.items, ...res.skuItems],
        isLoadingMore: false,
        currentPage: res.meta.currentPage,
        totalPages: res.meta.totalPages,
        totalCount: res.meta.totalCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void updateFilters({
    String? bySkuItemNumber,
    String? bySkuName,
    String? bySkuCode,
    String? byStatus,
  }) {
    fetchInitial(
      bySkuItemNumber: bySkuItemNumber,
      bySkuName: bySkuName,
      bySkuCode: bySkuCode,
      byStatus: byStatus,
    );
  }

  void clearFilters() {
    state = const SerialInventoryListState();
    fetchInitial();
  }
}

final serialInventoryListProvider = StateNotifierProvider<SerialInventoryListNotifier, SerialInventoryListState>((ref) {
  final repo = ref.read(inventoryRepositoryProvider);
  return SerialInventoryListNotifier(repo);
});

// ── Detail & Transactions Providers ───────────────────────────────────────────
final batchInventoryDetailProvider = FutureProvider.family<BatchInventoryModel, String>((ref, id) async {
  final repo = ref.read(inventoryRepositoryProvider);
  return repo.getBatchInventoryDetail(id);
});

final serialInventoryDetailProvider = FutureProvider.family<SerialInventoryModel, String>((ref, id) async {
  final repo = ref.read(inventoryRepositoryProvider);
  return repo.getSerialInventoryDetail(id);
});

// Batch Inventory Transactions with infinite scroll
class BatchTransactionsState {
  final Map<String, dynamic> summary;
  final List<BatchInventoryTransactionModel> transactions;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;
  final int totalCount;

  const BatchTransactionsState({
    this.summary = const {},
    this.transactions = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalCount = 0,
  });

  BatchTransactionsState copyWith({
    Map<String, dynamic>? summary,
    List<BatchInventoryTransactionModel>? transactions,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    bool clearError = false,
  }) {
    return BatchTransactionsState(
      summary: summary ?? this.summary,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class BatchTransactionsNotifier extends StateNotifier<BatchTransactionsState> {
  final InventoryRepository _repository;
  final String _batchId;

  BatchTransactionsNotifier(this._repository, this._batchId) : super(const BatchTransactionsState()) {
    fetchInitial();
  }

  Future<void> fetchInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repository.getBatchInventoryTransactions(_batchId, page: 1);
      state = state.copyWith(
        summary: res.batchInventorySummary,
        transactions: res.transactions,
        isLoading: false,
        currentPage: res.meta.currentPage,
        totalPages: res.meta.totalPages,
        totalCount: res.meta.totalCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || state.isLoadingMore || state.currentPage >= state.totalPages) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    final nextPage = state.currentPage + 1;
    try {
      final res = await _repository.getBatchInventoryTransactions(_batchId, page: nextPage);
      state = state.copyWith(
        transactions: [...state.transactions, ...res.transactions],
        isLoadingMore: false,
        currentPage: res.meta.currentPage,
        totalPages: res.meta.totalPages,
        totalCount: res.meta.totalCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final batchTransactionsProvider = StateNotifierProvider.family<BatchTransactionsNotifier, BatchTransactionsState, String>((ref, id) {
  final repo = ref.read(inventoryRepositoryProvider);
  return BatchTransactionsNotifier(repo, id);
});

// ── Node Inventory List State & Notifier ─────────────────────────────────────
class NodeInventoryListState {
  final List<NodeInventoryModel> items;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final String? bySkuName;
  final String? bySkuCode;
  final String? bySkuId;
  final bool availableOnly;

  const NodeInventoryListState({
    this.items = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalCount = 0,
    this.bySkuName,
    this.bySkuCode,
    this.bySkuId,
    this.availableOnly = true,
  });

  bool get hasMore => currentPage < totalPages;

  NodeInventoryListState copyWith({
    List<NodeInventoryModel>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    String? bySkuName,
    String? bySkuCode,
    String? bySkuId,
    bool? availableOnly,
    bool clearError = false,
  }) {
    return NodeInventoryListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      bySkuName: bySkuName ?? this.bySkuName,
      bySkuCode: bySkuCode ?? this.bySkuCode,
      bySkuId: bySkuId ?? this.bySkuId,
      availableOnly: availableOnly ?? this.availableOnly,
    );
  }
}

class NodeInventoryListNotifier extends StateNotifier<NodeInventoryListState> {
  final InventoryRepository _repository;

  NodeInventoryListNotifier(this._repository) : super(const NodeInventoryListState()) {
    fetchInitial();
  }

  Future<void> fetchInitial({
    String? bySkuName,
    String? bySkuCode,
    String? bySkuId,
    bool? availableOnly,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      bySkuName: bySkuName ?? state.bySkuName,
      bySkuCode: bySkuCode ?? state.bySkuCode,
      bySkuId: bySkuId ?? state.bySkuId,
      availableOnly: availableOnly ?? state.availableOnly,
    );

    try {
      final res = await _repository.getNodeInventories(
        bySkuName: state.bySkuName,
        bySkuCode: state.bySkuCode,
        bySkuId: state.bySkuId,
        availableInventory: state.availableOnly ? true : null,
        page: 1,
      );

      state = state.copyWith(
        items: res.inventories,
        isLoading: false,
        currentPage: res.currentPage,
        totalPages: res.totalPages,
        totalCount: res.totalCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || state.isLoadingMore || state.currentPage >= state.totalPages) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    final nextPage = state.currentPage + 1;

    try {
      final res = await _repository.getNodeInventories(
        bySkuName: state.bySkuName,
        bySkuCode: state.bySkuCode,
        bySkuId: state.bySkuId,
        availableInventory: state.availableOnly ? true : null,
        page: nextPage,
      );

      state = state.copyWith(
        items: [...state.items, ...res.inventories],
        isLoadingMore: false,
        currentPage: res.currentPage,
        totalPages: res.totalPages,
        totalCount: res.totalCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void filterAvailableOnly(bool value) {
    fetchInitial(availableOnly: value);
  }

  void updateFilters({
    String? bySkuName,
    String? bySkuCode,
    String? bySkuId,
    bool? availableOnly,
  }) {
    fetchInitial(
      bySkuName: bySkuName,
      bySkuCode: bySkuCode,
      bySkuId: bySkuId,
      availableOnly: availableOnly,
    );
  }

  void clearFilters() {
    state = const NodeInventoryListState(availableOnly: true);
    fetchInitial();
  }
}

final nodeInventoryListProvider = StateNotifierProvider<NodeInventoryListNotifier, NodeInventoryListState>((ref) {
  final repo = ref.read(inventoryRepositoryProvider);
  return NodeInventoryListNotifier(repo);
});

// ── Node Inventory Transactions State & Notifier ──────────────────────────────
class NodeInventoryTransactionsState {
  final NodeInventoryModel? nodeInventory;
  final List<NodeInventoryTransactionModel> transactions;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;
  final int totalCount;

  const NodeInventoryTransactionsState({
    this.nodeInventory,
    this.transactions = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalCount = 0,
  });

  NodeInventoryTransactionsState copyWith({
    NodeInventoryModel? nodeInventory,
    List<NodeInventoryTransactionModel>? transactions,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    bool clearError = false,
  }) {
    return NodeInventoryTransactionsState(
      nodeInventory: nodeInventory ?? this.nodeInventory,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class NodeInventoryTransactionsNotifier extends StateNotifier<NodeInventoryTransactionsState> {
  final InventoryRepository _repository;
  final String _inventoryId;

  NodeInventoryTransactionsNotifier(this._repository, this._inventoryId) : super(const NodeInventoryTransactionsState()) {
    fetchInitial();
  }

  Future<void> fetchInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repository.getNodeInventoryTransactions(_inventoryId, page: 1);
      state = state.copyWith(
        nodeInventory: res.nodeInventory,
        transactions: res.transactions,
        isLoading: false,
        currentPage: res.currentPage,
        totalPages: res.totalPages,
        totalCount: res.totalCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || state.isLoadingMore || state.currentPage >= state.totalPages) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    final nextPage = state.currentPage + 1;
    try {
      final res = await _repository.getNodeInventoryTransactions(_inventoryId, page: nextPage);
      state = state.copyWith(
        transactions: [...state.transactions, ...res.transactions],
        isLoadingMore: false,
        currentPage: res.currentPage,
        totalPages: res.totalPages,
        totalCount: res.totalCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final nodeInventoryTransactionsProvider = StateNotifierProvider.family<NodeInventoryTransactionsNotifier, NodeInventoryTransactionsState, String>((ref, id) {
  final repo = ref.read(inventoryRepositoryProvider);
  return NodeInventoryTransactionsNotifier(repo, id);
});

final nodeInventoryDetailProvider = FutureProvider.family<NodeInventoryModel, String>((ref, id) async {
  final repo = ref.read(inventoryRepositoryProvider);
  return await repo.getNodeInventoryDetail(id);
});

// ── Node Inventory Ledger State & Notifier ────────────────────────────────────
class NodeInventoryLedgerState {
  final List<NodeInventoryLedgerModel> items;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final String? bySkuId;
  final String? bySkuCode;
  final String? fromDate;
  final String? toDate;

  const NodeInventoryLedgerState({
    this.items = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalCount = 0,
    this.bySkuId,
    this.bySkuCode,
    this.fromDate,
    this.toDate,
  });

  NodeInventoryLedgerState copyWith({
    List<NodeInventoryLedgerModel>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    String? bySkuId,
    String? bySkuCode,
    String? fromDate,
    String? toDate,
    bool clearError = false,
  }) {
    return NodeInventoryLedgerState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      bySkuId: bySkuId ?? this.bySkuId,
      bySkuCode: bySkuCode ?? this.bySkuCode,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
    );
  }
}

class NodeInventoryLedgerNotifier extends StateNotifier<NodeInventoryLedgerState> {
  final InventoryRepository _repository;

  NodeInventoryLedgerNotifier(this._repository) : super(const NodeInventoryLedgerState()) {
    fetchInitial();
  }

  Future<void> fetchInitial({
    String? bySkuId,
    String? bySkuCode,
    String? fromDate,
    String? toDate,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      bySkuId: bySkuId ?? state.bySkuId,
      bySkuCode: bySkuCode ?? state.bySkuCode,
      fromDate: fromDate ?? state.fromDate,
      toDate: toDate ?? state.toDate,
    );

    try {
      final res = await _repository.getNodeInventoryLedger(
        bySkuId: state.bySkuId,
        bySkuCode: state.bySkuCode,
        fromDate: state.fromDate,
        toDate: state.toDate,
        page: 1,
      );

      state = state.copyWith(
        items: res.ledger,
        isLoading: false,
        currentPage: res.currentPage,
        totalPages: res.totalPages,
        totalCount: res.totalCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || state.isLoadingMore || state.currentPage >= state.totalPages) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    final nextPage = state.currentPage + 1;

    try {
      final res = await _repository.getNodeInventoryLedger(
        bySkuId: state.bySkuId,
        bySkuCode: state.bySkuCode,
        fromDate: state.fromDate,
        toDate: state.toDate,
        page: nextPage,
      );

      state = state.copyWith(
        items: [...state.items, ...res.ledger],
        isLoadingMore: false,
        currentPage: res.currentPage,
        totalPages: res.totalPages,
        totalCount: res.totalCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void filterByDates(String? from, String? to) {
    fetchInitial(fromDate: from, toDate: to);
  }

  void updateFilters({
    String? bySkuId,
    String? bySkuCode,
    String? fromDate,
    String? toDate,
  }) {
    fetchInitial(
      bySkuId: bySkuId,
      bySkuCode: bySkuCode,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  void clearFilters() {
    state = const NodeInventoryLedgerState();
    fetchInitial();
  }
}

final nodeInventoryLedgerProvider = StateNotifierProvider<NodeInventoryLedgerNotifier, NodeInventoryLedgerState>((ref) {
  final repo = ref.read(inventoryRepositoryProvider);
  return NodeInventoryLedgerNotifier(repo);
});
