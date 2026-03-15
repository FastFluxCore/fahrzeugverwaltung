import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import 'cost_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'logbook_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  // TODO: Replace with Firestore data
  final List<Vehicle> _vehicles = [
    Vehicle(
      id: '1',
      brand: 'Audi',
      model: 'A4',
      year: 2026,
      horsepower: 150,
      transmission: 'Automatik',
      fuelType: 'Benzin',
      licensePlate: 'B-AU 2026',
      mileage: 12450,
    ),
  ];

  late Vehicle _selectedVehicle;

  @override
  void initState() {
    super.initState();
    _selectedVehicle = _vehicles.first;
  }

  void _onVehicleChanged(Vehicle? vehicle) {
    if (vehicle != null) setState(() => _selectedVehicle = vehicle);
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      _showAddEntrySheet();
      return;
    }
    setState(() => _currentIndex = index);
  }

  void _showAddEntrySheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD0D0D0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Neuer Eintrag',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildAddOption(
              icon: Icons.local_gas_station,
              label: 'Tanken',
              color: const Color(0xFF1A5276),
              onTap: () {
                Navigator.pop(context);
                // TODO: Open fuel form
              },
            ),
            const SizedBox(height: 12),
            _buildAddOption(
              icon: Icons.build,
              label: 'Service',
              color: const Color(0xFF2E7D32),
              onTap: () {
                Navigator.pop(context);
                // TODO: Open service form
              },
            ),
            const SizedBox(height: 12),
            _buildAddOption(
              icon: Icons.euro,
              label: 'Sonstige Kosten',
              color: const Color(0xFFC62828),
              onTap: () {
                Navigator.pop(context);
                // TODO: Open other cost form
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        vehicles: _vehicles,
        selectedVehicle: _selectedVehicle,
        onVehicleChanged: _onVehicleChanged,
      ),
      CostScreen(
        vehicles: _vehicles,
        selectedVehicle: _selectedVehicle,
        onVehicleChanged: _onVehicleChanged,
      ),
      const SizedBox.shrink(), // Placeholder for FAB
      const _PlaceholderScreen(title: 'Logbuch'),
      ProfileScreen(
        vehicles: _vehicles,
        selectedVehicle: _selectedVehicle,
      ),
      LogbookScreen(
        vehicles: _vehicles,
        selectedVehicle: _selectedVehicle,
        onVehicleChanged: _onVehicleChanged,
      ),
      const _PlaceholderScreen(title: 'Profil'),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
              _buildNavItem(1, Icons.euro_outlined, Icons.euro, 'Kosten'),
              const SizedBox(width: 48),
              _buildNavItem(
                  3, Icons.menu_book_outlined, Icons.menu_book, 'Logbuch'),
              _buildNavItem(
                  4, Icons.person_outline, Icons.person, 'Profil'),
            ],
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        width: 56,
        height: 56,
        child: FloatingActionButton(
          onPressed: _showAddEntrySheet,
          backgroundColor: const Color(0xFF1A5276),
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem(
      int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    return InkWell(
      onTap: () => _onTabTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            color: isActive ? const Color(0xFF1A5276) : const Color(0xFF8E8E93),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color:
                  isActive ? const Color(0xFF1A5276) : const Color(0xFF8E8E93),
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        backgroundColor: const Color(0xFFF8F9FB),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: Text(
          '$title kommt bald...',
          style: const TextStyle(fontSize: 16, color: Color(0xFF8E8E93)),
        ),
      ),
    );
  }
}
