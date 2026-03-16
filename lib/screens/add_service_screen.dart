import 'package:flutter/material.dart';
import '../models/entry.dart';
import '../services/entry_service.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../services/vehicle_service.dart';
import '../theme.dart';
import '../widgets/document_picker.dart';

class AddServiceScreen extends StatefulWidget {
  final String vehicleId;
  final int currentMileage;
  final Entry? entry;

  const AddServiceScreen({
    super.key,
    required this.vehicleId,
    required this.currentMileage,
    this.entry,
  });

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _entryService = EntryService();
  final _vehicleService = VehicleService();
  final _storageService = StorageService();
  final _settings = SettingsService();
  final _docPickerKey = GlobalKey<DocumentPickerState>();

  late final TextEditingController _costController;
  late final TextEditingController _mileageController;
  late final TextEditingController _workshopController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;
  String _serviceType = 'Ölwechsel';
  bool _isLoading = false;

  bool get _isEditing => widget.entry != null;

  static const _serviceTypes = [
    'Ölwechsel',
    'Inspektion',
    'Bremsen',
    'Reifen',
    'TÜV/HU',
    'Zahnriemen',
    'Batterie',
    'Klimaanlage',
    'Auspuff',
    'Sonstiges',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _costController = TextEditingController(text: e?.cost.toStringAsFixed(2));
    _mileageController = TextEditingController(
        text: e?.mileage?.toString() ?? widget.currentMileage.toString());
    _workshopController = TextEditingController(text: e?.workshop);
    _notesController = TextEditingController(text: e?.notes);
    _selectedDate = e?.date ?? DateTime.now();
    if (e?.serviceType != null && _serviceTypes.contains(e!.serviceType)) {
      _serviceType = e.serviceType!;
    }
  }

  @override
  void dispose() {
    _costController.dispose();
    _mileageController.dispose();
    _workshopController.dispose();
    _notesController.dispose();
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
        content: const Text('Diesen Service-Eintrag wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              final outerNav = Navigator.of(this.context);
              final serviceType = widget.entry!.serviceType;
              Navigator.pop(context); // close dialog
              await _entryService.deleteService(
                  widget.vehicleId, widget.entry!.id);
              if (serviceType != null) {
                await _vehicleService.recalculateReminders(
                  vehicleId: widget.vehicleId,
                  deletedServiceType: serviceType,
                );
              }
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
      final cost = double.parse(_costController.text.replaceAll(',', '.'));
      final mileage = int.parse(_mileageController.text.trim());

      final docUrls = await _docPickerKey.currentState!.uploadAll(
        vehicleId: widget.vehicleId,
        entryType: 'services',
        storageService: _storageService,
      );

      final entry = Entry(
        id: widget.entry?.id ?? '',
        type: EntryType.service,
        date: _selectedDate,
        cost: cost,
        mileage: mileage,
        description: _serviceType,
        serviceType: _serviceType,
        workshop: _workshopController.text.trim().isEmpty
            ? null
            : _workshopController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        documentUrls: docUrls,
      );

      if (_isEditing) {
        await _entryService.updateService(widget.vehicleId, entry);
      } else {
        await _entryService.addService(widget.vehicleId, entry);
      }

      if (mileage > widget.currentMileage) {
        await _vehicleService.updateMileage(widget.vehicleId, mileage);
      }

      // Auto-update reminders based on service type
      await _vehicleService.updateRemindersAfterService(
        vehicleId: widget.vehicleId,
        serviceType: _serviceType,
        serviceDate: _selectedDate,
        mileage: mileage,
      );

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
          _isEditing ? 'Service bearbeiten' : 'Service',
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
              DropdownButtonFormField<String>(
                initialValue: _serviceType,
                items: _serviceTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _serviceType = v!),
                decoration: _inputDecoration(context, 'Art des Service'),
              ),
              const SizedBox(height: 12),
              _buildField(context, _costController, 'Kosten (${_settings.currency})', 'z.B. 250.00',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _buildField(context, _mileageController, _settings.isKm ? 'Kilometerstand' : 'Meilenstand', 'z.B. 12500',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _buildField(context,
                  _workshopController, 'Werkstatt (optional)', 'z.B. ATU',
                  required: false),
              const SizedBox(height: 12),
              _buildField(context,
                  _notesController, 'Notizen (optional)', 'Weitere Details...',
                  required: false, maxLines: 3),
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
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
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
          backgroundColor: const Color(0xFF2E7D32),
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
                _isEditing ? 'Speichern' : 'Service hinzufügen',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
