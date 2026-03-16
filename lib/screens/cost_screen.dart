import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/entry.dart';
import '../models/vehicle.dart';
import '../services/entry_service.dart';
import '../widgets/vehicle_selector.dart';

class CostScreen extends StatefulWidget {
  final List<Vehicle> vehicles;
  final Vehicle selectedVehicle;
  final ValueChanged<Vehicle?> onVehicleChanged;

  const CostScreen({
    super.key,
    required this.vehicles,
    required this.selectedVehicle,
    required this.onVehicleChanged,
  });

  @override
  State<CostScreen> createState() => _CostScreenState();
}

class _CostScreenState extends State<CostScreen> {
  final _entryService = EntryService();
  int _selectedPeriod = 0;
  final List<String> _periods = ['3M', '6M', '12M', 'Gesamt'];

  List<Entry> _filterByPeriod(List<Entry> entries) {
    if (_selectedPeriod == 3) return entries; // Gesamt
    final now = DateTime.now();
    final months = [3, 6, 12][_selectedPeriod];
    final cutoff = DateTime(now.year, now.month - months, now.day);
    return entries.where((e) => e.date.isAfter(cutoff)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          'Kosten',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF8F9FB),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: StreamBuilder<List<Entry>>(
        stream: _entryService.getAllEntries(widget.selectedVehicle.id),
        builder: (context, snapshot) {
          final allEntries = snapshot.data ?? [];
          final entries = _filterByPeriod(allEntries);

          final totalCost = entries.fold<double>(0, (s, e) => s + e.cost);
          final fuelCost = entries
              .where((e) => e.type == EntryType.fuel)
              .fold<double>(0, (s, e) => s + e.cost);
          final serviceCost = entries
              .where((e) => e.type == EntryType.service)
              .fold<double>(0, (s, e) => s + e.cost);
          final otherCost = entries
              .where((e) => e.type == EntryType.otherCost)
              .fold<double>(0, (s, e) => s + e.cost);

          // Months in period for average
          final periodMonths = _selectedPeriod == 3
              ? _calcMonthSpan(entries)
              : [3, 6, 12][_selectedPeriod];
          final avgPerMonth =
              periodMonths > 0 ? totalCost / periodMonths : 0.0;

          // Percentages for donut
          final fuelPct = totalCost > 0 ? (fuelCost / totalCost * 100) : 0.0;
          final servicePct =
              totalCost > 0 ? (serviceCost / totalCost * 100) : 0.0;
          final otherPct =
              totalCost > 0 ? (otherCost / totalCost * 100) : 0.0;

          // Monthly data for bar chart
          final monthlyData = _calcMonthlyData(entries);

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
                // Period Filter Chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: List.generate(_periods.length, (index) {
                      final isSelected = _selectedPeriod == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedPeriod = index),
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
                              _periods[index],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
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
                const SizedBox(height: 16),
                // KPI Cards
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
                      _buildKpiCard(
                        label: 'Gesamtkosten',
                        value: _formatCurrency(totalCost),
                      ),
                      _buildKpiCard(
                        label: 'Ø / Monat',
                        value: _formatCurrency(avgPerMonth),
                      ),
                      _buildKpiCard(
                        label: 'Kraftstoff',
                        value: _formatCurrency(fuelCost),
                        subtitle: totalCost > 0
                            ? '${fuelPct.toStringAsFixed(0)}% vom Gesamt'
                            : null,
                      ),
                      _buildKpiCard(
                        label: 'Service/Wartung',
                        value: _formatCurrency(serviceCost),
                        subtitle: totalCost > 0
                            ? '${servicePct.toStringAsFixed(0)}% vom Gesamt'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Donut Chart
                _buildCostDistribution(
                    fuelCost, serviceCost, otherCost, fuelPct, servicePct, otherPct),
                const SizedBox(height: 20),
                // Bar Chart
                _buildMonthlyChart(monthlyData),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  int _calcMonthSpan(List<Entry> entries) {
    if (entries.isEmpty) return 1;
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    final first = sorted.first.date;
    final last = sorted.last.date;
    final months =
        (last.year - first.year) * 12 + (last.month - first.month) + 1;
    return months < 1 ? 1 : months;
  }

  List<_MonthData> _calcMonthlyData(List<Entry> entries) {
    final now = DateTime.now();
    final months = <_MonthData>[];
    for (var i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i);
      final monthEntries = entries.where(
          (e) => e.date.year == date.year && e.date.month == date.month);
      final total = monthEntries.fold<double>(0, (s, e) => s + e.cost);
      months.add(_MonthData(_shortMonth(date.month), total));
    }
    return months;
  }

  String _shortMonth(int month) {
    const names = [
      'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'
    ];
    return names[month - 1];
  }

  String _formatCurrency(double value) {
    return '${value.toStringAsFixed(2).replaceAll('.', ',')} €';
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
          const Spacer(),
          if (subtitle != null)
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
            ),
        ],
      ),
    );
  }

  Widget _buildCostDistribution(double fuel, double service, double other,
      double fuelPct, double servicePct, double otherPct) {
    final hasData = fuel + service + other > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_outline,
                  size: 20, color: Color(0xFF1A5276)),
              SizedBox(width: 8),
              Text(
                'Kostenverteilung',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!hasData)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Keine Daten vorhanden',
                    style: TextStyle(color: Color(0xFF8E8E93))),
              ),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: [
                            if (fuel > 0)
                              PieChartSectionData(
                                value: fuel,
                                color: const Color(0xFF1A5276),
                                radius: 22,
                                showTitle: false,
                              ),
                            if (service > 0)
                              PieChartSectionData(
                                value: service,
                                color: const Color(0xFF5DADE2),
                                radius: 22,
                                showTitle: false,
                              ),
                            if (other > 0)
                              PieChartSectionData(
                                value: other,
                                color: const Color(0xFF85C1E9),
                                radius: 22,
                                showTitle: false,
                              ),
                          ],
                        ),
                      ),
                      const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '100%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            'GESAMT',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF8E8E93),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      _buildLegendItem('Tanken',
                          '${fuelPct.toStringAsFixed(0)}%', const Color(0xFF1A5276)),
                      const SizedBox(height: 12),
                      _buildLegendItem('Service',
                          '${servicePct.toStringAsFixed(0)}%', const Color(0xFF5DADE2)),
                      const SizedBox(height: 12),
                      _buildLegendItem('Sonstiges',
                          '${otherPct.toStringAsFixed(0)}%', const Color(0xFF85C1E9)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyChart(List<_MonthData> data) {
    final maxY = data.fold<double>(0, (max, d) => d.value > max ? d.value : max);
    final chartMaxY = maxY > 0 ? maxY * 1.2 : 100;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart,
                  size: 20, color: Color(0xFF1A5276)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Monatliche Kosten',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
              Text(
                'Letzte 6 Monate',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF8E8E93).withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: chartMaxY.toDouble(),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(2).replaceAll('.', ',')} €',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < data.length) {
                          final isLast = index == data.length - 1;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              data[index].label,
                              style: TextStyle(
                                fontSize: 12,
                                color: isLast
                                    ? const Color(0xFF1A5276)
                                    : const Color(0xFF8E8E93),
                                fontWeight: isLast
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(data.length, (index) {
                  final isLast = index == data.length - 1;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data[index].value,
                        color: isLast
                            ? const Color(0xFF1A5276)
                            : const Color(0xFFD6E4F0),
                        width: 28,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthData {
  final String label;
  final double value;
  _MonthData(this.label, this.value);
}
