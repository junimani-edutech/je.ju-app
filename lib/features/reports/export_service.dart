import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

import '../finance/transaction.dart';
import '../orders/order.dart';
import '../payments/payment.dart';
import 'report_summary.dart';

class ExportBundle {
  const ExportBundle({
    required this.filename,
    required this.bytes,
    required this.mimeType,
  });

  final String filename;
  final Uint8List bytes;
  final String mimeType;
}

abstract class ExportService {
  /// CSV berisi: baris header ringkasan + blok orders.
  ExportBundle ordersCsv({
    required String businessId,
    required ReportSummary summary,
    required List<Order> orders,
  });

  /// XLSX berisi 1 sheet "Summary" + 1 sheet "Orders".
  ExportBundle ordersXlsx({
    required String businessId,
    required ReportSummary summary,
    required List<Order> orders,
  });

  /// CSV berisi ringkasan + pembayaran.
  ExportBundle paymentsCsv({
    required String businessId,
    required ReportSummary summary,
    required List<Payment> payments,
  });

  /// CSV berisi ringkasan + transaksi.
  ExportBundle transactionsCsv({
    required String businessId,
    required ReportSummary summary,
    required List<Transaction> transactions,
  });
}

class DefaultExportService implements ExportService {
  const DefaultExportService();

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fileRange(ReportSummary s) => '${_dateStr(s.from)}_${_dateStr(s.to)}';

  /// Tambahkan UTF-8 BOM di awal agar Excel baca sebagai UTF-8.
  Uint8List _csvBytes(List<List<dynamic>> rows) {
    final csvStr = const ListToCsvConverter().convert(rows);
    final withBom = '\uFEFF$csvStr';
    return Uint8List.fromList(utf8.encode(withBom));
  }

  List<List<dynamic>> _summaryRows(ReportSummary s) => [
    ['Laporan', ''],
    ['Dari', _dateStr(s.from)],
    ['Sampai', _dateStr(s.to)],
    ['Jumlah pesanan', s.ordersCount],
    ['Total pesanan', s.ordersTotal],
    ['Pembayaran diterima', s.paymentsReceived],
    ['Sisa tagihan', s.receivablesRemaining],
    ['Pemasukan', s.income],
    ['Pengeluaran', s.expense],
    ['Pembayaran net', s.paymentsNet],
    ['Arus kas bersih', s.cashFlowNet],
    [''],
  ];

  @override
  ExportBundle ordersCsv({
    required String businessId,
    required ReportSummary summary,
    required List<Order> orders,
  }) {
    final rows = <List<dynamic>>[
      ..._summaryRows(summary),
      [
        'Tanggal',
        'Nomor',
        'Pelanggan',
        'Subtotal',
        'Diskon',
        'Biaya tambahan',
        'Ongkir',
        'Total',
        'Dibayar',
        'Status bayar',
        'Status order',
        'Catatan',
      ],
      for (final o in orders)
        [
          _dateStr(o.orderDate),
          o.orderNumber,
          o.customerId ?? '',
          o.subtotalAmount,
          o.discountAmount,
          o.additionalFeeAmount,
          o.shippingAmount,
          o.totalAmount,
          o.paidAmount,
          o.paymentStatus,
          o.isCancelled ? 'cancelled' : o.status,
          o.notes ?? '',
        ],
    ];
    return ExportBundle(
      filename: 'orders_${_fileRange(summary)}.csv',
      bytes: _csvBytes(rows),
      mimeType: 'text/csv;charset=utf-8',
    );
  }

  @override
  ExportBundle ordersXlsx({
    required String businessId,
    required ReportSummary summary,
    required List<Order> orders,
  }) {
    final excel = Excel.createExcel();

    // Sheet 1: Summary
    final summarySheet = excel['Summary'];
    final sumRows = _summaryRows(summary);
    for (var r = 0; r < sumRows.length; r++) {
      for (var c = 0; c < sumRows[r].length; c++) {
        final v = sumRows[r][c];
        summarySheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
            .value = v == null
            ? null
            : TextCellValue(v.toString());
      }
    }

    // Sheet 2: Orders
    final ordersSheet = excel['Orders'];
    final headerRow = [
      'Tanggal',
      'Nomor',
      'Pelanggan',
      'Subtotal',
      'Diskon',
      'Biaya tambahan',
      'Ongkir',
      'Total',
      'Dibayar',
      'Status bayar',
      'Status order',
      'Catatan',
    ];
    for (var c = 0; c < headerRow.length; c++) {
      ordersSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
          .value = TextCellValue(
        headerRow[c],
      );
    }
    for (var r = 0; r < orders.length; r++) {
      final o = orders[r];
      final row = <dynamic>[
        _dateStr(o.orderDate),
        o.orderNumber,
        o.customerId ?? '',
        o.subtotalAmount,
        o.discountAmount,
        o.additionalFeeAmount,
        o.shippingAmount,
        o.totalAmount,
        o.paidAmount,
        o.paymentStatus,
        o.isCancelled ? 'cancelled' : o.status,
        o.notes ?? '',
      ];
      for (var c = 0; c < row.length; c++) {
        final v = row[c];
        ordersSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
            .value = v == null
            ? null
            : TextCellValue(v.toString());
      }
    }

    final bytes = excel.encode();
    return ExportBundle(
      filename: 'orders_${_fileRange(summary)}.xlsx',
      bytes: Uint8List.fromList(bytes ?? const []),
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  @override
  ExportBundle paymentsCsv({
    required String businessId,
    required ReportSummary summary,
    required List<Payment> payments,
  }) {
    final rows = <List<dynamic>>[
      ..._summaryRows(summary),
      [
        'Tanggal',
        'Order ID',
        'Nominal',
        'Metode',
        'Akun',
        'Referensi',
        'Catatan',
        'Status',
        'Reversal',
      ],
      for (final p in payments)
        [
          _dateStr(p.paymentDate),
          p.orderId,
          p.amount,
          p.paymentMethodId ?? '',
          p.accountId ?? '',
          p.reference ?? '',
          p.notes ?? '',
          p.status,
          p.isReversal ? 'ya' : 'tidak',
        ],
    ];
    return ExportBundle(
      filename: 'payments_${_fileRange(summary)}.csv',
      bytes: _csvBytes(rows),
      mimeType: 'text/csv;charset=utf-8',
    );
  }

  @override
  ExportBundle transactionsCsv({
    required String businessId,
    required ReportSummary summary,
    required List<Transaction> transactions,
  }) {
    final rows = <List<dynamic>>[
      ..._summaryRows(summary),
      [
        'Tanggal',
        'Tipe',
        'Nominal',
        'Kategori',
        'Akun',
        'Deskripsi',
        'Referensi',
        'Status',
        'Reversal',
      ],
      for (final t in transactions)
        [
          _dateStr(t.transactionDate),
          t.type,
          t.amount,
          t.categoryId ?? '',
          t.accountId ?? '',
          t.description,
          t.reference ?? '',
          t.status,
          t.isReversal ? 'ya' : 'tidak',
        ],
    ];
    return ExportBundle(
      filename: 'transactions_${_fileRange(summary)}.csv',
      bytes: _csvBytes(rows),
      mimeType: 'text/csv;charset=utf-8',
    );
  }
}
