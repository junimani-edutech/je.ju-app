import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/utils/format.dart';
import '../customers/customer.dart';
import '../customers/customers_providers.dart';
import 'ar_reminder_providers.dart';
import 'order.dart';
import 'widgets/order_detail_sheet.dart';

class ArReminderScreen extends ConsumerWidget {
  const ArReminderScreen({super.key});

  Future<void> _sendWhatsApp(BuildContext context, Order order, Customer? customer) async {
    if (customer == null || customer.phone == null || customer.phone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor HP pelanggan tidak ditemukan.'), backgroundColor: Colors.red),
      );
      return;
    }

    String phone = customer.phone!.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('0')) phone = '62${phone.substring(1)}';

    final remaining = order.totalAmount - order.paidAmount;
    final message = 'Halo *${customer.name}*,\n\n'
        'Kami ingin mengingatkan bahwa pesanan Anda dengan nomor *${order.orderNumber}* '
        'memiliki sisa tagihan sebesar *${formatIdr(remaining)}*.\n\n'
        'Mohon segera diselesaikan agar pesanan dapat diproses dengan lancar. '
        'Terima kasih atas kepercayaan Anda.';

    final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp tidak ditemukan.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final arAsync = ref.watch(arReminderProvider);
    final totalAsync = ref.watch(totalReceivablesProvider);
    final customersAsync = ref.watch(activeCustomersProvider);
    
    final customerMap = <String, Customer>{
      for (final c in customersAsync.value ?? <Customer>[]) c.id: c,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tagihan Belum Lunas', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Kartu Total Piutang
          totalAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (total) => Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Piutang', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    formatIdr(total),
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text('Segera tagih agar kas tetap sehat', style: TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              ),
            ),
          ),
          
          // List Piutang
          Expanded(
            child: arAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Gagal memuat: $e')),
              data: (orders) {
                if (orders.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                          ),
                          const SizedBox(height: 24),
                          Text('Semua Lunas!', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Tidak ada tagihan yang perlu ditagih.', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }
                
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final o = orders[i];
                    final customer = o.customerId != null ? customerMap[o.customerId] : null;
                    final remaining = o.totalAmount - o.paidAmount;
                    
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => OrderDetailSheet.show(context, order: o),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(o.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: o.paymentStatus == 'partial' ? Colors.orange.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      o.paymentStatus == 'partial' ? 'DP' : 'Belum Bayar',
                                      style: TextStyle(
                                        fontSize: 10, 
                                        fontWeight: FontWeight.bold,
                                        color: o.paymentStatus == 'partial' ? Colors.orange.shade800 : Colors.red.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                customer?.name ?? 'Pelanggan Umum',
                                style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                              ),
                              Text(formatDateId(o.orderDate), style: theme.textTheme.bodySmall),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Sisa Tagihan', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      Text(
                                        formatIdr(remaining),
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _sendWhatsApp(context, o, customer),
                                    icon: const Icon(Icons.chat, size: 16),
                                    label: const Text('Tagih'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.green.shade700,
                                      side: BorderSide(color: Colors.green.shade700),
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
