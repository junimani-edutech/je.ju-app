import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../shared/widgets/skeleton_loader.dart';
import 'customer.dart';
import 'customers_providers.dart';
import 'widgets/customer_form_sheet.dart';
import 'widgets/customer_list_tile.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Customer> _applyFilter(List<Customer> list) {
    if (_query.isEmpty) return list;
    final q = _query.toLowerCase();
    return list.where((c) {
      if (c.name.toLowerCase().contains(q)) return true;
      if (c.phone != null && c.phone!.toLowerCase().contains(q)) return true;
      if (c.email != null && c.email!.toLowerCase().contains(q)) return true;
      return false;
    }).toList();
  }

  Future<void> _openCreate() => CustomerFormSheet.show(context);

  Future<void> _openEdit(Customer c) =>
      CustomerFormSheet.show(context, initial: c);

  Future<void> _archive(Customer c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Arsipkan pelanggan?'),
        content: Text(
          '"${c.name}" akan dipindahkan ke arsip. '
          'Data tetap tersimpan dan bisa dipulihkan.',
        ),
        actions: [
          TextButton(
            key: const Key('customer_archive_cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('customer_archive_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Arsipkan'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(customersProvider.notifier).archive(c.id);
  }

  Future<void> _restore(Customer c) async {
    await ref.read(customersProvider.notifier).restore(c.id);
  }

  Future<void> _confirmHardDelete(Customer c) async {
    try {
      final canDelete = await ref.read(customersProvider.notifier).canHardDelete(c.id);
      if (!canDelete) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Tidak Bisa Hapus'),
              content: Text('"${c.name}" sudah pernah dipakai di pesanan. Untuk menjaga integritas laporan, gunakan opsi "Arsipkan" saja.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Mengerti')),
              ],
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hapus Permanen?'),
          content: Text('"${c.name}" akan dihapus selamanya. Tindakan ini tidak dapat dibatalkan.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus Permanen'),
            ),
          ],
        ),
      );

      if (ok == true) {
        await ref.read(customersProvider.notifier).delete(c.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pelanggan dihapus permanen'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canWrite = ref.watch(currentMemberProvider).value?.canWrite ?? false;
    final activeAsync = ref.watch(activeCustomersProvider);
    final archivedAsync = ref.watch(archivedCustomersProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pelanggan', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            tabs: [
              Tab(key: Key('customers_tab_active'), text: 'Aktif'),
              Tab(key: Key('customers_tab_archived'), text: 'Arsip'),
            ],
          ),
        ),
        body: Column(
          children: [
            // ✅ PERBAIKAN: Search Bar Modern
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                key: const Key('customers_search'),
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari nama, telepon, atau email...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          key: const Key('customers_search_clear'),
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildList(activeAsync, isArchivedTab: false, canWrite: canWrite),
                  _buildList(archivedAsync, isArchivedTab: true, canWrite: canWrite),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: canWrite
            ? FloatingActionButton.extended(
                key: const Key('customers_fab'),
                onPressed: _openCreate,
                icon: const Icon(Icons.person_add),
                label: const Text('Tambah'),
              )
            : null,
      ),
    );
  }

  Widget _buildList(
    AsyncValue<List<Customer>> async, {
    required bool isArchivedTab,
    required bool canWrite,
  }) {
    return async.when(
      loading: () => const SkeletonList(),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Gagal memuat: $e'),
        ),
      ),
      data: (list) {
        final filtered = _applyFilter(list);
        if (filtered.isEmpty) {
          if (_query.isNotEmpty) {
            return _buildEmpty(
              icon: Icons.search_off,
              title: 'Tidak ada hasil',
              subtitle: 'Tidak ada pelanggan yang cocok dengan "$_query".',
            );
          }
          if (isArchivedTab) {
            return _buildEmpty(
              icon: Icons.archive_outlined,
              title: 'Belum ada arsip',
              subtitle: 'Pelanggan yang diarsipkan akan muncul di sini.',
            );
          }
          return _buildEmpty(
            icon: Icons.people_outline,
            title: 'Belum ada pelanggan',
            subtitle: canWrite
                ? 'Tekan tombol Tambah untuk menambah pelanggan pertama Anda.'
                : 'Pelanggan akan muncul di sini setelah ditambahkan.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final c = filtered[i];
            return CustomerListTile(
              customer: c,
              canWrite: canWrite,
              onTap: canWrite ? () => _openEdit(c) : null,
              onArchive: canWrite ? () => _archive(c) : null,
              onRestore: canWrite ? () => _restore(c) : null,
              onDelete: canWrite ? () => _confirmHardDelete(c) : null,
            );
          },
        );
      },
    );
  }

  // ✅ PERBAIKAN: Empty State Premium
  Widget _buildEmpty({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
