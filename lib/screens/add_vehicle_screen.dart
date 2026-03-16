import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/vehicle_service.dart';
import '../theme.dart';

class AddVehicleScreen extends StatefulWidget {
  final Vehicle? vehicle; // null = add, non-null = edit

  const AddVehicleScreen({super.key, this.vehicle});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleService = VehicleService();

  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _horsepowerController;
  late final TextEditingController _licensePlateController;
  late final TextEditingController _mileageController;

  String _transmission = 'Automatik';
  String _fuelType = 'Benzin';
  bool _isLoading = false;

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

    if (_isEditing) {
      _transmission = widget.vehicle!.transmission;
      _fuelType = widget.vehicle!.fuelType;
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
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
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
      );

      if (_isEditing) {
        await _vehicleService.updateVehicle(vehicle);
      } else {
        await _vehicleService.addVehicle(vehicle);
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
          _isEditing ? 'Fahrzeug bearbeiten' : 'Fahrzeug hinzufügen',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: context.bgColor,
        backgroundColor: const Color(0xFFF8F9FB),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(_brandController, 'Marke', 'z.B. Audi'),
              const SizedBox(height: 12),
              _buildTextField(_modelController, 'Modell', 'z.B. A4'),
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
              _buildDropdown(
                label: 'Getriebe',
                value: _transmission,
                items: ['Automatik', 'Manuell'],
                onChanged: (v) => setState(() => _transmission = v!),
              ),
              const SizedBox(height: 12),
              _buildDropdown(
                label: 'Kraftstoff',
                value: _fuelType,
                items: ['Benzin', 'Diesel', 'Elektro', 'Hybrid', 'Gas'],
                onChanged: (v) => setState(() => _fuelType = v!),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                  _licensePlateController, 'Kennzeichen', 'z.B. B-AU 2026'),
              const SizedBox(height: 12),
              _buildTextField(_mileageController, 'Kilometerstand', 'z.B. 12450',
                  keyboardType: TextInputType.number),
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Pflichtfeld' : null,
      decoration: _inputDecoration(context, label, hint: hint),
      decoration: InputDecoration(
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
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      decoration: _inputDecoration(context, label),
      decoration: InputDecoration(
        labelText: label,
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
      ),
    );
  }
}
