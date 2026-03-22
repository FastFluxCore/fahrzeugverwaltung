import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../data/vehicle_data.dart';
import '../models/vehicle.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../services/vehicle_service.dart';
import '../theme.dart';
import '../widgets/sheet_picker.dart';

class AddVehicleScreen extends StatefulWidget {
  final Vehicle? vehicle; // null = add, non-null = edit

  const AddVehicleScreen({super.key, this.vehicle});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleService = VehicleService();
  final _storageService = StorageService();

  Uint8List? _imageBytes;
  String? _imageFileName;
  String? _existingImageUrl;

  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _horsepowerController;
  late final TextEditingController _licensePlateController;
  late final TextEditingController _mileageController;
  late final TextEditingController _oilChangeIntervalController;
  late final TextEditingController _lastOilChangeMileageController;

  String _transmission = 'Automatik';
  String _fuelType = 'Benzin';
  bool _isLoading = false;
  DateTime? _nextTuev;
  DateTime? _nextInspection;
  DateTime? _registrationDate;

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    _brandController = TextEditingController(text: widget.vehicle?.brand);
    _modelController = TextEditingController(text: widget.vehicle?.model);
    _yearController = TextEditingController(
        text: widget.vehicle?.year.toString());
    _horsepowerController = TextEditingController(
        text: widget.vehicle?.horsepower.toString());
    _licensePlateController =
        TextEditingController(text: widget.vehicle?.licensePlate);
    _mileageController = TextEditingController(
        text: widget.vehicle?.mileage.toString());
    _oilChangeIntervalController = TextEditingController(
        text: widget.vehicle?.oilChangeInterval?.toString());
    _lastOilChangeMileageController = TextEditingController(
        text: widget.vehicle?.lastOilChangeMileage?.toString());

    if (_isEditing) {
      _transmission = widget.vehicle!.transmission;
      _fuelType = widget.vehicle!.fuelType;
      _nextTuev = widget.vehicle!.nextTuev;
      _nextInspection = widget.vehicle!.nextInspection;
      _registrationDate = widget.vehicle!.registrationDate;
      _existingImageUrl = widget.vehicle!.imageUrl;
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _horsepowerController.dispose();
    _licensePlateController.dispose();
    _mileageController.dispose();
    _oilChangeIntervalController.dispose();
    _lastOilChangeMileageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _imageBytes = result.files.single.bytes;
        _imageFileName = result.files.single.name;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _imageBytes = null;
      _imageFileName = null;
      _existingImageUrl = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final oilInterval = _oilChangeIntervalController.text.trim();
      final lastOilMileage = _lastOilChangeMileageController.text.trim();

      // Upload image if new one was picked
      String? imageUrl = _existingImageUrl;
      if (_imageBytes != null && _imageFileName != null) {
        final vehicleId = widget.vehicle?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
        imageUrl = await _storageService.uploadDocument(
          vehicleId: vehicleId,
          entryType: 'profile',
          fileName: _imageFileName!,
          bytes: _imageBytes!,
        );
        // Delete old image if replacing
        if (_existingImageUrl != null) {
          await _storageService.deleteDocument(_existingImageUrl!);
        }
      } else if (_existingImageUrl == null && widget.vehicle?.imageUrl != null) {
        // User removed the image
        await _storageService.deleteDocument(widget.vehicle!.imageUrl!);
      }

      final vehicle = Vehicle(
        id: widget.vehicle?.id ?? '',
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text.trim()),
        horsepower: int.parse(_horsepowerController.text.trim()),
        transmission: _transmission,
        fuelType: _fuelType,
        licensePlate: _licensePlateController.text.trim(),
        mileage: int.parse(_mileageController.text.trim()),
        registrationDate: _registrationDate!,
        imageUrl: imageUrl,
        nextTuev: _nextTuev,
        nextInspection: _nextInspection,
        oilChangeInterval: oilInterval.isEmpty ? null : int.parse(oilInterval),
        lastOilChangeMileage: lastOilMileage.isEmpty ? null : int.parse(lastOilMileage),
        originalNextTuev: _nextTuev,
        originalNextInspection: _nextInspection,
        originalLastOilChangeMileage: lastOilMileage.isEmpty ? null : int.parse(lastOilMileage),
      );

