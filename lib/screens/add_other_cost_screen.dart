import 'package:flutter/material.dart';
import '../models/entry.dart';
import '../services/entry_service.dart';
import '../services/storage_service.dart';
import '../widgets/document_picker.dart';

class AddOtherCostScreen extends StatefulWidget {
  final String vehicleId;
  final Entry? entry;

  const AddOtherCostScreen({
    super.key,
    required this.vehicleId,
    this.entry,
  });

  @override
  State<AddOtherCostScreen> createState() => _AddOtherCostScreenState();
}

class _AddOtherCostScreenState extends State<AddOtherCostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _entryService = EntryService();
  final _storageService = StorageService();
  final _docPickerKey = GlobalKey<DocumentPickerState>();

  late final TextEditingController _descriptionController;
  late final TextEditingController _costController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;
  String _category = 'Versicherung';
  String _interval = 'Einmalig';
  bool _isLoading = false;

  bool get _isEditing => widget.entry != null;

  static const _categories = [
    'Versicherung',
    'Steuer',
    'Parkgebühren',
    'Maut',
    'Waschen',
    'Zubehör',
    'Finanzierung',
    'Sonstiges',
  ];

  static const _intervals = [
    'Einmalig',
    'Monatlich',
    'Vierteljährlich',
    'Halbjährlich',
    'Jährlich',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _descriptionController = TextEditingController(text: e?.description);
    _costController = TextEditingController(text: e?.cost.toStringAsFixed(2));
    _notesController = TextEditingController(text: e?.notes);
    _selectedDate = e?.date ?? DateTime.now();
    if (e?.category != null && _categories.contains(e!.category)) {
      _category = e.category!;
    }
    if (e?.interval != null && _intervals.contains(e!.interval)) {
      _interval = e.interval!;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _costController.dispose();
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
        content: const Text('Diesen Kosteneintrag wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              nav.pop();
              await _entryService.deleteOtherCost(
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
      final cost = double.parse(_costController.text.replaceAll(',', '.'));

      final docUrls = await _docPickerKey.currentState!.uploadAll(
        vehicleId: widget.vehicleId,
        entryType: 'otherCosts',
        storageService: _storageService,
      );

      final entry = Entry(
        id: widget.entry?.id ?? '',
        type: EntryType.otherCost,
        date: _selectedDate,
        cost: cost,
        description: _descriptionController.text.trim(),
        category: _category,
        interval: _interval,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        documentUrls: docUrls,
      );

      if (_isEditing) {
        await _entryService.updateOtherCost(widget.vehicleId, entry);
      } else {
        await _entryService.addOtherCost(widget.vehicleId, entry);
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
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Kosten bearbeiten' : 'Sonstige Kosten',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
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
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: _inputDecoration('Datum'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.calendar_today,
                          size: 20, color: Color(0xFF8E8E93)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
                decoration: _inputDecoration('Kategorie'),
              ),
              const SizedBox(height: 12),
              _buildField(
                  _descriptionController, 'Beschreibung', 'z.B. KFZ-Steuer 2026'),
              const SizedBox(height: 12),
              _buildField(_costController, 'Kosten (€)', 'z.B. 120.00',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _interval,
                items: _intervals
                    .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                    .toList(),
                onChanged: (v) => setState(() => _interval = v!),
                decoration: _inputDecoration('Intervall'),
              ),
              const SizedBox(height: 12),
              _buildField(
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
      decoration: _inputDecoration(label, hint: hint),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
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
          backgroundColor: const Color(0xFFC62828),
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
                _isEditing ? 'Speichern' : 'Kosten hinzufügen',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
