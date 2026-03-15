import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  final List<Vehicle> vehicles;
  final Vehicle selectedVehicle;

  const ProfileScreen({
    super.key,
    required this.vehicles,
    required this.selectedVehicle,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final authService = AuthService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          'Einstellungen',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFFF8F9FB),
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
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8E8E93),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8ECF0)),
              ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: Icons.palette_outlined,
                    title: 'Design',
                    subtitle: 'Hell, Dunkel oder System',
                    trailing: 'System',
                    onTap: () {
                      // TODO: Design picker
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildSettingsTile(
                    icon: Icons.straighten,
                    title: 'Einheiten',
                    subtitle: null,
                    trailing: 'Metrisch (km)',
                    onTap: () {
                      // TODO: Units picker
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildSettingsTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Währung',
                    subtitle: null,
                    trailing: 'Euro (€)',
                    onTap: () {
                      // TODO: Currency picker
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Fahrzeug-Einstellungen
            _buildSectionHeader('FAHRZEUG-EINSTELLUNGEN'),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8ECF0)),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.directions_car,
                          color: Color(0xFF1A5276), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        '${selectedVehicle.brand} ${selectedVehicle.model}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // TODO: Edit vehicle
                      },
                      icon: const Icon(Icons.edit_outlined,
                          color: Color(0xFF8E8E93), size: 22),
                    ),
                    IconButton(
                      onPressed: () {
                        // TODO: Delete vehicle
                      },
                      icon: const Icon(Icons.delete_outline,
                          color: Color(0xFF8E8E93), size: 22),
                    ),
                  ],
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
                onTap: () => _showDeleteAccountDialog(context, authService),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1A5276).withValues(alpha: 0.7),
          letterSpacing: 0.5,
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
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF1A5276), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8E8E93),
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

  void _showDeleteAccountDialog(
      BuildContext context, AuthService authService) {
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
            onPressed: () {
              Navigator.pop(context);
              // TODO: Delete account + all data
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFC62828)),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