      if (_isEditing) {
        await _vehicleService.updateVehicle(vehicle);
      } else {
        final created = await _vehicleService.addVehicle(vehicle);
        // Re-upload with correct vehicle ID if we used a temp one
        if (_imageBytes != null && _imageFileName != null) {
          final correctUrl = await _storageService.uploadDocument(
            vehicleId: created.id,
            entryType: 'profile',
            fileName: _imageFileName!,
            bytes: _imageBytes!,
          );
          await _vehicleService.updateVehicle(Vehicle(
            id: created.id,
            brand: vehicle.brand,
            model: vehicle.model,
            year: vehicle.year,
            horsepower: vehicle.horsepower,
            transmission: vehicle.transmission,
            fuelType: vehicle.fuelType,
            licensePlate: vehicle.licensePlate,
            mileage: vehicle.mileage,
            registrationDate: vehicle.registrationDate,
            imageUrl: correctUrl,
            nextTuev: vehicle.nextTuev,
            nextInspection: vehicle.nextInspection,
            oilChangeInterval: vehicle.oilChangeInterval,
            lastOilChangeMileage: vehicle.lastOilChangeMileage,
            originalNextTuev: vehicle.originalNextTuev,
            originalNextInspection: vehicle.originalNextInspection,
            originalLastOilChangeMileage: vehicle.originalLastOilChangeMileage,
          ));
          // Clean up temp upload
          if (imageUrl != null) await _storageService.deleteDocument(imageUrl);
        }
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
          _isEditing ? 'Fahrzeug bearbeiten' : 'Fahrzeug hinzufügen',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: context.bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildImagePicker(context),
              const SizedBox(height: 16),
              _buildSearchablePicker(
                label: 'Marke',
                value: _brandController.text,
                items: [...vehicleBrands, 'Sonstige'],
                onChanged: (v) {
                  setState(() {
                    final changed = v != _brandController.text;
                    _brandController.text = v;
                    if (changed) _modelController.text = '';
                  });
                },
                allowCustom: true,
              ),
              const SizedBox(height: 12),
              _buildSearchablePicker(
                label: 'Modell',
                value: _modelController.text,
                items: [
                  ...?vehicleModels[_brandController.text],
                  'Sonstiges',
                ],
                onChanged: (v) => setState(() => _modelController.text = v),
                allowCustom: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                        _yearController, 'Baujahr', 'z.B. 2026',
                        keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                        _horsepowerController, 'PS', 'z.B. 150',
                        keyboardType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SheetPicker(
                label: 'Getriebe',
                value: _transmission,
                items: const ['Automatik', 'Manuell'],
                onChanged: (v) => setState(() => _transmission = v),
              ),
              const SizedBox(height: 12),
              SheetPicker(
                label: 'Kraftstoff',
                value: _fuelType,
                items: const ['Benzin', 'Diesel', 'Elektro', 'Hybrid', 'Gas'],
                onChanged: (v) => setState(() => _fuelType = v),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                  _licensePlateController, 'Kennzeichen', 'z.B. B-AU 2026'),
              const SizedBox(height: 12),
              _buildTextField(_mileageController, 'Kilometerstand', 'z.B. 12450',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _buildRequiredDateField(
                label: 'Zugelassen seit',
                value: _registrationDate,
                onPicked: (d) => setState(() => _registrationDate = d),
                allowPast: true,
              ),
              const SizedBox(height: 28),
              // Section: Termine & Intervalle
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'TERMINE & INTERVALLE',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.sectionHeader,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildDateField(
                label: 'Nächster TÜV/HU',
                value: _nextTuev,
                onPicked: (d) => setState(() => _nextTuev = d),
              ),
              const SizedBox(height: 12),
              _buildDateField(
                label: 'Nächste Inspektion',
                value: _nextInspection,
                onPicked: (d) => setState(() => _nextInspection = d),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _oilChangeIntervalController,
                'Ölwechsel-Intervall (${SettingsService().distanceUnit})',
                'z.B. 15000',
                keyboardType: TextInputType.number,
                required: false,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _lastOilChangeMileageController,
                'Letzter Ölwechsel (${SettingsService().distanceUnit}-Stand)',
                'z.B. 230000',
                keyboardType: TextInputType.number,
                required: false,
              ),
              const SizedBox(height: 24),
              SizedBox(
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
                          _isEditing ? 'Speichern' : 'Fahrzeug hinzufügen',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(BuildContext context) {
    final hasImage = _imageBytes != null || _existingImageUrl != null;
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  if (_imageBytes != null)
                    Image.memory(_imageBytes!, fit: BoxFit.cover)
                  else
                    Image.network(
                      _existingImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildImagePlaceholder(context),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildImageAction(Icons.edit, context.brand, _pickImage),
                        const SizedBox(width: 6),
                        _buildImageAction(Icons.close, const Color(0xFFC62828), _removeImage),
                      ],
                    ),
                  ),
                ],
              )
            : _buildImagePlaceholder(context),
      ),
    );
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined, size: 36, color: context.textSecondary),
        const SizedBox(height: 8),
        Text(
          'Fahrzeugbild hinzufügen',
          style: TextStyle(fontSize: 14, color: context.textSecondary),
        ),
        Text(
          'JPG, PNG, WebP',
          style: TextStyle(fontSize: 12, color: context.textSecondary.withValues(alpha: 0.6)),
        ),
      ],
    );
  }

  Widget _buildImageAction(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
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

  Widget _buildTextField(
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

  Widget _buildSearchablePicker({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
    bool allowCustom = false,
  }) {
    return FormField<String>(
      validator: (_) => value.isEmpty ? 'Pflichtfeld' : null,
      builder: (state) => InkWell(
        onTap: () => _showSearchSheet(label, items, onChanged, state, allowCustom),
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: _inputDecoration(context, label).copyWith(
            errorText: state.errorText,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value.isNotEmpty ? value : 'Auswählen',
                  style: TextStyle(
                    fontSize: 16,
                    color: value.isNotEmpty ? context.textPrimary : context.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.arrow_drop_down, color: context.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchSheet(
    String label,
    List<String> items,
    ValueChanged<String> onChanged,
    FormFieldState<String> fieldState,
    bool allowCustom,
  ) {
    final searchController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final query = searchController.text.toLowerCase();
            final filtered = items
                .where((item) => item.toLowerCase().contains(query))
                .toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              minChildSize: 0.3,
              expand: false,
              builder: (ctx, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Suchen...',
                          prefixIcon: const Icon(Icons.search),
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
                        onChanged: (_) => setSheetState(() {}),
                      ),
                      const SizedBox(height: 12),
                      if (allowCustom && query.isNotEmpty && !filtered.any((f) => f.toLowerCase() == query))
                        ListTile(
                          leading: const Icon(Icons.add, color: Color(0xFF1A5276)),
                          title: Text('"${searchController.text}" verwenden'),
                          onTap: () {
                            onChanged(searchController.text);
                            fieldState.didChange(searchController.text);
                            Navigator.pop(ctx);
                          },
                        ),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: filtered.length,
                          itemBuilder: (ctx, index) {
                            final item = filtered[index];
                            return ListTile(
                              title: Text(item),
                              onTap: () {
                                if (item == 'Sonstige' || item == 'Sonstiges') {
                                  // Clear so user types manually
                                  searchController.clear();
                                  setSheetState(() {});
                                } else {
                                  onChanged(item);
                                  fieldState.didChange(item);
                                  Navigator.pop(ctx);
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRequiredDateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onPicked,
    bool allowPast = false,
  }) {
    return FormField<DateTime>(
      validator: (_) => value == null ? 'Pflichtfeld' : null,
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime.now(),
                firstDate: allowPast ? DateTime(1970) : DateTime.now(),
                lastDate: allowPast ? DateTime.now() : DateTime.now().add(const Duration(days: 365 * 5)),
              );
              if (picked != null) {
                onPicked(picked);
                state.didChange(picked);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: _inputDecoration(context, label).copyWith(
                errorText: state.errorText,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value != null
                        ? '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}'
                        : 'Nicht gesetzt',
                    style: TextStyle(
                      fontSize: 16,
                      color: value != null ? context.textPrimary : context.textSecondary,
                    ),
                  ),
                  Icon(Icons.calendar_today, size: 20, color: context.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onPicked,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now().add(const Duration(days: 365)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        );
        if (picked != null) onPicked(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _inputDecoration(context, label),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value != null
                  ? '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}'
                  : 'Nicht gesetzt',
              style: TextStyle(
                fontSize: 16,
                color: value != null ? context.textPrimary : context.textSecondary,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (value != null)
                  GestureDetector(
                    onTap: () => onPicked(null),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(Icons.close, size: 18, color: context.textSecondary),
                    ),
                  ),
                Icon(Icons.calendar_today, size: 20, color: context.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
