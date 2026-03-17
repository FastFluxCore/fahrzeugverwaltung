import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../services/vehicle_service.dart';
import '../theme.dart';
import 'add_vehicle_screen.dart';
import 'export_screen.dart';

class ProfileScreen extends StatefulWidget {
  final List<Vehicle> vehicles;
  final Vehicle selectedVehicle;

  const ProfileScreen({
    super.key,
    required this.vehicles,
    required this.selectedVehicle,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _settings = SettingsService();

  @override
  void initState() {
    super.initState();
    _settings.addListener(_rebuild);
  }

  @override
  void dispose() {
    _settings.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final authService = AuthService();
    final vehicleService = VehicleService();

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text(
          'Einstellungen',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: false,
        backgroundColor: context.bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    backgroundColor: const Color(0xFF1A5276),
                    child: user?.photoURL == null
                        ? const Icon(Icons.person,
                            color: Colors.white, size: 32)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Benutzer',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Logout button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => authService.signOut(),
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text(
                    'Abmelden',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A5276),
                    side: const BorderSide(color: Color(0xFF1A5276)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            // App-Einstellungen
            _buildSectionHeader('APP-EINSTELLUNGEN'),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: Icons.palette_outlined,
                    title: 'Design',
                    subtitle: 'Hell, Dunkel oder System',
                    trailing: _settings.themeLabel,
                    onTap: () => _showThemePicker(context),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildSettingsTile(
                    icon: Icons.straighten,
                    title: 'Einheiten',
                    subtitle: null,
                    trailing: _settings.unitLabel,
                    onTap: () => _showUnitPicker(context),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildSettingsTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Währung',
                    subtitle: null,
                    trailing: _settings.currencyLabel,
                    onTap: () => _showCurrencyPicker(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Fahrzeug-Einstellungen
            _buildSectionHeader('FAHRZEUGE'),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                children: [
                  ...widget.vehicles.asMap().entries.map((e) {
                    final index = e.key;
                    final vehicle = e.value;
                    return Column(
                      children: [
                        if (index > 0)
                          const Divider(height: 1, indent: 56),
                        _buildVehicleTile(
                            context, vehicle, vehicleService),
                      ],
                    );
                  }),
                  const Divider(height: 1, indent: 56),
                  // Add vehicle button
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddVehicleScreen()),
                    ),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_outline,
                              color: Color(0xFF1A5276), size: 22),
                          SizedBox(width: 14),
                          Text(
                            'Fahrzeug hinzufügen',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A5276),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Export
            _buildSectionHeader('EXPORT'),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.borderColor),
              ),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExportScreen(
                      vehicles: widget.vehicles,
                      initialVehicle: widget.selectedVehicle,
                    ),
                  ),
                ),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.subtleBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.picture_as_pdf, color: context.brand, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fahrzeughistorie exportieren',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: context.textPrimary,
                              ),
                            ),
                            Text(
                              'PDF mit kompletter Fahrzeughistorie',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: context.textSecondary, size: 22),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Gefahrenzone
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'GEFAHRENZONE',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFC62828).withValues(alpha: 0.7),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () => _showDeleteAccountDialog(
                    context, authService, vehicleService),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC62828).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person_off_outlined,
                          color:
                              const Color(0xFFC62828).withValues(alpha: 0.8),
                          size: 22),
                      const SizedBox(width: 14),
                      Text(
                        'Account löschen',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color:
                              const Color(0xFFC62828).withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleTile(
      BuildContext context, Vehicle vehicle, VehicleService vehicleService) {
    final isSelected = vehicle.id == widget.selectedVehicle.id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? context.brand.withValues(alpha: 0.1)
                  : context.subtleBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.directions_car,
                color: isSelected
                    ? context.brand
                    : context.textSecondary,
                size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${vehicle.brand} ${vehicle.model}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: context.textPrimary,
                  ),
                ),
                Text(
                  '${vehicle.licensePlate} • ${vehicle.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddVehicleScreen(vehicle: vehicle),
              ),
            ),
            icon: Icon(Icons.edit_outlined,
                color: context.textSecondary, size: 22),
          ),
          IconButton(
            onPressed: () =>
                _showDeleteVehicleDialog(context, vehicle, vehicleService),
            icon: Icon(Icons.delete_outline,
                color: context.textSecondary, size: 22),
          ),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Design',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildOption('System', _settings.themeMode == ThemeMode.system,
                () => _settings.setThemeMode(ThemeMode.system), context),
            _buildOption('Hell', _settings.themeMode == ThemeMode.light,
                () => _settings.setThemeMode(ThemeMode.light), context),
            _buildOption('Dunkel', _settings.themeMode == ThemeMode.dark,
                () => _settings.setThemeMode(ThemeMode.dark), context),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showUnitPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Einheiten',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildOption('Metrisch (km)', _settings.unit == 'km',
                () => _settings.setUnit('km'), context),
            _buildOption('Imperial (mi)', _settings.unit == 'mi',
                () => _settings.setUnit('mi'), context),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Währung',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildOption('Euro (€)', _settings.currency == '€',
                () => _settings.setCurrency('€'), context),
            _buildOption('Dollar (\$)', _settings.currency == '\$',
                () => _settings.setCurrency('\$'), context),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
      String label, bool selected, VoidCallback onTap, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          onTap();
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? context.brand.withValues(alpha: 0.08)
                : context.subtleBg,
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(color: context.brand)
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected
                        ? context.brand
                        : context.textPrimary,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check, color: context.brand, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required String trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.subtleBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: context.brand, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: context.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              trailing,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A5276),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: context.sectionHeader,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showDeleteVehicleDialog(
      BuildContext context, Vehicle vehicle, VehicleService vehicleService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fahrzeug löschen'),
        content: Text(
          '„${vehicle.brand} ${vehicle.model}" und alle zugehörigen Einträge unwiderruflich löschen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              vehicleService.deleteVehicle(vehicle.id);
            },
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFC62828)),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AuthService authService,
      VehicleService vehicleService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account löschen'),
        content: const Text(
          'Möchten Sie Ihren Account und alle zugehörigen Daten unwiderruflich löschen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Delete all vehicles (and their subcollections)
                for (final vehicle in widget.vehicles) {
                  await vehicleService.deleteVehicle(vehicle.id);
                }
                // Delete user document
                final uid = FirebaseAuth.instance.currentUser!.uid;
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .delete();
                // Delete auth account
                await authService.deleteAccount();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fehler: $e')),
                  );
                }
              }
            },
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFC62828)),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
