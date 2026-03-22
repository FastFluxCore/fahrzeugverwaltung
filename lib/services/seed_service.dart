import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SeedService {
  final _firestore = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> _vehicleRef(String vehicleId) =>
      _firestore.collection('users').doc(_uid).collection('vehicles').doc(vehicleId);

  Future<void> seedAll() async {
    // Create two vehicles
    final v1Ref = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('vehicles')
        .add({
      'brand': 'BMW',
      'model': '3er',
      'year': 2019,
      'horsepower': 190,
      'transmission': 'Automatik',
      'fuelType': 'Diesel',
      'licensePlate': 'M-BW 1234',
      'mileage': 87500,
      'registrationDate': '2024-06-01T00:00:00.000',
      'nextTuev': '2026-09-15T00:00:00.000',
      'nextInspection': '2026-06-01T00:00:00.000',
      'oilChangeInterval': 15000,
      'lastOilChangeMileage': 82000,
      'originalNextTuev': '2026-09-15T00:00:00.000',
      'originalNextInspection': '2026-06-01T00:00:00.000',
      'originalLastOilChangeMileage': 82000,
    });

    final v2Ref = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('vehicles')
        .add({
      'brand': 'Volkswagen',
      'model': 'Golf',
      'year': 2021,
      'horsepower': 150,
      'transmission': 'Manuell',
      'fuelType': 'Benzin',
      'licensePlate': 'HH-VW 5678',
      'mileage': 42000,
      'registrationDate': '2025-01-15T00:00:00.000',
      'nextTuev': '2027-03-20T00:00:00.000',
      'nextInspection': '2026-11-10T00:00:00.000',
      'oilChangeInterval': 15000,
      'lastOilChangeMileage': 38000,
      'originalNextTuev': '2027-03-20T00:00:00.000',
      'originalNextInspection': '2026-11-10T00:00:00.000',
      'originalLastOilChangeMileage': 38000,
    });

    await Future.wait([
      _seedCollection(v1Ref.id, 'fuelLogs', _bmwFuelLogs()),
      _seedCollection(v1Ref.id, 'services', _bmwServices()),
      _seedCollection(v1Ref.id, 'otherCosts', _bmwOtherCosts()),
      _seedCollection(v2Ref.id, 'fuelLogs', _vwFuelLogs()),
      _seedCollection(v2Ref.id, 'services', _vwServices()),
      _seedCollection(v2Ref.id, 'otherCosts', _vwOtherCosts()),
    ]);
  }

  Future<void> _seedCollection(String vehicleId, String collection, List<Map<String, dynamic>> items) async {
    final col = _vehicleRef(vehicleId).collection(collection);
    await Future.wait(items.map((item) => col.add(item)));
  }

  // ── BMW 320d Fuel Logs ──
  List<Map<String, dynamic>> _bmwFuelLogs() => [
    {'date': '2025-04-10T00:00:00.000', 'totalCost': 72.50, 'liters': 42.5, 'pricePerLiter': 1.706, 'fullTank': true, 'station': 'Aral', 'mileage': 75200},
    {'date': '2025-05-02T00:00:00.000', 'totalCost': 68.30, 'liters': 40.8, 'pricePerLiter': 1.674, 'fullTank': true, 'station': 'Shell', 'mileage': 76100},
    {'date': '2025-06-15T00:00:00.000', 'totalCost': 75.10, 'liters': 43.2, 'pricePerLiter': 1.738, 'fullTank': true, 'station': 'Aral', 'mileage': 77300},
    {'date': '2025-07-20T00:00:00.000', 'totalCost': 70.80, 'liters': 41.0, 'pricePerLiter': 1.727, 'fullTank': true, 'station': 'Total', 'mileage': 78500},
    {'date': '2025-08-25T00:00:00.000', 'totalCost': 73.60, 'liters': 42.8, 'pricePerLiter': 1.719, 'fullTank': true, 'station': 'Aral', 'mileage': 79800},
    {'date': '2025-09-30T00:00:00.000', 'totalCost': 69.90, 'liters': 40.5, 'pricePerLiter': 1.726, 'fullTank': true, 'station': 'Shell', 'mileage': 80900},
    {'date': '2025-11-05T00:00:00.000', 'totalCost': 71.20, 'liters': 41.8, 'pricePerLiter': 1.703, 'fullTank': true, 'station': 'Aral', 'mileage': 82100},
    {'date': '2025-12-12T00:00:00.000', 'totalCost': 74.50, 'liters': 43.0, 'pricePerLiter': 1.733, 'fullTank': true, 'station': 'Total', 'mileage': 83400},
    {'date': '2026-01-18T00:00:00.000', 'totalCost': 76.20, 'liters': 43.5, 'pricePerLiter': 1.751, 'fullTank': true, 'station': 'Aral', 'mileage': 84600},
    {'date': '2026-02-22T00:00:00.000', 'totalCost': 72.80, 'liters': 42.0, 'pricePerLiter': 1.733, 'fullTank': true, 'station': 'Shell', 'mileage': 85900},
    {'date': '2026-03-15T00:00:00.000', 'totalCost': 77.40, 'liters': 44.1, 'pricePerLiter': 1.755, 'fullTank': true, 'station': 'Aral', 'mileage': 87500},
  ];

  // ── VW Golf 8 Fuel Logs ──
  List<Map<String, dynamic>> _vwFuelLogs() => [
    {'date': '2025-05-08T00:00:00.000', 'totalCost': 62.40, 'liters': 38.0, 'pricePerLiter': 1.642, 'fullTank': true, 'station': 'Jet', 'mileage': 35500},
    {'date': '2025-06-20T00:00:00.000', 'totalCost': 65.80, 'liters': 39.5, 'pricePerLiter': 1.665, 'fullTank': true, 'station': 'Aral', 'mileage': 36400},
    {'date': '2025-08-01T00:00:00.000', 'totalCost': 64.10, 'liters': 38.8, 'pricePerLiter': 1.652, 'fullTank': true, 'station': 'Shell', 'mileage': 37300},
    {'date': '2025-09-15T00:00:00.000', 'totalCost': 67.20, 'liters': 40.0, 'pricePerLiter': 1.680, 'fullTank': true, 'station': 'Jet', 'mileage': 38200},
    {'date': '2025-11-10T00:00:00.000', 'totalCost': 63.50, 'liters': 38.5, 'pricePerLiter': 1.649, 'fullTank': true, 'station': 'Total', 'mileage': 39400},
    {'date': '2025-12-28T00:00:00.000', 'totalCost': 66.90, 'liters': 39.8, 'pricePerLiter': 1.681, 'fullTank': true, 'station': 'Aral', 'mileage': 40200},
    {'date': '2026-02-05T00:00:00.000', 'totalCost': 68.30, 'liters': 40.5, 'pricePerLiter': 1.686, 'fullTank': true, 'station': 'Shell', 'mileage': 41100},
    {'date': '2026-03-10T00:00:00.000', 'totalCost': 65.60, 'liters': 39.2, 'pricePerLiter': 1.674, 'fullTank': true, 'station': 'Jet', 'mileage': 42000},
  ];

  // ── BMW 320d Services ──
  List<Map<String, dynamic>> _bmwServices() => [
    {
      'date': '2025-03-20T00:00:00.000',
      'cost': 850.00,
      'mileage': 75000,
      'description': 'Inspektion, Bremsflüssigkeit gewechselt, Luftfilter erneuert',
      'includesOilChange': true,
      'includesInspection': true,
      'includesTuev': false,
      'workshop': 'BMW Autohaus München',
    },
    {
      'date': '2025-09-10T00:00:00.000',
      'cost': 320.00,
      'mileage': 80500,
      'description': 'Bremsbeläge vorne erneuert, Bremsscheiben geprüft',
      'includesOilChange': false,
      'includesInspection': false,
      'includesTuev': false,
      'workshop': 'Bosch Car Service',
    },
    {
      'date': '2026-01-15T00:00:00.000',
      'cost': 480.00,
      'mileage': 84200,
      'description': 'Ölwechsel, Ölfilter, Pollenfilter, Wischwasser aufgefüllt',
      'includesOilChange': true,
      'includesInspection': false,
      'includesTuev': false,
      'workshop': 'BMW Autohaus München',
    },
  ];

  // ── VW Golf 8 Services ──
  List<Map<String, dynamic>> _vwServices() => [
    {
      'date': '2025-07-05T00:00:00.000',
      'cost': 620.00,
      'mileage': 37000,
      'description': 'Inspektion, Ölwechsel, Zündkerzen erneuert',
      'includesOilChange': true,
      'includesInspection': true,
      'includesTuev': false,
      'workshop': 'VW Autohaus Hamburg',
    },
    {
      'date': '2026-03-01T00:00:00.000',
      'cost': 180.00,
      'mileage': 41500,
      'description': 'HU/AU bestanden, keine Mängel',
      'includesOilChange': false,
      'includesInspection': false,
      'includesTuev': true,
      'workshop': 'TÜV NORD Hamburg',
    },
  ];

  // ── BMW 320d Other Costs ──
  List<Map<String, dynamic>> _bmwOtherCosts() => [
    {'date': '2025-01-15T00:00:00.000', 'cost': 890.00, 'description': 'Kfz-Versicherung', 'category': 'Versicherung'},
    {'date': '2025-03-01T00:00:00.000', 'cost': 148.00, 'description': 'Kfz-Steuer', 'category': 'Steuer'},
    {'date': '2025-04-20T00:00:00.000', 'cost': 45.00, 'description': 'Parkausweis Tiefgarage April', 'category': 'Parken'},
    {'date': '2025-11-02T00:00:00.000', 'cost': 680.00, 'description': 'Winterreifen Michelin Alpin 6', 'category': 'Reifen'},
    {'date': '2026-01-10T00:00:00.000', 'cost': 890.00, 'description': 'Kfz-Versicherung 2026', 'category': 'Versicherung'},
    {'date': '2026-02-15T00:00:00.000', 'cost': 29.90, 'description': 'Autowäsche Jahresabo', 'category': 'Pflege'},
  ];

  // ── VW Golf 8 Other Costs ──
  List<Map<String, dynamic>> _vwOtherCosts() => [
    {'date': '2025-02-01T00:00:00.000', 'cost': 540.00, 'description': 'Kfz-Versicherung', 'category': 'Versicherung'},
    {'date': '2025-03-15T00:00:00.000', 'cost': 92.00, 'description': 'Kfz-Steuer', 'category': 'Steuer'},
    {'date': '2025-10-20T00:00:00.000', 'cost': 520.00, 'description': 'Winterreifen Continental WinterContact', 'category': 'Reifen'},
    {'date': '2026-02-01T00:00:00.000', 'cost': 540.00, 'description': 'Kfz-Versicherung 2026', 'category': 'Versicherung'},
  ];
}
