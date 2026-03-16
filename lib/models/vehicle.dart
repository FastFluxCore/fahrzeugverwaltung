class Vehicle {
  final String id;
  final String brand;
  final String model;
  final int year;
  final int horsepower;
  final String transmission;
  final String fuelType;
  final String licensePlate;
  final int mileage;
  final String? imageUrl;

  // Reminders (current / computed)
  final DateTime? nextTuev;
  final DateTime? nextInspection;
  final int? oilChangeInterval;
  final int? lastOilChangeMileage;

  // Reminders (original values set by user)
  final DateTime? originalNextTuev;
  final DateTime? originalNextInspection;
  final int? originalLastOilChangeMileage;

  Vehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.horsepower,
    required this.transmission,
    required this.fuelType,
    required this.licensePlate,
    required this.mileage,
    this.imageUrl,
    this.nextTuev,
    this.nextInspection,
    this.oilChangeInterval,
    this.lastOilChangeMileage,
    this.originalNextTuev,
    this.originalNextInspection,
    this.originalLastOilChangeMileage,
  });

  String get displayName => '$brand $model - $licensePlate';

  factory Vehicle.fromMap(String id, Map<String, dynamic> map) {
    return Vehicle(
      id: id,
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      year: map['year'] ?? 0,
      horsepower: map['horsepower'] ?? 0,
      transmission: map['transmission'] ?? '',
      fuelType: map['fuelType'] ?? '',
      licensePlate: map['licensePlate'] ?? '',
      mileage: map['mileage'] ?? 0,
      imageUrl: map['imageUrl'],
      nextTuev: map['nextTuev'] != null ? DateTime.parse(map['nextTuev']) : null,
      nextInspection: map['nextInspection'] != null ? DateTime.parse(map['nextInspection']) : null,
      oilChangeInterval: map['oilChangeInterval'],
      lastOilChangeMileage: map['lastOilChangeMileage'],
      originalNextTuev: map['originalNextTuev'] != null ? DateTime.parse(map['originalNextTuev']) : null,
      originalNextInspection: map['originalNextInspection'] != null ? DateTime.parse(map['originalNextInspection']) : null,
      originalLastOilChangeMileage: map['originalLastOilChangeMileage'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'brand': brand,
      'model': model,
      'year': year,
      'horsepower': horsepower,
      'transmission': transmission,
      'fuelType': fuelType,
      'licensePlate': licensePlate,
      'mileage': mileage,
      'imageUrl': imageUrl,
    };
    if (nextTuev != null) map['nextTuev'] = nextTuev!.toIso8601String();
    if (nextInspection != null) map['nextInspection'] = nextInspection!.toIso8601String();
    if (oilChangeInterval != null) map['oilChangeInterval'] = oilChangeInterval;
    if (lastOilChangeMileage != null) map['lastOilChangeMileage'] = lastOilChangeMileage;
    if (originalNextTuev != null) map['originalNextTuev'] = originalNextTuev!.toIso8601String();
    if (originalNextInspection != null) map['originalNextInspection'] = originalNextInspection!.toIso8601String();
    if (originalLastOilChangeMileage != null) map['originalLastOilChangeMileage'] = originalLastOilChangeMileage;
    return map;
  }
}
