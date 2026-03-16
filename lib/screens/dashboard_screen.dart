import 'package:flutter/material.dart';
import '../models/entry.dart';
import '../models/vehicle.dart';
import '../services/entry_service.dart';
import '../services/settings_service.dart';
import '../theme.dart';
import '../widgets/entry_card.dart';
import '../widgets/summary_card.dart';
import '../widgets/vehicle_selector.dart';

class DashboardScreen extends StatefulWidget {
  final List<Vehicle> vehicles;
  final Vehicle selectedVehicle;
  final ValueChanged<Vehicle?> onVehicleChanged;

  const DashboardScreen({
    super.key,
    required this.vehicles,
    required this.selectedVehicle,
    required this.onVehicleChanged,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _entryService = EntryService();
  final _settings = SettingsService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: context.bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: StreamBuilder<List<Entry>>(
        stream: _entryService.getAllEntries(widget.selectedVehicle.id),
        builder: (context, snapshot) {
          final entries = snapshot.data ?? [];
          final recentEntries = entries.take(5).toList();

          // Compute KPIs
          final now = DateTime.now();
          final monthStart = DateTime(now.year, now.month);
          final monthCosts = entries
              .where((e) => e.date.isAfter(monthStart))
              .fold<double>(0, (sum, e) => sum + e.cost);

          // Average fuel consumption
          final fuelEntries = entries
              .where((e) => e.type == EntryType.fuel && e.liters != null && e.mileage != null)
              .toList();
          String avgConsumption = '–';
          if (fuelEntries.length >= 2) {
            final sorted = [...fuelEntries]..sort((a, b) => a.mileage!.compareTo(b.mileage!));
            final totalLiters = sorted.skip(1).fold<double>(0, (sum, e) => sum + e.liters!);
            final distKm = sorted.last.mileage! - sorted.first.mileage!;
            if (distKm > 0) {
              avgConsumption = '${(totalLiters / distKm * 100).toStringAsFixed(1).replaceAll('.', ',')} L';
            }
          }

          // Total entries count
          final totalEntries = entries.length;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VehicleSelector(
                  selectedVehicle: widget.selectedVehicle,
                  vehicles: widget.vehicles,
                  onChanged: widget.onVehicleChanged,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'ZUSAMMENFASSUNG',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.sectionHeader,
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
                        value: _settings.formatDistance(widget.selectedVehicle.mileage),
                        value: '${_formatNumber(widget.selectedVehicle.mileage)} km',
                        label: 'Kilometerstand',
                      ),
                      SummaryCard(
                        icon: Icons.account_balance_wallet,
                        value: _settings.formatCost(monthCosts),
                        value: '${monthCosts.toStringAsFixed(2).replaceAll('.', ',')} €',
                        label: 'Kosten / Monat',
                      ),
                      SummaryCard(
                        icon: Icons.local_gas_station,
                        value: avgConsumption,
                        label: 'Ø Verbr. / ${_settings.consumptionUnit}',
                      ),
                      SummaryCard(
                        icon: Icons.format_list_numbered,
                        value: '$totalEntries',
                        label: 'Einträge gesamt',
                      ),
                        label: 'Ø Verbr. / 100km',
                      ),
                      SummaryCard(
                        icon: Icons.format_list_numbered,
                        value: '$totalEntries',
                        label: 'Einträge gesamt',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'LETZTE EINTRÄGE',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.sectionHeader,
                      color: const Color(0xFF1A5276).withValues(alpha: 0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: recentEntries.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Center(
                            child: Text(
                              'Noch keine Einträge vorhanden',
                              style: TextStyle(
                                  fontSize: 15, color: context.textSecondary),
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE8ECF0)),
                          ),
                          child: const Center(
                            child: Text(
                              'Noch keine Einträge vorhanden',
                              style: TextStyle(
                                  fontSize: 15, color: Color(0xFF8E8E93)),
                            ),
                          ),
                        )
                      : Column(
                          children: recentEntries
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
          );
        },
      ),
    );
  }
}
