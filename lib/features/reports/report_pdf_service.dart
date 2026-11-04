import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/models/business.dart';
import 'report_summary.dart';

class ReportPdfService {
  static Future<void> printReport({
    required Business business,
    required ReportSummary summary,
    required DateTime from,
    required DateTime to,
  }) async {
    final pdf = pw.Document();

    String fmtIdr(int amount) {
      final s = amount.toString();
      final buf = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
        buf.write(s[i]);
      }
      return 'Rp $buf';
    }

    String fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // HEADER
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(business.name, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                    if (business.address != null) pw.Text(business.address!),
                    if (business.contactPhone != null) pw.Text('Telp: ${business.contactPhone}'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('LAPORAN KEUANGAN', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    pw.Text('Periode: ${fmtDate(from)} - ${fmtDate(to)}'),
                    pw.Text('Dicetak: ${fmtDate(DateTime.now())}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 20),

            // SECTION 1: RINGKASAN PESANAN
            pw.Text('Ringkasan Pesanan', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Keterangan', 'Nilai'],
              data: [
                ['Total Pesanan', '${summary.ordersCount} Pesanan'],
                ['Nilai Pesanan', fmtIdr(summary.ordersTotal)],
                ['Pembayaran Diterima', fmtIdr(summary.paymentsReceived)],
                ['Sisa Tagihan (Piutang)', fmtIdr(summary.receivablesRemaining)],
              ],
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            ),
            pw.SizedBox(height: 20),

            // SECTION 2: ARUS KAS
            pw.Text('Arus Kas', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Keterangan', 'Nilai'],
              data: [
                ['Pemasukan (Lainnya)', fmtIdr(summary.income)],
                ['Pengeluaran', '- ${fmtIdr(summary.expense)}'],
                ['Pembayaran Pesanan', fmtIdr(summary.paymentsNet)],
              ],
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(color: PdfColors.green50, border: pw.Border.all(color: PdfColors.green)),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('LABA / ARUS KAS BERSIH', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(fmtIdr(summary.cashFlowNet), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // SECTION 3: SALDO AKUN
            pw.Text('Saldo Akun (Saat Ini)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            if (summary.balanceByAccount.isEmpty)
              pw.Text('Belum ada akun aktif.')
            else
              pw.TableHelper.fromTextArray(
                headers: ['Nama Akun', 'Saldo'],
                data: summary.balanceByAccount
                    .map((b) => [b.accountName, fmtIdr(b.balance)])
                    .toList(),
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              ),

            pw.SizedBox(height: 40),
            pw.Center(
              child: pw.Text(
                'Laporan ini dibuat otomatis oleh PayNote App',
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey600, fontSize: 10),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
