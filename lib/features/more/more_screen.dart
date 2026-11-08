import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../shared/permissions/app_permission.dart';
import '../../shared/permissions/permission_provider.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final permissions = ref.watch(currentPermissionsProvider);
    final user = ref.watch(authStateProvider).value;
    final member = ref.watch(currentMemberProvider).value;

    final emailStr = user?.email ?? 'User';
    final initial = emailStr.isNotEmpty ? emailStr[0].toUpperCase() : 'U';
    final roleStr = member?.role.toUpperCase() ?? 'MEMBER';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lainnya', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. PROFIL CARD PREMIUM
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    initial,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emailStr.split('@').first,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        emailStr,
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          roleStr,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () => context.go('/app/more/settings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. DAFTAR MENU DENGAN IKON PASTEL
          _buildMenuItem(
            context,
            icon: Icons.payments_outlined,
            iconBgColor: Colors.blue.withValues(alpha: 0.1),
            iconColor: Colors.blue,
            title: 'Pembayaran',
            subtitle: 'Kelola pembayaran masuk',
            onTap: () => context.go('/app/more/payments'),
          ),
          _buildMenuItem(
            context,
            icon: Icons.receipt_long_outlined,
            iconBgColor: Colors.orange.withValues(alpha: 0.1),
            iconColor: Colors.orange,
            title: 'Transaksi',
            subtitle: 'Riwayat pemasukan & pengeluaran',
            onTap: () => context.go('/app/more/transactions'),
          ),

          _buildMenuItem(
            context,
            icon: Icons.notifications_active_outlined,
            iconBgColor: Colors.red.withValues(alpha: 0.1),
            iconColor: Colors.red.shade700,
            title: 'Tagihan Belum Lunas',
            subtitle: 'Pengingat piutang pelanggan',
            onTap: () => context.go('/app/more/ar-reminder'),
          ),

          _buildMenuItem(
            context,
            icon: Icons.savings_outlined,
            iconBgColor: Colors.amber.withValues(alpha: 0.1),
            iconColor: Colors.amber.shade700,
            title: 'Kelebihan Bayar',
            subtitle: 'History kelebihan dari pelanggan',
            onTap: () => context.go('/app/more/excess-history'),
          ),
          _buildMenuItem(
            context,
            icon: Icons.swap_horiz,
            iconBgColor: Colors.purple.withValues(alpha: 0.1),
            iconColor: Colors.purple,
            title: 'Transfer',
            subtitle: 'Pindah dana antar akun',
            onTap: () => context.go('/app/more/transfers'),
          ),
          _buildMenuItem(
            context,
            icon: Icons.bar_chart_outlined,
            iconBgColor: Colors.green.withValues(alpha: 0.1),
            iconColor: Colors.green,
            title: 'Laporan',
            subtitle: 'Analitik dan ringkasan bisnis',
            onTap: () => context.go('/app/more/reports'),
          ),

          _buildMenuItem(
            context,
            icon: Icons.assignment_ind_outlined,
            iconBgColor: Colors.lightBlue.withValues(alpha: 0.1),
            iconColor: Colors.lightBlue,
            title: 'Laporan Per Kasir',
            subtitle: 'Performa staf & shift',
            onTap: () => context.go('/app/more/staff-report'),
          ),
          // ✅ TAMBAHAN: Menu Produk Terlaris
          _buildMenuItem(
            context,
            icon: Icons.leaderboard_outlined,
            iconBgColor: Colors.pink.withValues(alpha: 0.1),
            iconColor: Colors.pink,
            title: 'Produk Terlaris',
            subtitle: 'Analisis barang paling laku',
            onTap: () => context.go('/app/more/product-report'),
          ),
          _buildMenuItem(
            context,
            icon: Icons.inventory_2_outlined,
            iconBgColor: Colors.teal.withValues(alpha: 0.1),
            iconColor: Colors.teal,
            title: 'Produk & Jasa',
            subtitle: 'Daftar barang & jasa yang dijual',
            onTap: () => context.go('/app/more/products'),
          ),
          _buildMenuItem(
            context,
            icon: Icons.inventory,
            iconBgColor: Colors.brown.withValues(alpha: 0.1),
            iconColor: Colors.brown,
            title: 'Stok Bahan Baku',
            subtitle: 'Pantau stok deterjen, plastik, dll',
            onTap: () => context.go('/app/more/inventory'),
          ),

          if (permissions.contains(AppPermission.manageMembers))
            _buildMenuItem(
              context,
              icon: Icons.history,
              iconBgColor: Colors.grey.withValues(alpha: 0.1),
              iconColor: Colors.grey.shade700,
              title: 'Log Aktivitas',
              subtitle: 'Riwayat perubahan data oleh staf',
              onTap: () => context.go('/app/more/audit-log'),
            ),

          if (permissions.contains(AppPermission.editBusinessProfile))
            _buildMenuItem(
              context,
              icon: Icons.backup_outlined,
              iconBgColor: Colors.deepPurple.withValues(alpha: 0.1),
              iconColor: Colors.deepPurple,
              title: 'Backup Data',
              subtitle: 'Cadangkan seluruh data bisnis',
              onTap: () => context.go('/app/more/backup'),
            ),

          if (permissions.contains(AppPermission.manageMembers))
            _buildMenuItem(
              context,
              icon: Icons.people_outline,
              iconBgColor: Colors.indigo.withValues(alpha: 0.1),
              iconColor: Colors.indigo,
              title: 'Anggota & Undangan',
              subtitle: 'Kelola akses kasir & admin',
              onTap: () => context.go('/app/more/members'),
            ),

          if (!kIsWeb)
            _buildMenuItem(
              context,
              icon: Icons.cloud_upload_outlined,
              iconBgColor: Colors.cyan.withValues(alpha: 0.1),
              iconColor: Colors.cyan,
              title: 'Status Sinkronisasi',
              subtitle: 'Cek antrean data offline',
              onTap: () => context.go('/app/more/sync'),
            ),
          const SizedBox(height: 16),
          _buildMenuItem(
            context,
            icon: Icons.logout,
            iconBgColor: Colors.red.withValues(alpha: 0.1),
            iconColor: Colors.red,
            title: 'Keluar',
            subtitle: 'Logout dari akun ini',
            titleColor: Colors.red,
            onTap: () async {
              await ref.read(authServiceProvider).signOut();
            },
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'PayNote v1.1.0',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: titleColor ?? Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}