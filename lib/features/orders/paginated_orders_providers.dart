import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers.dart';
import 'order.dart';

class PaginatedOrdersResult {
  final List<Order> items;
  final int total;
  final int page;
  final bool hasMore;

  PaginatedOrdersResult({
    required this.items,
    required this.total,
    required this.page,
    required this.hasMore,
  });

  factory PaginatedOrdersResult.empty() =>
      PaginatedOrdersResult(items: [], total: 0, page: 0, hasMore: false);

  factory PaginatedOrdersResult.fromMap(Map<String, dynamic> m) {
    return PaginatedOrdersResult(
      items: (m['items'] as List).map((e) => Order.fromMap(e as Map<String, dynamic>)).toList(),
      total: (m['total'] as num).toInt(),
      page: (m['page'] as num).toInt(),
      hasMore: m['has_more'] as bool? ?? false,
    );
  }
}

class PaginatedOrdersNotifier extends AsyncNotifier<PaginatedOrdersResult> {
  String? _statusCode;
  String? _search;
  String? _specialFilter;
  int _page = 0;
  static const int _pageSize = 20;

  String? get specialFilter => _specialFilter;
  String? get statusCode => _statusCode;

  @override
  Future<PaginatedOrdersResult> build() async {
    return _load(0);
  }

  Future<PaginatedOrdersResult> _load(int page) async {
    final biz = await ref.read(currentBusinessProvider.future);
    if (biz == null) return PaginatedOrdersResult.empty();

    final client = Supabase.instance.client;
    final res = await client.rpc('list_orders_page', params: {
      'p_business_id': biz.id,
      'p_status_code': _statusCode,
      'p_search': _search,
      'p_special_filter': _specialFilter,
      'p_page': page,
      'p_page_size': _pageSize,
    });

    return PaginatedOrdersResult.fromMap(res as Map<String, dynamic>);
  }

  Future<void> setStatusFilter(String? code) async {
    _statusCode = code;
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

  Future<void> setSpecialFilter(String? filter) async {
    _specialFilter = filter;
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
      state = AsyncData(PaginatedOrdersResult(
        items: [...current.items, ...next.items],
        total: next.total,
        page: next.page,
        hasMore: next.hasMore,
      ));
    } catch (_) {
      // Silent fail
    }
  }

  Future<void> refresh() async {
    _page = 0;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(0));
  }
}

final paginatedOrdersProvider =
    AsyncNotifierProvider<PaginatedOrdersNotifier, PaginatedOrdersResult>(
  PaginatedOrdersNotifier.new,
);
