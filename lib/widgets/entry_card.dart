import 'package:flutter/material.dart';
import '../models/entry.dart';

class EntryCard extends StatelessWidget {
  final Entry entry;
  final VoidCallback? onTap;

  const EntryCard({
    super.key,
    required this.entry,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8ECF0)),
        ),
        child: Row(
          children: [
            _buildIcon(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.description,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatSubtitle(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-${entry.cost.toStringAsFixed(2).replaceAll('.', ',')}€',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                if (_trailingSubtitle() != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      _trailingSubtitle()!,
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
    );
  }

  Widget _buildIcon() {
    final (Color bg, Color fg, IconData icon) = switch (entry.type) {
      EntryType.fuel => (
          const Color(0xFFE8F0FE),
          const Color(0xFF1A5276),
          Icons.local_gas_station,
        ),
      EntryType.service => (
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
          Icons.build,
        ),
      EntryType.otherCost => (
          const Color(0xFFFCE4EC),
          const Color(0xFFC62828),
          Icons.local_parking,
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

  String _formatSubtitle() {
    final date = '${entry.date.day.toString().padLeft(2, '0')}. '
        '${_monthName(entry.date.month)} ${entry.date.year}';
    if (entry.subtitle != null) return '${entry.subtitle}';
    return date;
  }

  String? _trailingSubtitle() {
    if (entry.type == EntryType.fuel && entry.liters != null) {
      return '${entry.liters!.toStringAsFixed(1).replaceAll('.', ',')} L';
    }
    if (entry.type == EntryType.service) return 'Werkstatt';
    if (entry.type == EntryType.otherCost) return 'Sonstiges';
    return null;
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez',
    ];
    return months[month - 1];
  }
}
