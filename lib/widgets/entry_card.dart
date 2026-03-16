import 'package:flutter/material.dart';
import '../models/entry.dart';
import '../services/settings_service.dart';
import '../theme.dart';

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
    final settings = SettingsService();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            _buildIcon(context),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.description,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatSubtitle(),
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-${settings.formatCost(entry.cost)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                if (_trailingSubtitle(settings) != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      _trailingSubtitle(settings)!,
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
    );
  }

  Widget _buildIcon(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (Color bg, Color fg, IconData icon) = switch (entry.type) {
      EntryType.fuel => (
          isDark ? const Color(0xFF1A3A5C) : const Color(0xFFE8F0FE),
          const Color(0xFF5DADE2),
          Icons.local_gas_station,
        ),
      EntryType.service => (
          isDark ? const Color(0xFF1B3A1B) : const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
          Icons.build,
        ),
      EntryType.otherCost => (
          isDark ? const Color(0xFF3A1B1B) : const Color(0xFFFCE4EC),
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

  String _formatSubtitle() {
    final date = '${entry.date.day.toString().padLeft(2, '0')}. '
        '${_monthName(entry.date.month)} ${entry.date.year}';
    if (entry.subtitle != null) return '${entry.subtitle} • $date';
    return date;
  }

  String? _trailingSubtitle(SettingsService settings) {
    if (entry.type == EntryType.fuel && entry.liters != null) {
      final vol = settings.displayVolume(entry.liters!);
      return '${vol.toStringAsFixed(1).replaceAll('.', ',')} ${settings.volumeUnit}';
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
