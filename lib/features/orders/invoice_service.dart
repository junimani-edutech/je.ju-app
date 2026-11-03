import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'order.dart';

class InvoiceService {
  static Future<void> printInvoice(
    Order order,
    List<OrderItem> items,
    String businessName,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(level: 0, child: pw.Text('INVOICE - $businessName')),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('No. Pesanan: ${order.orderNumber}'),
                pw.Text(
                  'Tanggal: ${order.orderDate.toIso8601String().substring(0, 10)}',
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Deskripsi', 'Qty', 'Harga Satuan', 'Total'],
              data: items
                  .map(
                    (item) => [
                      item.description,
                      item.quantity.toString(),
                      'Rp ${item.unitPrice}',
                      'Rp ${item.lineTotal}',
                    ],
                  )
                  .toList(),
              border: pw.TableBorder.all(),
            ),
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Total Tagihan: Rp ${order.totalAmount}',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 16,
                ),
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
