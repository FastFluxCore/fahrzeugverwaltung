import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/entry.dart';
import '../models/vehicle.dart';

class ExportService {
  final _firestore = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> _vehicleRef(String vehicleId) =>
      _firestore.collection('users').doc(_uid).collection('vehicles').doc(vehicleId);

  /// Fetches all entries for a vehicle (non-streaming, one-shot).
  Future<List<Entry>> _fetchAllEntries(String vehicleId) async {
    final ref = _vehicleRef(vehicleId);

    final results = await Future.wait([
      ref.collection('services').get(),
      ref.collection('fuelLogs').get(),
      ref.collection('otherCosts').get(),
    ]);

    final services = results[0].docs.map((d) => Entry.fromService(d.id, d.data())).toList();
    final fuelLogs = results[1].docs.map((d) => Entry.fromFuelLog(d.id, d.data())).toList();
    final otherCosts = results[2].docs.map((d) => Entry.fromOtherCost(d.id, d.data())).toList();

    final all = [...services, ...fuelLogs, ...otherCosts];
    all.sort((a, b) => a.date.compareTo(b.date));
    return all;
  }

  /// Generates a PDF vehicle history report.
  Future<Uint8List> generatePdf({
    required Vehicle vehicle,
    required String currency,
    required String distanceUnit,
    required String volumeUnit,
    bool includeServices = true,
    bool includeFuel = true,
    bool includeOtherCosts = true,
  }) async {
    final allEntries = await _fetchAllEntries(vehicle.id);
    final services = includeServices
        ? allEntries.where((e) => e.type == EntryType.service).toList()
        : <Entry>[];
    final fuelLogs = includeFuel
        ? allEntries.where((e) => e.type == EntryType.fuel).toList()
        : <Entry>[];
    final otherCosts = includeOtherCosts
        ? allEntries.where((e) => e.type == EntryType.otherCost).toList()
        : <Entry>[];

    final entries = [...services, ...fuelLogs, ...otherCosts];
    entries.sort((a, b) => a.date.compareTo(b.date));

    final totalCost = entries.fold<double>(0, (s, e) => s + e.cost);
    final serviceCost = services.fold<double>(0, (s, e) => s + e.cost);
    final fuelCost = fuelLogs.fold<double>(0, (s, e) => s + e.cost);
    final otherCostTotal = otherCosts.fold<double>(0, (s, e) => s + e.cost);

    final regular = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    final theme = pw.ThemeData.withFont(base: regular, bold: bold);

    final pdf = pw.Document(theme: theme);

    final headerStyle = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);
    final cellStyle = const pw.TextStyle(fontSize: 9);
    final sectionStyle = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);

    String fmtDate(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    String fmtCost(double c) => '${c.toStringAsFixed(2).replaceAll('.', ',')} $currency';

    // --- Page 1: Vehicle info + summary ---
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildPageHeader(vehicle, fmtDate),
        footer: (context) => _buildPageFooter(context),
        build: (context) => [
          // Vehicle details
          pw.SizedBox(height: 8),
          _buildVehicleInfo(vehicle, distanceUnit, fmtDate),
          pw.SizedBox(height: 24),

          // Summary
          pw.Text('Kostenübersicht', style: sectionStyle),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: headerStyle,
            cellStyle: cellStyle,
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            headers: ['Kategorie', 'Anzahl', 'Kosten'],
            data: [
              if (includeServices) ['Service & Werkstatt', '${services.length}', fmtCost(serviceCost)],
              if (includeFuel) ['Tankvorgänge', '${fuelLogs.length}', fmtCost(fuelCost)],
              if (includeOtherCosts) ['Sonstige Kosten', '${otherCosts.length}', fmtCost(otherCostTotal)],
              ['Gesamt', '${entries.length}', fmtCost(totalCost)],
            ],
          ),
          pw.SizedBox(height: 24),

          // Service history
          if (services.isNotEmpty) ...[
            pw.Text('Service-Historie', style: sectionStyle),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: headerStyle,
              cellStyle: cellStyle,
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              columnWidths: {
                0: const pw.FixedColumnWidth(65),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FixedColumnWidth(55),
                3: const pw.FixedColumnWidth(60),
                4: const pw.FlexColumnWidth(2),
                5: const pw.FlexColumnWidth(3),
              },
              headers: ['Datum', 'Art', distanceUnit, 'Kosten', 'Werkstatt', 'Notizen'],
              data: services.map((e) => [
                fmtDate(e.date),
                'Service',
                e.mileage?.toString() ?? '-',
                fmtCost(e.cost),
                e.workshop ?? '-',
                e.description,
              ]).toList(),
            ),
            pw.SizedBox(height: 24),
          ],

          // Fuel history
          if (fuelLogs.isNotEmpty) ...[
            pw.Text('Tank-Historie', style: sectionStyle),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: headerStyle,
              cellStyle: cellStyle,
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              columnWidths: {
                0: const pw.FixedColumnWidth(65),
                1: const pw.FixedColumnWidth(50),
                2: const pw.FixedColumnWidth(60),
                3: const pw.FixedColumnWidth(60),
                4: const pw.FixedColumnWidth(55),
                5: const pw.FlexColumnWidth(2),
              },
              headers: ['Datum', volumeUnit, '$currency/$volumeUnit', 'Kosten', distanceUnit, 'Tankstelle'],
              data: fuelLogs.map((e) => [
                fmtDate(e.date),
                e.liters?.toStringAsFixed(2) ?? '-',
                e.pricePerLiter?.toStringAsFixed(3) ?? '-',
                fmtCost(e.cost),
                e.mileage?.toString() ?? '-',
                e.station ?? '-',
              ]).toList(),
            ),
            pw.SizedBox(height: 24),
          ],

          // Other costs
          if (otherCosts.isNotEmpty) ...[
            pw.Text('Sonstige Kosten', style: sectionStyle),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: headerStyle,
              cellStyle: cellStyle,
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              columnWidths: {
                0: const pw.FixedColumnWidth(65),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FixedColumnWidth(70),
              },
              headers: ['Datum', 'Kategorie', 'Beschreibung', 'Kosten'],
              data: otherCosts.map((e) => [
                fmtDate(e.date),
                e.category ?? '-',
                e.description,
                fmtCost(e.cost),
              ]).toList(),
            ),
            pw.SizedBox(height: 24),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  /// Generates a second PDF containing all attached document images.
  Future<Uint8List?> generateDocumentsPdf({
    required Vehicle vehicle,
  }) async {
    final allEntries = await _fetchAllEntries(vehicle.id);
    final withDocs = allEntries.where((e) => e.documentUrls.isNotEmpty).toList();
    if (withDocs.isEmpty) return null;

    final regular = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    final pdf = pw.Document(theme: pw.ThemeData.withFont(base: regular, bold: bold));

    for (final entry in withDocs) {
      final date = '${entry.date.day.toString().padLeft(2, '0')}.${entry.date.month.toString().padLeft(2, '0')}.${entry.date.year}';
      final title = entry.type == EntryType.service
          ? 'Service'
          : entry.type == EntryType.fuel
              ? 'Tanken'
              : entry.description;

      for (var i = 0; i < entry.documentUrls.length; i++) {
        try {
          final response = await http.get(Uri.parse(entry.documentUrls[i]));
          if (response.statusCode != 200) continue;

          final image = pw.MemoryImage(response.bodyBytes);
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(24),
              build: (context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '$date - $title (Dokument ${i + 1})',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Expanded(
                    child: pw.Center(
                      child: pw.Image(image, fit: pw.BoxFit.contain),
                    ),
                  ),
                ],
              ),
            ),
          );
        } catch (_) {
          // Skip documents that can't be downloaded
        }
      }
    }

    return pdf.save();
  }

  pw.Widget _buildPageHeader(Vehicle vehicle, String Function(DateTime) fmtDate) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Fahrzeughistorie',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              '${vehicle.brand} ${vehicle.model}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Divider(thickness: 1.5),
      ],
    );
  }

  pw.Widget _buildPageFooter(pw.Context context) {
    final now = DateTime.now();
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Erstellt am ${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
        pw.Text(
          'Seite ${context.pageNumber} / ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ],
    );
  }

  pw.Widget _buildVehicleInfo(Vehicle vehicle, String distanceUnit, String Function(DateTime) fmtDate) {
    final rows = <List<String>>[
      ['Marke', vehicle.brand],
      ['Modell', vehicle.model],
      ['Baujahr', vehicle.year.toString()],
      ['Leistung', '${vehicle.horsepower} PS'],
      ['Getriebe', vehicle.transmission],
      ['Kraftstoff', vehicle.fuelType],
      ['Kennzeichen', vehicle.licensePlate],
      ['Kilometerstand', '${vehicle.mileage} $distanceUnit'],
    ];
    if (vehicle.nextTuev != null) {
      rows.add(['Nächster TÜV/HU', fmtDate(vehicle.nextTuev!)]);
    }
    if (vehicle.nextInspection != null) {
      rows.add(['Nächste Inspektion', fmtDate(vehicle.nextInspection!)]);
    }

    return pw.TableHelper.fromTextArray(
      headerCount: 0,
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      columnWidths: {
        0: const pw.FixedColumnWidth(120),
        1: const pw.FlexColumnWidth(),
      },
      data: rows.map((r) => [
        pw.Text(r[0], style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        r[1],
      ]).toList(),
    );
  }

}
