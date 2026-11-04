import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../finance/finance_providers.dart';

class ExpenseFormSheet extends ConsumerStatefulWidget {
  const ExpenseFormSheet({super.key});

  @override
  ConsumerState<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends ConsumerState<ExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  
  String? _selectedCategory = 'Bahan Baku';
  String? _selectedAccountId; 
  bool _isLoading = false;
  
  final List<String> _categories = [
    'Bahan Baku',
    'Operasional',
    'Gaji',
    'Sewa',
    'Lain-lain'
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      // 1. Ambil dan bersihkan nilai nominal
      final amountStr = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final amount = int.parse(amountStr);
      final notes = _descController.text.trim();
      
      // 2. Gabungkan kategori dan catatan (karena method record tidak punya parameter kategori)
      final fullDescription = notes.isEmpty 
          ? _selectedCategory! 
          : '$_selectedCategory! - $notes';

      // 3. Panggil provider untuk menyimpan ke database
      await ref.read(transactionsProvider.notifier).record(
        type: 'expense',
        amount: amount,
        description: fullDescription,
        accountId: _selectedAccountId,
      );

      if (mounted) {
        context.pop(); // Tutup bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengeluaran berhasil dicatat!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mencatat pengeluaran: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mengambil data akun (Kas/Bank) dari database Anda
    final accountsAsync = ref.watch(accountBalancesProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Catat Pengeluaran',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Input Nominal
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nominal (Rp)',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Nominal wajib diisi';
                final parsed = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
                if (parsed == null || parsed <= 0) return 'Nominal tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 12),
            
            // Pilihan Kategori
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
            const SizedBox(height: 12),
            
            // Pilihan Sumber Dana (Dinamis dari Database)
            accountsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Gagal memuat akun: $e'),
              data: (accounts) {
                if (accounts.isEmpty) {
                  return const Text('Belum ada akun Kas/Bank. Buat di Pengaturan.');
                }
                return DropdownButtonFormField<String>(
                  initialValue: _selectedAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Sumber Dana (Kas/Bank)',
                    border: OutlineInputBorder(),
                  ),
                  items: accounts.map((acc) {
                    return DropdownMenuItem(
                      value: acc.accountId,
                      child: Text(acc.accountName),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedAccountId = v),
                  validator: (v) => v == null ? 'Pilih sumber dana' : null,
                );
              },
            ),
            const SizedBox(height: 12),
            
            // Input Catatan
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Catatan (Opsional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            
            // Tombol Simpan
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2)
                    )
                  : const Text('Simpan Pengeluaran'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}