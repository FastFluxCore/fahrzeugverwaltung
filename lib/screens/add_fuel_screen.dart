import 'package:flutter/material.dart';
import '../models/entry.dart';
import '../services/entry_service.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../services/vehicle_service.dart';
import '../theme.dart';
import '../services/storage_service.dart';
import '../services/vehicle_service.dart';
import '../widgets/document_picker.dart';

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
  bool _fullTank = true;
  bool _isLoading = false;

  // Tracks which field the user last edited manually
  // so we know which field to auto-calculate.
  String? _lastEditedField;
  bool _isCalculating = false;

  bool get _isEditing => widget.entry != null;

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
        text: e?.mileage?.toString());
    _stationController = TextEditingController(text: e?.station);
    _selectedDate = e?.date ?? DateTime.now();
    _fullTank = e?.fullTank ?? true;

    _litersController.addListener(() => _onFieldChanged('liters'));
    _pricePerLiterController.addListener(() => _onFieldChanged('price'));
    _totalCostController.addListener(() => _onFieldChanged('total'));
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
              final nav = Navigator.of(context);
              nav.pop();
              await _entryService.deleteFuelLog(
                  widget.vehicleId, widget.entry!.id);
              if (mounted) nav.pop();
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
      final mileageText = _mileageController.text.trim();
      final mileage = mileageText.isEmpty ? null : int.parse(mileageText);

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
        fullTank: _fullTank,
        documentUrls: docUrls,
      );

      if (_isEditing) {
        await _entryService.updateFuelLog(widget.vehicleId, entry);
      } else {
        await _entryService.addFuelLog(widget.vehicleId, entry);
      }

      if (mileage != null && mileage > widget.currentMileage) {
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
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Tankvorgang bearbeiten' : 'Tanken',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: context.bgColor,
        backgroundColor: const Color(0xFFF8F9FB),
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
              // Date picker
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: _inputDecoration(context, 'Datum'),
                  decoration: _inputDecoration('Datum'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Icon(Icons.calendar_today,
                          size: 20, color: context.textSecondary),
                      const Icon(Icons.calendar_today,
                          size: 20, color: Color(0xFF8E8E93)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildField(context,
                  _totalCostController, 'Gesamtkosten (${_settings.currency})', 'z.B. 75,40',
              _buildField(
                  _totalCostController, 'Gesamtkosten (€)', 'z.B. 75,40',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildField(context,
                        _litersController, '${_settings.volumeUnit} (optional)', 'z.B. 45,5',
                    child: _buildField(
                        _litersController, 'Liter (optional)', 'z.B. 45,5',
                        keyboardType: TextInputType.number, required: false),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(context,
                        _pricePerLiterController, '${_settings.currency}/${_settings.volumeUnit} (optional)', 'z.B. 1,659',
                    child: _buildField(
                        _pricePerLiterController, '€/Liter (optional)', 'z.B. 1,659',
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
              _buildField(context,
                  _mileageController, '${_settings.distanceUnit == "km" ? "Kilometerstand" : "Meilenstand"} (optional)', 'z.B. 12500',
                  keyboardType: TextInputType.number, required: false),
              const SizedBox(height: 12),
              _buildField(context, _stationController, 'Tankstelle (optional)',
              _buildField(
                  _mileageController, 'Kilometerstand (optional)', 'z.B. 12500',
                  keyboardType: TextInputType.number, required: false),
              const SizedBox(height: 12),
              _buildField(_stationController, 'Tankstelle (optional)',
                  'z.B. Aral, Shell',
                  required: false),
              const SizedBox(height: 12),
              DocumentPicker(
                key: _docPickerKey,
                existingUrls: widget.entry?.documentUrls ?? [],
                onChanged: (_) {},
              ),
              const SizedBox(height: 12),
              // Full tank toggle
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor),
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8ECF0)),
                ),
                child: SwitchListTile(
                  title: const Text('Vollgetankt',
                      style: TextStyle(fontSize: 15)),
                  value: _fullTank,
                  onChanged: (v) => setState(() => _fullTank = v),
                  activeTrackColor: const Color(0xFF1A5276),
                  contentPadding: EdgeInsets.zero,
                ),
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
      decoration: _inputDecoration(label, hint: hint),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
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
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE8ECF0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE8ECF0)),
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
