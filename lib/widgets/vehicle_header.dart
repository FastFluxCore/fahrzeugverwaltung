import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/settings_service.dart';
import '../theme.dart';

class VehicleHeader extends StatelessWidget {
  final Vehicle selectedVehicle;
  final List<Vehicle> vehicles;
  final ValueChanged<Vehicle?> onVehicleChanged;

  const VehicleHeader({
    super.key,
    required this.selectedVehicle,
    required this.vehicles,
    required this.onVehicleChanged,
  });

  void _showVehicleSheet(BuildContext context) {
    final settings = SettingsService();
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
                    itemCount: vehicles.length,
                    itemBuilder: (_, index) {
                      final vehicle = vehicles[index];
                      final selected = vehicle.id == selectedVehicle.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            onVehicleChanged(vehicle);
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
                                _buildVehicleThumbnail(context, vehicle, selected, size: 40),
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
                                        '${vehicle.licensePlate} • ${vehicle.year} • ${vehicle.mileage} ${settings.distanceUnit}',
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

  static Widget _buildVehicleThumbnail(
    BuildContext context,
    Vehicle vehicle,
    bool selected, {
    double size = 40,
  }) {
    if (vehicle.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.25),
        child: Image.network(
          vehicle.imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackIcon(context, selected, size),
        ),
      );
    }
    return _buildFallbackIcon(context, selected, size);
  }

  static Widget _buildFallbackIcon(BuildContext context, bool selected, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected
            ? context.brand.withValues(alpha: 0.15)
            : context.subtleBg,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Icon(Icons.directions_car,
          color: selected ? context.brand : context.textSecondary,
          size: size * 0.55),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService();
    final hasImage = selectedVehicle.imageUrl != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: vehicles.length > 1 ? () => _showVehicleSheet(context) : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Vehicle image or placeholder
              SizedBox(
                width: double.infinity,
                height: 140,
                child: hasImage
                    ? Image.network(
                        selectedVehicle.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildHeroPlaceholder(context),
                      )
                    : _buildHeroPlaceholder(context),
              ),
              // Vehicle info bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${selectedVehicle.brand} ${selectedVehicle.model}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${selectedVehicle.licensePlate} • ${selectedVehicle.year} • ${selectedVehicle.horsepower} PS • ${settings.formatDistance(selectedVehicle.mileage)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (vehicles.length > 1)
                      Icon(Icons.expand_more, size: 22, color: context.textSecondary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroPlaceholder(BuildContext context) {
    return Container(
      color: context.brand.withValues(alpha: 0.06),
      child: Center(
        child: Icon(
          Icons.directions_car_outlined,
          size: 48,
          color: context.brand.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
