import 'package:flutter/material.dart';
import '../models/entry.dart';
import '../services/entry_service.dart';
import '../services/settings_service.dart';
import '../models/vehicle.dart';
import '../theme.dart';
import '../widgets/vehicle_selector.dart';
import 'add_fuel_screen.dart';
import 'add_other_cost_screen.dart';
import 'add_service_screen.dart';

class LogbookScreen extends StatefulWidget {
  final List<Vehicle> vehicles;
  final Vehicle selectedVehicle;
  final ValueChanged<Vehicle?> onVehicleChanged;

  const LogbookScreen({
    super.key,
    required this.vehicles,
    required this.selectedVehicle,
    required this.onVehicleChanged,
  });

  @override
  State<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends State<LogbookScreen> {
  final _entryService = EntryService();
  final _settings = SettingsService();
  int _selectedFilter = 0;
  final List<String> _filters = ['Alle', 'Service', 'Tanken', 'Sonstige'];
  final TextEditingController _searchController = TextEditingController();

  List<Entry> _applyFilters(List<Entry> entries) {
    var filtered = entries;
    if (_selectedFilter == 1) {
      filtered = filtered.where((e) => e.type == EntryType.service).toList();
    } else if (_selectedFilter == 2) {
      filtered = filtered.where((e) => e.type == EntryType.fuel).toList();
    } else if (_selectedFilter == 3) {
      filtered = filtered.where((e) => e.type == EntryType.otherCost).toList();
    }

    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((e) =>
              e.description.toLowerCase().contains(query) ||
              (e.subtitle?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    return filtered;
  }

  Map<String, List<Entry>> _groupByMonth(List<Entry> entries) {
    final map = <String, List<Entry>>{};
    for (final entry in entries) {
      final key = _monthYearKey(entry.date);
      map.putIfAbsent(key, () => []).add(entry);
    }
    return map;
  }

  void _openEditScreen(Entry entry) {
    final vehicleId = widget.selectedVehicle.id;
    final mileage = widget.selectedVehicle.mileage;

    Widget screen;
    switch (entry.type) {
      case EntryType.fuel:
        screen = AddFuelScreen(
          vehicleId: vehicleId,
          currentMileage: mileage,
          entry: entry,
        );
      case EntryType.service:
        screen = AddServiceScreen(
          vehicleId: vehicleId,
          currentMileage: mileage,
          entry: entry,
        );
      case EntryType.otherCost:
        screen = AddOtherCostScreen(
          vehicleId: vehicleId,
          entry: entry,
        );
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _deleteEntry(Entry entry) async {
    final vehicleId = widget.selectedVehicle.id;
    switch (entry.type) {
      case EntryType.fuel:
        await _entryService.deleteFuelLog(vehicleId, entry.id);
      case EntryType.service:
        await _entryService.deleteService(vehicleId, entry.id);
      case EntryType.otherCost:
        await _entryService.deleteOtherCost(vehicleId, entry.id);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text(
          'Logbuch',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: context.bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          VehicleSelector(
            selectedVehicle: widget.selectedVehicle,
            vehicles: widget.vehicles,
            onChanged: widget.onVehicleChanged,
          ),
          const SizedBox(height: 8),
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Einträge durchsuchen...',
                hintStyle: TextStyle(
                  color: context.textSecondary,
                  fontSize: 15,
                ),
                prefixIcon: Icon(Icons.search, color: context.textSecondary),
                filled: true,
                fillColor: context.subtleBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(_filters.length, (index) {
                final isSelected = _selectedFilter == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1A5276)
                            : context.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1A5276)
                              : context.borderColor,
                        ),
                      ),
                      child: Text(
                        _filters[index],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : context.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: context.borderColor),
          // Timeline entries
          Expanded(
            child: StreamBuilder<List<Entry>>(
              stream: _entryService.getAllEntries(widget.selectedVehicle.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allEntries = snapshot.data ?? [];
                final filtered = _applyFilters(allEntries);
                final grouped = _groupByMonth(filtered);

                if (grouped.isEmpty) {
                  return Center(
                    child: Text(
                      'Keine Einträge gefunden',
                      style: TextStyle(fontSize: 15, color: context.textSecondary),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final monthKey = grouped.keys.elementAt(index);
                    final entries = grouped[monthKey]!;
                    return _buildMonthSection(monthKey, entries);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSection(String monthKey, List<Entry> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            monthKey,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.sectionHeader,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...entries.map((entry) => _buildTimelineEntry(entry)),
      ],
    );
  }

  Widget _buildTimelineEntry(Entry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Dismissible(
        key: ValueKey(entry.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => _confirmDismiss(entry),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFC62828),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: GestureDetector(
          onTap: () => _openEditScreen(entry),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.borderColor),
            ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEntryIcon(entry),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.description,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (entry.subtitle != null)
                      Text(
                        entry.subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      _settings.formatCost(entry.cost),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A5276),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDateShort(entry.date),
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondary,
                    ),
                  ),
                  if (entry.mileage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _settings.formatDistance(entry.mileage!),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                  if (entry.type == EntryType.fuel && entry.liters != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${entry.liters!.toStringAsFixed(1).replaceAll('.', ',')} ${_settings.volumeUnit} • ${entry.pricePerLiter?.toStringAsFixed(3).replaceAll('.', ',')} ${_settings.pricePerVolumeUnit}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Future<bool> _confirmDismiss(Entry entry) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eintrag löschen'),
        content: Text('„${entry.description}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFC62828)),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (result == true) {
      await _deleteEntry(entry);
      return true;
    }
    return false;
  }

  Widget _buildEntryIcon(Entry entry) {
    final (Color bg, Color fg, IconData icon) = switch (entry.type) {
      EntryType.fuel => (
          const Color(0xFFE8F0FE),
          const Color(0xFF1A5276),
          Icons.local_gas_station,
        ),
      EntryType.service => (
          const Color(0xFFFFF3E0),
          const Color(0xFFE67E22),
          Icons.build,
        ),
      EntryType.otherCost => (
          const Color(0xFFFCE4EC),
          const Color(0xFFC62828),
          Icons.euro,
        ),
    };

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: fg, size: 22),
    );
  }

  String _formatDateShort(DateTime date) {
    const months = [
      'JAN', 'FEB', 'MÄR', 'APR', 'MAI', 'JUN',
      'JUL', 'AUG', 'SEP', 'OKT', 'NOV', 'DEZ',
    ];
    return '${date.day.toString().padLeft(2, '0')}. ${months[date.month - 1]}';
  }

  String _monthYearKey(DateTime date) {
    const months = [
      'JANUAR', 'FEBRUAR', 'MÄRZ', 'APRIL', 'MAI', 'JUNI',
      'JULI', 'AUGUST', 'SEPTEMBER', 'OKTOBER', 'NOVEMBER', 'DEZEMBER',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

}
