import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/entry.dart';
import '../models/vehicle.dart';
import '../services/entry_service.dart';
import '../services/settings_service.dart';
import '../theme.dart';
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
  final _settings = SettingsService();
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
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text(
          'Kosten',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: context.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: context.bgColor,
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
                                  : context.cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF1A5276)
                                    : context.borderColor,
                              ),
                            ),
                            child: Text(
                              _periods[index],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
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
                const SizedBox(height: 20),
                // Fuel consumption trend
                _buildConsumptionTrend(allEntries),
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
    return _settings.formatCost(value);
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: context.textSecondary),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
          ),
          const Spacer(),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: context.textSecondary),
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
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_outline,
                  size: 20, color: Color(0xFF1A5276)),
              const SizedBox(width: 8),
              Text(
                'Kostenverteilung',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!hasData)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Keine Daten vorhanden',
                    style: TextStyle(color: context.textSecondary)),
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
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '100%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                          Text(
                            'GESAMT',
                            style: TextStyle(
                              fontSize: 10,
                              color: context.textSecondary,
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
            style: TextStyle(fontSize: 14, color: context.textPrimary),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
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
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart,
                  size: 20, color: Color(0xFF1A5276)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Monatliche Kosten',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
              ),
              Text(
                'Letzte 6 Monate',
                style: TextStyle(
                  fontSize: 12,
                  color: context.textSecondary.withValues(alpha: 0.8),
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
                        '${rod.toY.toStringAsFixed(2).replaceAll('.', ',')} ${_settings.currency}',
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
                                    : context.textSecondary,
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
  List<_ConsumptionPoint> _calcConsumptionPoints(List<Entry> entries) {
    final fuelEntries = entries
        .where((e) => e.type == EntryType.fuel && e.liters != null && e.mileage != null)
        .toList()
      ..sort((a, b) => a.mileage!.compareTo(b.mileage!));

    final points = <_ConsumptionPoint>[];
    for (var i = 1; i < fuelEntries.length; i++) {
      final prev = fuelEntries[i - 1];
      final curr = fuelEntries[i];
      final distKm = curr.mileage! - prev.mileage!;
      if (distKm > 0) {
        final consumption = curr.liters! / distKm * 100;
        points.add(_ConsumptionPoint(curr.date, consumption));
      }
    }
    return points;
  }

  Widget _buildConsumptionTrend(List<Entry> entries) {
    final points = _calcConsumptionPoints(entries);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, size: 20, color: Color(0xFF1A5276)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verbrauchstrend',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
              ),
              Text(
                _settings.consumptionUnit,
                style: TextStyle(
                  fontSize: 12,
                  color: context.textSecondary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (points.length < 2)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Mindestens 3 Tankvorgänge mit km-Stand nötig',
                  style: TextStyle(color: context.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            _buildConsumptionChart(points),
        ],
      ),
    );
  }

  Widget _buildConsumptionChart(List<_ConsumptionPoint> points) {
    final avg = points.fold<double>(0, (s, p) => s + p.value) / points.length;
    final minY = points.fold<double>(points.first.value, (m, p) => p.value < m ? p.value : m);
    final maxY = points.fold<double>(points.first.value, (m, p) => p.value > m ? p.value : m);
    final padding = (maxY - minY) * 0.2;
    final chartMinY = (minY - padding).clamp(0.0, double.infinity);
    final chartMaxY = maxY + padding;

    // Build spots
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].value));
    }

    // Show max ~6 labels on x-axis
    final labelInterval = points.length <= 6 ? 1 : (points.length / 6).ceil();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: chartMinY,
          maxY: chartMaxY,
          lineBarsData: [
            // Consumption line
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: const Color(0xFF1A5276),
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: const Color(0xFF1A5276),
                    strokeWidth: 1.5,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF1A5276).withValues(alpha: 0.08),
              ),
            ),
            // Average line
            LineChartBarData(
              spots: [
                FlSpot(0, avg),
                FlSpot((points.length - 1).toDouble(), avg),
              ],
              isCurved: false,
              color: const Color(0xFFF57C00),
              barWidth: 1.5,
              dashArray: [6, 4],
              dotData: const FlDotData(show: false),
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) return const SizedBox.shrink();
                  if (index % labelInterval != 0 && index != points.length - 1) {
                    return const SizedBox.shrink();
                  }
                  final d = points[index].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 10, color: context.textSecondary),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min || value == meta.max) return const SizedBox.shrink();
                  return Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(fontSize: 10, color: context.textSecondary),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (chartMaxY - chartMinY) / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: context.borderColor,
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  if (spot.barIndex == 1) return null; // skip avg line tooltip
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(1).replaceAll('.', ',')} ${_settings.consumptionUnit}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ConsumptionPoint {
  final DateTime date;
  final double value;
  _ConsumptionPoint(this.date, this.value);
}

class _MonthData {
  final String label;
  final double value;
  _MonthData(this.label, this.value);
}
