import 'package:flutter/material.dart';
import '../models/vehicle.dart';

class VehicleSelector extends StatelessWidget {
  final Vehicle? selectedVehicle;
  final List<Vehicle> vehicles;
  final ValueChanged<Vehicle?> onChanged;

  const VehicleSelector({
    super.key,
    required this.selectedVehicle,
    required this.vehicles,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Vehicle>(
          value: selectedVehicle,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF1A5276)),
          items: vehicles.map((vehicle) {
            return DropdownMenuItem(
              value: vehicle,
              child: Row(
                children: [
                  const Icon(Icons.directions_car,
                      size: 20, color: Color(0xFF1A5276)),
                  const SizedBox(width: 12),
                  Text(
                    vehicle.displayName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
