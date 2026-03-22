import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/settings_service.dart';
import '../theme.dart';

enum ReminderUrgency { ok, upcoming, overdue }

class Reminder {
  final String title;
  final String subtitle;
  final IconData icon;
  final ReminderUrgency urgency;

  const Reminder({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.urgency,
  });
}

List<Reminder> buildReminders(Vehicle vehicle) {
  final reminders = <Reminder>[];
  final now = DateTime.now();

  // TÜV/HU
  if (vehicle.nextTuev != null) {
    final days = vehicle.nextTuev!.difference(now).inDays;
    final urgency = days < 0
        ? ReminderUrgency.overdue
        : days <= 30
            ? ReminderUrgency.upcoming
            : ReminderUrgency.ok;
    final subtitle = days < 0
        ? 'Überfällig seit ${-days} Tagen'
        : days == 0
            ? 'Heute fällig'
            : 'In $days Tagen (${_formatDate(vehicle.nextTuev!)})';
    reminders.add(Reminder(
      title: 'TÜV/HU',
      subtitle: subtitle,
      icon: Icons.verified_user_outlined,
      urgency: urgency,
    ));
  }

  // Inspektion
  if (vehicle.nextInspection != null) {
    final days = vehicle.nextInspection!.difference(now).inDays;
    final urgency = days < 0
        ? ReminderUrgency.overdue
        : days <= 30
            ? ReminderUrgency.upcoming
            : ReminderUrgency.ok;
    final subtitle = days < 0
        ? 'Überfällig seit ${-days} Tagen'
        : days == 0
            ? 'Heute fällig'
            : 'In $days Tagen (${_formatDate(vehicle.nextInspection!)})';
    reminders.add(Reminder(
      title: 'Inspektion',
      subtitle: subtitle,
      icon: Icons.build_outlined,
      urgency: urgency,
    ));
  }

  // Ölwechsel
  if (vehicle.oilChangeInterval != null && vehicle.lastOilChangeMileage != null) {
    final unit = SettingsService().distanceUnit;
    final nextOilChange = vehicle.lastOilChangeMileage! + vehicle.oilChangeInterval!;
    final remaining = nextOilChange - vehicle.mileage;
    final urgency = remaining <= 0
        ? ReminderUrgency.overdue
        : remaining <= 1000
            ? ReminderUrgency.upcoming
            : ReminderUrgency.ok;
    final subtitle = remaining <= 0
        ? 'Überfällig seit ${-remaining} $unit'
        : 'In $remaining $unit (bei $nextOilChange $unit)';
    reminders.add(Reminder(
      title: 'Ölwechsel',
      subtitle: subtitle,
      icon: Icons.oil_barrel_outlined,
      urgency: urgency,
    ));
  }

  // Sort: overdue first, then upcoming, then ok
  reminders.sort((a, b) => a.urgency.index.compareTo(b.urgency.index));
  // Reverse so overdue is first (index 2 > 1 > 0)
  reminders.sort((a, b) => b.urgency.index.compareTo(a.urgency.index));

  return reminders;
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}

class ReminderCard extends StatelessWidget {
  final Reminder reminder;

  const ReminderCard({super.key, required this.reminder});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (reminder.urgency) {
      ReminderUrgency.overdue => (
          const Color(0xFFC62828),
          Colors.white,
        ),
      ReminderUrgency.upcoming => (
          const Color(0xFFF57C00),
          Colors.white,
        ),
      ReminderUrgency.ok => (
          context.subtleBg,
          context.textPrimary,
        ),
    };

    final iconBg = switch (reminder.urgency) {
      ReminderUrgency.overdue => Colors.white.withValues(alpha: 0.2),
      ReminderUrgency.upcoming => Colors.white.withValues(alpha: 0.2),
      ReminderUrgency.ok => context.brand.withValues(alpha: 0.1),
    };

    final subtitleColor = switch (reminder.urgency) {
      ReminderUrgency.overdue => Colors.white.withValues(alpha: 0.85),
      ReminderUrgency.upcoming => Colors.white.withValues(alpha: 0.85),
      ReminderUrgency.ok => context.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(reminder.icon, color: fg, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reminder.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          if (reminder.urgency != ReminderUrgency.ok)
            Icon(
              reminder.urgency == ReminderUrgency.overdue
                  ? Icons.error_outline
                  : Icons.warning_amber_rounded,
              color: Colors.white.withValues(alpha: 0.8),
              size: 22,
            ),
        ],
      ),
    );
  }
}
