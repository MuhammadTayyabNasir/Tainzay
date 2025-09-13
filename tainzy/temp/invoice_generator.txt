import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:tainzy/app/models/models.dart';

class InvoiceGenerator {
  static Future<void> generateAndShowInvoice(Transaction transaction, Patient patient) async {
    final pdf = await _generatePdf(transaction, patient);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf);
  }

  static Future<Uint8List> _generatePdf(Transaction transaction, Patient patient) async {
    final pdf = pw.Document();

    // Load custom fonts for styling
    final font = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(boldFont),
              pw.SizedBox(height: 20),
              _buildCustomerInfo(patient, boldFont),
              pw.SizedBox(height: 20),
              _buildInvoiceInfo(transaction, boldFont),
              pw.SizedBox(height: 20),
              _buildInvoiceTable(transaction, font, boldFont),
              pw.SizedBox(height: 20),
              _buildTotal(transaction, boldFont),
              pw.Spacer(),
              _buildFooter(font),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(pw.Font boldFont) {
    return pw.Column(
      children: [
        pw.Text('PRIME CARE', style: pw.TextStyle(font: boldFont, fontSize: 24)),
        pw.SizedBox(height: 5),
        pw.Text('12-A, II-I Education Town, Wahdat Road, Lahore'),
        pw.Text('Email: primecare12a@gmail.com'),
        pw.Text('PTCL # 042-35422541'),
        pw.SizedBox(height: 15),
        pw.Text('SALES INVOICE', style: pw.TextStyle(font: boldFont, fontSize: 16)),
      ],
      crossAxisAlignment: pw.CrossAxisAlignment.center,
    );
  }

  static pw.Widget _buildCustomerInfo(Patient patient, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('M/S ${patient.name}', style: pw.TextStyle(font: boldFont)),
          pw.Text(patient.city),
        ],
      ),
    );
  }

  static pw.Widget _buildInvoiceInfo(Transaction transaction, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Dated'),
            pw.SizedBox(height: 10),
            pw.Text('Invoice No'),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(DateFormat('dd-MMM-yy').format(transaction.dateOfPurchase), style: pw.TextStyle(font: boldFont)),
            pw.SizedBox(height: 10),
            pw.Text(transaction.id!.substring(0, 8).toUpperCase(), style: pw.TextStyle(font: boldFont)), // Using part of transaction ID
          ]),
        ],
      ),
    );
  }

  static pw.Widget _buildInvoiceTable(Transaction transaction, pw.Font font, pw.Font boldFont) {
    final headers = ['Item ID', 'Item Title', 'Batch No', 'Qty', 'Sale Price', 'Sale Amount', '%', 'Discount Amount', 'Net Sale'];

    final basePrice = transaction.saleAmount + transaction.discountAmount;
    final item = [
      'N/A', // Item ID
      transaction.productName,
      'N/A', // Batch No
      transaction.qty.toString(),
      (basePrice / transaction.qty).toStringAsFixed(2),
      basePrice.toStringAsFixed(2),
      transaction.discountPercentage.toStringAsFixed(0),
      transaction.discountAmount.toStringAsFixed(2),
      transaction.saleAmount.toStringAsFixed(2),
    ];

    return pw.Table.fromTextArray(
      headers: headers,
      data: [item],
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(font: boldFont, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.center,
        7: pw.Alignment.centerRight,
        8: pw.Alignment.centerRight,
      },
    );
  }

  static pw.Widget _buildTotal(Transaction transaction, pw.Font boldFont) {
    final baseTotal = transaction.saleAmount + transaction.discountAmount;
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text('TOTAL AMOUNT', style: pw.TextStyle(font: boldFont)),
        pw.SizedBox(width: 40),
        pw.Container(
          width: 250,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(baseTotal.toStringAsFixed(2), style: pw.TextStyle(font: boldFont)),
              pw.Text(transaction.discountAmount.toStringAsFixed(2), style: pw.TextStyle(font: boldFont)),
              pw.Text(transaction.saleAmount.toStringAsFixed(2), style: pw.TextStyle(font: boldFont)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Text('Form 2-A, (See rules 19 & 30)', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)),
        pw.Text(
          'WARRANTY: Under section 23(1)(i) of the Drugs Act 1976. I Zahid Hussain being person resident in Pakistan Carring on business on 12-A 11-I Education Town, Wahdat Road, Lahore, under the name of Prime Care do hereby give this warranty that the drugs described and sold by us, specified and contained in this invoice do not contravene in any way the provision of section 23 of the Drug Act 1976.',
          textAlign: pw.TextAlign.justify,
          style: pw.TextStyle(font: font, fontSize: 8),
        ),
      ],
    );
  }
}