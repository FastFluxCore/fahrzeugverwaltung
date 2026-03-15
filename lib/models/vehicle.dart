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
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
  }
}
