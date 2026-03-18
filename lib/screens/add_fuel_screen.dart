import 'package:flutter/material.dart';
import '../models/entry.dart';
import '../services/entry_service.dart';
import '../services/receipt_scanner_service.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../services/vehicle_service.dart';
import '../theme.dart';
import '../widgets/document_picker.dart';
import '../widgets/receipt_scan_button.dart';

class AddFuelScreen extends StatefulWidget {
  final String vehicleId;
  final int currentMileage;
  final Entry? entry;

  const AddFuelScreen({
    super.key,
    required this.vehicleId,
    required this.currentMileage,
    this.entry,
  });

  @override
  State<AddFuelScreen> createState() => _AddFuelScreenState();
}

class _AddFuelScreenState extends State<AddFuelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _entryService = EntryService();
  final _settings = SettingsService();
  final _vehicleService = VehicleService();
  final _storageService = StorageService();
  final _docPickerKey = GlobalKey<DocumentPickerState>();

  late final TextEditingController _litersController;
  late final TextEditingController _pricePerLiterController;
  late final TextEditingController _totalCostController;
  late final TextEditingController _mileageController;
  late final TextEditingController _stationController;
  late DateTime _selectedDate;
  bool _isLoading = false;

  // Tracks which field the user last edited manually
  // so we know which field to auto-calculate.
  String? _lastEditedField;
  bool _isCalculating = false;

  static const _geminiKey = String.fromEnvironment('GEMINI_API_KEY');

  bool get _isEditing => widget.entry != null;

  void _applyScanResult(ScanResult result) {
    _isCalculating = true;
    if (result.date != null) setState(() => _selectedDate = result.date!);
    if (result.totalCost != null) {
      _totalCostController.text = result.totalCost!.toStringAsFixed(2);
    }
    if (result.liters != null) {
      _litersController.text = result.liters!.toStringAsFixed(2);
    }
    if (result.pricePerLiter != null) {
      _pricePerLiterController.text = result.pricePerLiter!.toStringAsFixed(3);
    }
    if (result.mileage != null) {
      _mileageController.text = result.mileage.toString();
    }
    if (result.station != null && result.station!.isNotEmpty) {
      _stationController.text = result.station!;
    }
    _isCalculating = false;
    _validateConsistency();
  }

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _litersController =
        TextEditingController(text: e?.liters?.toStringAsFixed(2));
    _pricePerLiterController =
        TextEditingController(text: e?.pricePerLiter?.toStringAsFixed(3));
    _totalCostController =
        TextEditingController(text: e?.cost.toStringAsFixed(2));
    _mileageController = TextEditingController(
        text: e?.mileage?.toString() ?? widget.currentMileage.toString());
    _stationController = TextEditingController(text: e?.station);
    _selectedDate = e?.date ?? DateTime.now();

    _litersController.addListener(() => _onFieldChanged('liters'));
    _pricePerLiterController.addListener(() => _onFieldChanged('price'));
    _totalCostController.addListener(() => _onFieldChanged('total'));
    _litersController.addListener(_updateConsumptionPreview);
    _mileageController.addListener(_updateConsumptionPreview);
  }

  double? _parse(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.'));

  void _onFieldChanged(String field) {
    if (_isCalculating) return;
    _lastEditedField = field;
    _autoCalculate();
  }

  void _autoCalculate() {
    final liters = _parse(_litersController);
    final price = _parse(_pricePerLiterController);
    final total = _parse(_totalCostController);

    _isCalculating = true;

    // Gesamtkosten ist Master — nur Liter oder Preis werden berechnet
    if (_lastEditedField == 'liters' && liters != null && liters > 0 && total != null) {
      // Liter geändert + Gesamt vorhanden → Preis berechnen
      _pricePerLiterController.text = (total / liters).toStringAsFixed(3);
    } else if (_lastEditedField == 'price' && price != null && price > 0 && total != null) {
      // Preis geändert + Gesamt vorhanden → Liter berechnen
      _litersController.text = (total / price).toStringAsFixed(2);
    } else if (_lastEditedField == 'total') {
      // Gesamt geändert → abhängigen Wert neu berechnen
      if (liters != null && liters > 0) {
        _pricePerLiterController.text = (total! / liters).toStringAsFixed(3);
      } else if (price != null && price > 0) {
        _litersController.text = (total! / price).toStringAsFixed(2);
      }
    }

    _isCalculating = false;
    _validateConsistency();
  }

  String? _consistencyError;
  String? _consumptionPreview;

  void _updateConsumptionPreview() {
    final liters = _parse(_litersController);
    final mileageText = _mileageController.text.trim();
    final mileage = int.tryParse(mileageText);

    String? preview;
    if (liters != null && liters > 0 && mileage != null && mileage > widget.currentMileage) {
      final dist = mileage - widget.currentMileage;
      if (dist > 0) {
        final consumption = liters / dist * 100;
        preview = '${consumption.toStringAsFixed(1).replaceAll('.', ',')} ${_settings.consumptionUnit}';
      }
    }

    if (preview != _consumptionPreview) {
      setState(() => _consumptionPreview = preview);
    }
  }

  void _validateConsistency() {
    final liters = _parse(_litersController);
    final price = _parse(_pricePerLiterController);
    final total = _parse(_totalCostController);

    String? error;
    if (liters != null && price != null && total != null) {
      final expected = liters * price;
      if ((expected - total).abs() > 0.02) {
        error =
            'Rechnung geht nicht auf: ${liters.toStringAsFixed(2)} L × ${price.toStringAsFixed(3)} €/L = ${expected.toStringAsFixed(2)} €';
      }
    }

    if (error != _consistencyError) {
      setState(() => _consistencyError = error);
    }
  }

  @override
  void dispose() {
    _litersController.dispose();
    _pricePerLiterController.dispose();
    _totalCostController.dispose();
    _mileageController.dispose();
    _stationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eintrag löschen'),
        content: const Text('Diesen Tankvorgang wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              final outerNav = Navigator.of(this.context);
              Navigator.pop(context); // close dialog
              await _entryService.deleteFuelLog(
                  widget.vehicleId, widget.entry!.id);
              if (mounted) outerNav.pop(); // close form screen
            },
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFC62828)),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final totalCost =
          double.parse(_totalCostController.text.replaceAll(',', '.'));
      final liters = _parse(_litersController);
      final pricePerLiter = _parse(_pricePerLiterController);
      final mileage = int.parse(_mileageController.text.trim());

      final docUrls = await _docPickerKey.currentState!.uploadAll(
        vehicleId: widget.vehicleId,
        entryType: 'fuelLogs',
        storageService: _storageService,
      );

      final entry = Entry(
        id: widget.entry?.id ?? '',
        type: EntryType.fuel,
        date: _selectedDate,
        cost: totalCost,
        mileage: mileage,
        description: 'Tanken',
        station: _stationController.text.trim().isEmpty
            ? null
            : _stationController.text.trim(),
        liters: liters,
        pricePerLiter: pricePerLiter,
        fullTank: true,
        documentUrls: docUrls,
      );

      if (_isEditing) {
        await _entryService.updateFuelLog(widget.vehicleId, entry);
      } else {
        await _entryService.addFuelLog(widget.vehicleId, entry);
      }

      if (mileage > widget.currentMileage) {
        await _vehicleService.updateMileage(widget.vehicleId, mileage);
      }

      if (mounted) Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Tankvorgang bearbeiten' : 'Tanken',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: context.bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_outline,
                  color: Color(0xFFC62828)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (!_isEditing && _geminiKey.isNotEmpty) ...[
                ReceiptScanButton(
                  receiptType: ReceiptType.fuel,
                  apiKey: _geminiKey,
                  onScanned: _applyScanResult,
                  onFilePicked: (name, bytes) =>
                      _docPickerKey.currentState?.addFile(name, bytes),
                ),
                const SizedBox(height: 16),
              ],
              // Date picker
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: _inputDecoration(context, 'Datum'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Icon(Icons.calendar_today,
                          size: 20, color: context.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildField(context,
                  _totalCostController, 'Gesamtkosten (${_settings.currency})', 'z.B. 75,40',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildField(context,
                        _litersController, _settings.volumeUnit, 'z.B. 45,5',
                        keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(context,
                        _pricePerLiterController, '${_settings.currency}/${_settings.volumeUnit} (optional)', 'z.B. 1,659',
                        keyboardType: TextInputType.number, required: false),
                  ),
                ],
              ),
              // Consistency warning
              if (_consistencyError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFE67E22), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _consistencyError!,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFFE67E22)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mileageController,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Pflichtfeld';
                  final val = int.tryParse(v.trim());
                  if (val == null) return 'Ungültige Zahl';
                  if (!_isEditing && val < widget.currentMileage) {
                    return 'Muss mindestens ${widget.currentMileage} ${_settings.distanceUnit} sein';
                  }
                  return null;
                },
                decoration: _inputDecoration(context,
                    _settings.distanceUnit == 'km' ? 'Kilometerstand' : 'Meilenstand',
                    hint: 'z.B. ${widget.currentMileage + 350}'),
              ),
              // Consumption preview
              if (_consumptionPreview != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A5276).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_gas_station,
                            color: Color(0xFF1A5276), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Verbrauch: $_consumptionPreview',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A5276),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              _buildField(context, _stationController, 'Tankstelle (optional)',
                  'z.B. Aral, Shell',
                  required: false),
              const SizedBox(height: 12),
              DocumentPicker(
                key: _docPickerKey,
                existingUrls: widget.entry?.documentUrls ?? [],
                onChanged: (_) {},
              ),
              const SizedBox(height: 24),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    BuildContext context,
    TextEditingController controller,
    String label,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Pflichtfeld' : null
          : null,
      decoration: _inputDecoration(context, label, hint: hint),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
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
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A5276),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(
                _isEditing ? 'Speichern' : 'Tankvorgang hinzufügen',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
