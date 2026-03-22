import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/vehicle.dart';
import '../services/export_service.dart';
import '../services/settings_service.dart';
import '../theme.dart';

class ExportScreen extends StatefulWidget {
  final List<Vehicle> vehicles;
  final Vehicle initialVehicle;

  const ExportScreen({
    super.key,
    required this.vehicles,
    required this.initialVehicle,
  });

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _exportService = ExportService();
  final _settings = SettingsService();
  bool _isLoading = false;

  late Vehicle _selectedVehicle;

  // Filter toggles
  bool _includeServices = true;
  bool _includeFuel = true;
  bool _includeOtherCosts = true;

  @override
  void initState() {
    super.initState();
    _selectedVehicle = widget.initialVehicle;
  }

  Future<Uint8List> _generatePdf() {
    return _exportService.generatePdf(
      vehicle: _selectedVehicle,
      currency: 'EUR',
      distanceUnit: _settings.distanceUnit,
      volumeUnit: _settings.volumeUnit,
      includeServices: _includeServices,
      includeFuel: _includeFuel,
      includeOtherCosts: _includeOtherCosts,
    );
  }

  Future<void> _export() async {
    setState(() => _isLoading = true);
    try {
      final name = '${_selectedVehicle.brand}_${_selectedVehicle.model}';
      final results = await Future.wait([
        _generatePdf(),
        _exportService.generateDocumentsPdf(vehicle: _selectedVehicle),
      ]);
      final pdfBytes = results[0]!;
      final docsPdfBytes = results[1];

      if (!mounted) return;

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Fahrzeughistorie_$name.pdf',
      );

      if (docsPdfBytes != null && mounted) {
        await Printing.sharePdf(
          bytes: docsPdfBytes,
          filename: 'Dokumente_$name.pdf',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _preview() async {
    setState(() => _isLoading = true);
    try {
      final pdfBytes = await _generatePdf();

      if (!mounted) return;
      setState(() => _isLoading = false);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _PdfPreviewScreen(
            pdfBytes: pdfBytes,
            vehicle: _selectedVehicle,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text(
          'Fahrzeughistorie',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: context.bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle selector
            _buildVehiclePicker(context),
            const SizedBox(height: 24),

            // Filter toggles
            Text(
              'INHALT AUSWÄHLEN',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.sectionHeader,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                children: [
                  _buildToggle(
                    icon: Icons.directions_car,
                    title: 'Fahrzeugdaten',
                    subtitle: 'Marke, Modell, Baujahr, PS, Kennzeichen',
                    value: true,
                    locked: true,
                  ),
                  Divider(height: 1, indent: 56, color: context.borderColor),
                  _buildToggle(
                    icon: Icons.build,
                    title: 'Service-Historie',
                    subtitle: 'Werkstattbesuche mit Details',
                    value: _includeServices,
                    onChanged: (v) => setState(() => _includeServices = v),
                  ),
                  Divider(height: 1, indent: 56, color: context.borderColor),
                  _buildToggle(
                    icon: Icons.local_gas_station,
                    title: 'Tank-Historie',
                    subtitle: 'Tankvorgänge mit Verbrauch',
                    value: _includeFuel,
                    onChanged: (v) => setState(() => _includeFuel = v),
                  ),
                  Divider(height: 1, indent: 56, color: context.borderColor),
                  _buildToggle(
                    icon: Icons.receipt_long,
                    title: 'Sonstige Kosten',
                    subtitle: 'Versicherung, Steuer, etc.',
                    value: _includeOtherCosts,
                    onChanged: (v) => setState(() => _includeOtherCosts = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Fahrzeugdaten und Kostenübersicht sind immer enthalten.',
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            ),

            const Spacer(),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _preview,
                      icon: const Icon(Icons.visibility, size: 20),
                      label: const Text('Vorschau',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.brand,
                        side: BorderSide(color: context.brand),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _export,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.download, size: 20),
                      label: const Text('Exportieren',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A5276),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildVehiclePicker(BuildContext context) {
    return InkWell(
      onTap: () => _showVehicleSheet(context),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fahrzeug',
          filled: true,
          fillColor: context.inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.borderColor),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.directions_car, size: 20, color: context.brand),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${_selectedVehicle.brand} ${_selectedVehicle.model} — ${_selectedVehicle.licensePlate}',
                style: TextStyle(fontSize: 16, color: context.textPrimary),
              ),
            ),
            Icon(Icons.expand_more, size: 22, color: context.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showVehicleSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final maxHeight = MediaQuery.of(context).size.height * 0.6;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Fahrzeug auswählen',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.vehicles.length,
                    itemBuilder: (_, index) {
                      final vehicle = widget.vehicles[index];
                      final selected = vehicle.id == _selectedVehicle.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            setState(() => _selectedVehicle = vehicle);
                            Navigator.pop(sheetContext);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? context.brand.withValues(alpha: 0.08)
                                  : context.subtleBg,
                              borderRadius: BorderRadius.circular(12),
                              border: selected
                                  ? Border.all(color: context.brand)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? context.brand.withValues(alpha: 0.15)
                                        : context.subtleBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.directions_car,
                                      color: selected ? context.brand : context.textSecondary,
                                      size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${vehicle.brand} ${vehicle.model}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                          color: selected ? context.brand : context.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${vehicle.licensePlate} • ${vehicle.year} • ${vehicle.mileage} ${_settings.distanceUnit}',
                                        style: TextStyle(fontSize: 12, color: context.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selected)
                                  Icon(Icons.check, color: context.brand, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    bool locked = false,
    ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: value ? context.brand : context.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: value ? context.textPrimary : context.textSecondary)),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: context.textSecondary)),
              ],
            ),
          ),
          if (locked)
            Icon(Icons.lock_outline, size: 18, color: context.textSecondary)
          else
            SizedBox(
              height: 24,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: const Color(0xFF1A5276),
              ),
            ),
        ],
      ),
    );
  }
}

class _PdfPreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;
  final Vehicle vehicle;

  const _PdfPreviewScreen({required this.pdfBytes, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text(
          'PDF Vorschau',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: context.bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            onPressed: () => Printing.sharePdf(
              bytes: pdfBytes,
              filename: 'Fahrzeughistorie_${vehicle.brand}_${vehicle.model}.pdf',
            ),
            icon: Icon(Icons.download, color: context.brand),
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) async => pdfBytes,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: 'Fahrzeughistorie_${vehicle.brand}_${vehicle.model}.pdf',
      ),
    );
  }
}
