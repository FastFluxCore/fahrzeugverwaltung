import 'package:flutter/material.dart';
import '../models/entry.dart';
import '../models/vehicle.dart';
import '../widgets/vehicle_selector.dart';

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
  int _selectedFilter = 0;
  final List<String> _filters = ['Alle', 'Service', 'Tanken', 'Sonstige'];
  final TextEditingController _searchController = TextEditingController();

  // TODO: Replace with Firestore data
  final List<Entry> _entries = [
    Entry(
      id: '1',
      type: EntryType.service,
      date: DateTime(2026, 3, 14),
      cost: 342.50,
      mileage: 45200,
      description: 'Inspektion & Ölwechsel',
      subtitle: 'KFZ-Meisterbetrieb Schmidt',
      serviceType: 'Inspektion',
      workshop: 'KFZ-Meisterbetrieb Schmidt',
    ),
    Entry(
      id: '2',
      type: EntryType.fuel,
      date: DateTime(2026, 3, 8),
      cost: 84.12,
      description: 'Tanken',
      subtitle: 'Aral',
      liters: 42.5,
      pricePerLiter: 1.979,
      station: 'Aral',
    ),
    Entry(
      id: '3',
      type: EntryType.otherCost,
      date: DateTime(2026, 2, 1),
      cost: 128.90,
      description: 'Kfz-Versicherung',
      subtitle: 'HUK-Coburg (Vierteljährlich)',
      category: 'Versicherung',
      interval: 'vierteljährlich',
    ),
    Entry(
      id: '4',
      type: EntryType.fuel,
      date: DateTime(2026, 1, 22),
      cost: 76.55,
      description: 'Tanken',
      subtitle: 'Shell',
      liters: 38.7,
      pricePerLiter: 1.979,
      station: 'Shell',
    ),
    Entry(
      id: '5',
      type: EntryType.fuel,
      date: DateTime(2026, 1, 24),
      cost: 65.30,
      description: 'Tanken',
      subtitle: 'Total',
      liters: 33.1,
      pricePerLiter: 1.972,
      station: 'Total',
    ),
  ];

  List<Entry> get _filteredEntries {
    var entries = _entries;
    if (_selectedFilter == 1) {
      entries = entries.where((e) => e.type == EntryType.service).toList();
    } else if (_selectedFilter == 2) {
      entries = entries.where((e) => e.type == EntryType.fuel).toList();
    } else if (_selectedFilter == 3) {
      entries = entries.where((e) => e.type == EntryType.otherCost).toList();
    }

    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      entries = entries
          .where((e) =>
              e.description.toLowerCase().contains(query) ||
              (e.subtitle?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  Map<String, List<Entry>> get _groupedEntries {
    final map = <String, List<Entry>>{};
    for (final entry in _filteredEntries) {
      final key = _monthYearKey(entry.date);
      map.putIfAbsent(key, () => []).add(entry);
    }
    return map;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedEntries;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          'Logbuch',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF8F9FB),
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
                hintStyle: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 15,
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF8E8E93)),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
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
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1A5276)
                              : const Color(0xFFE0E0E0),
                        ),
                      ),
                      child: Text(
                        _filters[index],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFE8ECF0)),
          // Timeline entries
          Expanded(
            child: grouped.isEmpty
                ? const Center(
                    child: Text(
                      'Keine Einträge gefunden',
                      style: TextStyle(fontSize: 15, color: Color(0xFF8E8E93)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final monthKey = grouped.keys.elementAt(index);
                      final entries = grouped[monthKey]!;
                      return _buildMonthSection(monthKey, entries);
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
              color: const Color(0xFF1A5276).withValues(alpha: 0.7),
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
      child: InkWell(
        onTap: () {
          // TODO: Open detail view
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8ECF0)),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (entry.subtitle != null)
                      Text(
                        entry.subtitle!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.cost.toStringAsFixed(2).replaceAll('.', ',')} €',
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
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  if (entry.mileage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${_formatNumber(entry.mileage!)} km',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                  if (entry.type == EntryType.fuel && entry.liters != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${entry.liters!.toStringAsFixed(1).replaceAll('.', ',')} L • ${entry.pricePerLiter?.toStringAsFixed(3).replaceAll('.', ',')} €/L',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
