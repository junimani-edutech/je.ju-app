import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/models/business.dart';
import '../../features/customers/customer.dart';
import 'order.dart';

class InvoiceService {
  static Future<void> printInvoice(
    Order order,
    List<OrderItem> items,
    Business business,
    Customer? customer, // ✅ Tambahan data pelanggan
  ) async {
    final pdf = pw.Document();

    // Format Rupiah
    String fmtIdr(int amount) {
      final s = amount.toString();
      final buf = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
        buf.write(s[i]);
      }
      return 'Rp $buf';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // HEADER TOKO
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      business.name,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (business.address != null) pw.Text(business.address!),
                    if (business.contactPhone != null) pw.Text('Telp: ${business.contactPhone}'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text('No: ${order.orderNumber}'),
                    pw.Text('Tanggal: ${order.orderDate.toIso8601String().substring(0, 10)}'),
                    if (order.dueDate != null)
                      pw.Text('Kirim: ${order.dueDate!.toIso8601String().substring(0, 10)}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 10),

            // INFO PELANGGAN
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Kepada Yth:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(customer?.name ?? 'Pelanggan Umum'),
                      if (customer?.phone != null) pw.Text(customer!.phone!),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // TABEL ITEM
            pw.TableHelper.fromTextArray(
              headers: ['Deskripsi', 'Qty', 'Harga Satuan', 'Total'],
              data: items
                  .map(
                    (item) => [
                      item.description,
                      item.quantity.toString(),
                      fmtIdr(item.unitPrice),
                      fmtIdr(item.lineTotal),
                    ],
                  )
                  .toList(),
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 20),

            // RINGKASAN BIAYA
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 200,
                child: pw.Column(
                  children: [
                    _pdfRow('Subtotal', fmtIdr(order.subtotalAmount)),
                    if (order.discountAmount > 0) _pdfRow('Diskon', '-${fmtIdr(order.discountAmount)}'),
                    if (order.additionalFeeAmount > 0) _pdfRow('Biaya Tambahan', fmtIdr(order.additionalFeeAmount)),
                    if (order.shippingAmount > 0) _pdfRow('Ongkir', fmtIdr(order.shippingAmount)),
                    pw.Divider(),
                    _pdfRow('Total', fmtIdr(order.totalAmount), bold: true),
                    _pdfRow('Dibayar', fmtIdr(order.paidAmount)),
                    _pdfRow('Sisa', fmtIdr(order.totalAmount - order.paidAmount), isRed: true),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 40),

            // FOOTER
            pw.Center(
              child: pw.Text(
                'Terima kasih atas kepercayaan Anda!',
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey600),
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

  static pw.Widget _pdfRow(String label, String value, {bool bold = false, bool isRed = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isRed ? PdfColors.red : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
