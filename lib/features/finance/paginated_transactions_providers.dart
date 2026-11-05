import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers.dart';
import 'transaction.dart';

class PaginatedTransactionsResult {
  final List<Transaction> items;
  final int total;
  final int page;
  final bool hasMore;

  PaginatedTransactionsResult({
    required this.items,
    required this.total,
    required this.page,
    required this.hasMore,
  });

  factory PaginatedTransactionsResult.empty() =>
      PaginatedTransactionsResult(items: [], total: 0, page: 0, hasMore: false);

  factory PaginatedTransactionsResult.fromMap(Map<String, dynamic> m) {
    return PaginatedTransactionsResult(
      items: (m['items'] as List).map((e) => Transaction.fromMap(e as Map<String, dynamic>)).toList(),
      total: (m['total'] as num).toInt(),
      page: (m['page'] as num).toInt(),
      hasMore: m['has_more'] as bool? ?? false,
    );
  }
}

class PaginatedTransactionsNotifier extends AsyncNotifier<PaginatedTransactionsResult> {
  String? _typeFilter;
  String? _search;
  String? _accountIdFilter;
  String? _periodFilter;
  int _page = 0;
  static const int _pageSize = 20;

  String? get typeFilter => _typeFilter;
  String? get periodFilter => _periodFilter;
  String? get accountIdFilter => _accountIdFilter;

  @override
  Future<PaginatedTransactionsResult> build() async {
    return _load(0);
  }

  Future<PaginatedTransactionsResult> _load(int page) async {
    final biz = await ref.read(currentBusinessProvider.future);
    if (biz == null) return PaginatedTransactionsResult.empty();

    final client = Supabase.instance.client;
    final res = await client.rpc('list_transactions_page', params: {
      'p_business_id': biz.id,
      'p_type': _typeFilter,
      'p_search': _search,
      'p_account_id': _accountIdFilter,
      'p_period': _periodFilter,
      'p_page': page,
      'p_page_size': _pageSize,
    });

    return PaginatedTransactionsResult.fromMap(res as Map<String, dynamic>);
  }

  Future<void> setTypeFilter(String? type) async {
    _typeFilter = type;
    _page = 0;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(0));
  }

  Future<void> setSearch(String? query) async {
    _search = (query == null || query.isEmpty) ? null : query;
    _page = 0;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(0));
  }

  Future<void> setAccountFilter(String? accountId) async {
    _accountIdFilter = accountId;
    _page = 0;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(0));
  }

  Future<void> setPeriodFilter(String? period) async {
    _periodFilter = period;
    _page = 0;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(0));
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore) return;

    final nextPage = _page + 1;
    try {
      final next = await _load(nextPage);
      _page = nextPage;
      state = AsyncData(PaginatedTransactionsResult(
        items: [...current.items, ...next.items],
        total: next.total,
        page: next.page,
        hasMore: next.hasMore,
      ));
    } catch (_) {}
  }

  Future<void> refresh() async {
    _page = 0;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(0));
  }
}

final paginatedTransactionsProvider =
    AsyncNotifierProvider<PaginatedTransactionsNotifier, PaginatedTransactionsResult>(
  PaginatedTransactionsNotifier.new,
);
