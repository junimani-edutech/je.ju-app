import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers.dart';
import 'product.dart';

class PaginatedProductsResult {
  final List<Product> items;
  final int total;
  final int page;
  final bool hasMore;

  PaginatedProductsResult({
    required this.items,
    required this.total,
    required this.page,
    required this.hasMore,
  });

  factory PaginatedProductsResult.empty() =>
      PaginatedProductsResult(items: [], total: 0, page: 0, hasMore: false);

  factory PaginatedProductsResult.fromMap(Map<String, dynamic> m) {
    return PaginatedProductsResult(
      items: (m['items'] as List)
          .map((e) => Product.fromMap(e as Map<String, dynamic>))
          .toList(),
      total: (m['total'] as num).toInt(),
      page: (m['page'] as num).toInt(),
      hasMore: m['has_more'] as bool? ?? false,
    );
  }
}

class PaginatedProductsNotifier extends AsyncNotifier<PaginatedProductsResult> {
  String? _search;
  String? _category;
  bool _includeArchived = false;
  int _page = 0;
  static const int _pageSize = 20;

  bool get includeArchived => _includeArchived;

  @override
  Future<PaginatedProductsResult> build() async {
    return _load(0);
  }

  Future<PaginatedProductsResult> _load(int page) async {
    final biz = await ref.read(currentBusinessProvider.future);
    if (biz == null) return PaginatedProductsResult.empty();

    final client = Supabase.instance.client;
    final res = await client.rpc('list_products_page', params: {
      'p_business_id': biz.id,
      'p_search': _search,
      'p_category': _category,
      'p_include_archived': _includeArchived,
      'p_page': page,
      'p_page_size': _pageSize,
    });

    return PaginatedProductsResult.fromMap(res as Map<String, dynamic>);
  }

  Future<void> setSearch(String? query) async {
    _search = (query == null || query.isEmpty) ? null : query;
    _page = 0;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(0));
  }

  Future<void> setCategory(String? category) async {
    _category = category;
    _page = 0;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(0));
  }

  Future<void> setArchived(bool archived) async {
    _includeArchived = archived;
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
      state = AsyncData(PaginatedProductsResult(
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

final paginatedProductsProvider =
    AsyncNotifierProvider<PaginatedProductsNotifier, PaginatedProductsResult>(
  PaginatedProductsNotifier.new,
);
