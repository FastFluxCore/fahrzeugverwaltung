import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/vehicle.dart';
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
  int _selectedPeriod = 0;
  final List<String> _periods = ['3M', '6M', '12M', 'Gesamt'];

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
      body: SingleChildScrollView(
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
                      onTap: () => setState(() => _selectedPeriod = index),
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
                    value: '€2.450,80',
                    trend: '+4.2%',
                    trendUp: true,
                  ),
                  _buildKpiCard(
                    label: 'Ø / Monat',
                    value: '€816,93',
                    trend: '-1.8%',
                    trendUp: false,
                  ),
                  _buildKpiCard(
                    label: 'Kraftstoff',
                    value: '€1.120,40',
                    subtitle: '45% vom Gesamt',
                  ),
                  _buildKpiCard(
                    label: 'Service/Wartung',
                    value: '€350,00',
                    subtitle: 'Nächster: 12.500km',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Donut Chart
            _buildCostDistribution(),
            const SizedBox(height: 20),
            // Bar Chart
            _buildMonthlyChart(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    String? trend,
    bool? trendUp,
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const Spacer(),
          if (trend != null)
            Row(
              children: [
                Icon(
                  trendUp == true
                      ? Icons.trending_up
                      : Icons.trending_down,
                  size: 16,
                  color: trendUp == true
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFC62828),
                ),
                const SizedBox(width: 4),
                Text(
                  trend,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: trendUp == true
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
                  ),
                ),
              ],
            ),
          if (subtitle != null)
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
            ),
        ],
      ),
    );
  }

  Widget _buildCostDistribution() {
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
                          PieChartSectionData(
                            value: 45,
                            color: const Color(0xFF1A5276),
                            radius: 22,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: 25,
                            color: const Color(0xFF5DADE2),
                            radius: 22,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: 20,
                            color: const Color(0xFF85C1E9),
                            radius: 22,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: 10,
                            color: const Color(0xFFD5D8DC),
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
                    _buildLegendItem('Tanken', '45%', const Color(0xFF1A5276)),
                    const SizedBox(height: 12),
                    _buildLegendItem(
                        'Fixkosten', '25%', const Color(0xFF5DADE2)),
                    const SizedBox(height: 12),
                    _buildLegendItem(
                        'Service', '20%', const Color(0xFF85C1E9)),
                    const SizedBox(height: 12),
                    _buildLegendItem(
                        'Sonstiges', '10%', const Color(0xFFD5D8DC)),
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

  Widget _buildMonthlyChart() {
    final months = ['Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov'];
    final values = [620.0, 480.0, 550.0, 720.0, 940.0, 380.0];

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
                maxY: 1100,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '€${rod.toY.toStringAsFixed(0)}',
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
                        if (index >= 0 && index < months.length) {
                          final isHighlighted = index == 4;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              months[index],
                              style: TextStyle(
                                fontSize: 12,
                                color: isHighlighted
                                    ? const Color(0xFF1A5276)
                                    : const Color(0xFF8E8E93),
                                fontWeight: isHighlighted
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
                barGroups: List.generate(values.length, (index) {
                  final isHighlighted = index == 4;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: values[index],
                        color: isHighlighted
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
