import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

/// Tombol dropdown untuk memilih bisnis aktif (D-01 multi-business).
/// Tampil di AppBar. Klik akan menampilkan bottom sheet berisi daftar bisnis.
class BusinessSelectorButton extends ConsumerWidget {
  const BusinessSelectorButton({super.key});

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final bizListAsync = ref.read(businessServiceProvider).listMyBusinesses();
    final list = await bizListAsync;
    if (!context.mounted) return;
    if (list.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Belum ada bisnis.')));
      return;
    }
    final current = ref.read(currentBusinessProvider).value;
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Pilih bisnis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            for (final b in list)
              ListTile(
                key: Key('business_pick_${b.id}'),
                leading: const Icon(Icons.storefront_outlined),
                title: Text(b.name),
                trailing: current?.id == b.id
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => Navigator.of(context).pop(b.id),
              ),
          ],
        ),
      ),
    );
    if (picked != null && context.mounted) {
      await ref.read(currentBusinessProvider.notifier).select(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biz = ref.watch(currentBusinessProvider).value;
    return TextButton.icon(
      key: const Key('business_selector_button'),
      onPressed: () => _pick(context, ref),
      icon: const Icon(Icons.storefront_outlined),
      label: Text(biz?.name ?? 'Pilih bisnis', overflow: TextOverflow.ellipsis),
    );
  }
}
