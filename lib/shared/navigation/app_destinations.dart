import 'package:flutter/material.dart';
import '../../shared/permissions/app_permission.dart';

enum AppDestination {
  dashboard, orders, customers, payments, transactions, transfers, reports, members, products, sync, settings,
}

extension AppDestinationX on AppDestination {
  bool get isPrimary => [AppDestination.dashboard, AppDestination.orders, AppDestination.customers].contains(this);
  
  String get label => switch (this) { 
    AppDestination.dashboard => 'Dashboard', 
    AppDestination.orders => 'Pesanan', 
    AppDestination.customers => 'Pelanggan', 
    AppDestination.payments => 'Pembayaran', 
    AppDestination.transactions => 'Transaksi', 
    AppDestination.transfers => 'Transfer', 
    AppDestination.reports => 'Laporan', 
    AppDestination.members => 'Anggota & Undangan', 
    AppDestination.products => 'Master Produk', 
    AppDestination.sync => 'Sinkronisasi', 
    AppDestination.settings => 'Pengaturan' 
  };
  
  String get route => switch (this) { 
    AppDestination.dashboard => '/app/dashboard', 
    AppDestination.orders => '/app/orders', 
    AppDestination.customers => '/app/customers', 
    AppDestination.payments => '/app/payments', 
    AppDestination.transactions => '/app/transactions', 
    AppDestination.transfers => '/app/transfers', 
    AppDestination.reports => '/app/reports', 
    AppDestination.members => '/app/members', 
    AppDestination.products => '/app/products', 
    AppDestination.sync => '/app/sync', 
    AppDestination.settings => '/app/settings' 
  };
  
  IconData get icon => switch (this) { 
    AppDestination.dashboard => Icons.dashboard, 
    AppDestination.orders => Icons.receipt_long, 
    AppDestination.customers => Icons.people, 
    AppDestination.payments => Icons.payment, 
    AppDestination.transactions => Icons.swap_horiz, 
    AppDestination.transfers => Icons.compare_arrows, 
    AppDestination.reports => Icons.bar_chart, 
    AppDestination.members => Icons.group, 
    AppDestination.products => Icons.inventory, 
    AppDestination.sync => Icons.cloud_sync, 
    AppDestination.settings => Icons.settings 
  };
  
  AppPermission? get requiredPermission => switch (this) { 
    AppDestination.members => AppPermission.manageMembers, 
    AppDestination.settings => AppPermission.editBusinessProfile, 
    _ => null 
  };
}