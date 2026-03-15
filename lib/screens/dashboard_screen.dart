import 'package:flutter/material.dart';
import '../models/entry.dart';
import '../models/vehicle.dart';
import '../widgets/entry_card.dart';
import '../widgets/summary_card.dart';
import '../widgets/vehicle_selector.dart';

class DashboardScreen extends StatelessWidget {
  final List<Vehicle> vehicles;
  final Vehicle selectedVehicle;
  final ValueChanged<Vehicle?> onVehicleChanged;

  const DashboardScreen({
    super.key,
    required this.vehicles,
    required this.selectedVehicle,
    required this.onVehicleChanged,
  });

  // TODO: Replace with Firestore data
  List<Entry> get _recentEntries => [
        Entry(
          id: '1',
          type: EntryType.fuel,
          date: DateTime(2023, 10, 13, 18, 45),
          cost: 84.20,
          description: 'Tanken',
          subtitle: 'Gestern, 18:45 Uhr',
          liters: 54.2,
        ),
        Entry(
          id: '2',
          type: EntryType.service,
          date: DateTime(2023, 10, 12),
          cost: 210.00,
          description: 'Service',
          subtitle: '12. Okt 2023',
        ),
        Entry(
          id: '3',
          type: EntryType.otherCost,
          date: DateTime(2023, 10, 8),
          cost: 2.00,
          description: 'Parkgebühren',
          subtitle: '08. Okt 2023',
          category: 'Parkgebühren',
        ),
        Entry(
          id: '4',
          type: EntryType.otherCost,
          date: DateTime(2023, 10, 8),
          cost: 4.50,
          description: 'Parkgebühren',
          subtitle: '08. Okt 2023',
          category: 'Parkgebühren',
        ),
        Entry(
          id: '5',
          type: EntryType.fuel,
          date: DateTime(2023, 10, 1),
          cost: 50.01,
          description: 'Tanken',
          subtitle: '01. Okt 2023',
          liters: 31.6,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF8F9FB),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VehicleSelector(
              selectedVehicle: selectedVehicle,
              vehicles: vehicles,
              onChanged: onVehicleChanged,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'ZUSAMMENFASSUNG',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A5276).withValues(alpha: 0.7),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  SummaryCard(
                    icon: Icons.speed,
                    value: '${_formatNumber(selectedVehicle.mileage)} km',
                    label: 'Kilometerstand',
                  ),
                  const SummaryCard(
                    icon: Icons.account_balance_wallet,
                    value: '450,00 €',
                    label: 'Kosten / Monat',
                  ),
                  const SummaryCard(
                    icon: Icons.local_gas_station,
                    value: '8,4 L',
                    label: 'Ø Verbr. / 100km',
                  ),
                  const SummaryCard(
                    icon: Icons.build,
                    value: '15 Tage',
                    label: 'Service fällig',
                    valueColor: Color(0xFFE67E22),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LETZTE EINTRÄGE',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A5276).withValues(alpha: 0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // TODO: Navigate to timeline
                    },
                    child: const Text(
                      'Alle zeigen',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A5276),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: _recentEntries
                    .map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: EntryCard(entry: entry),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
