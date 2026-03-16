import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../theme.dart';

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
        color: context.subtleBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Vehicle>(
          value: selectedVehicle,
          isExpanded: true,
          dropdownColor: context.cardColor,
          icon: Icon(Icons.keyboard_arrow_down, color: context.brand),
          items: vehicles.map((vehicle) {
            return DropdownMenuItem(
              value: vehicle,
              child: Row(
                children: [
                  Icon(Icons.directions_car,
                      size: 20, color: context.brand),
                  const SizedBox(width: 12),
                  Text(
                    vehicle.displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: context.textPrimary,
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
