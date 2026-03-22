enum EntryType { fuel, service, otherCost }

class Entry {
  final String id;
  final EntryType type;
  final DateTime date;
  final double cost;
  final int? mileage;
  final String description;
  final String? subtitle;

  // Fuel-specific
  final double? liters;
  final double? pricePerLiter;
  final bool? fullTank;
  final String? station;

  // Service-specific
  final String? serviceType; // legacy, kept for reading old data
  final bool includesOilChange;
  final bool includesInspection;
  final bool includesTuev;
  final String? workshop;
  final String? notes;

  // OtherCost-specific
  final String? category;

  // Documents
  final List<String> documentUrls;

  Entry({
    required this.id,
    required this.type,
    required this.date,
    required this.cost,
    this.mileage,
    required this.description,
    this.subtitle,
    this.liters,
    this.pricePerLiter,
    this.fullTank,
    this.station,
    this.serviceType,
    this.includesOilChange = false,
    this.includesInspection = false,
    this.includesTuev = false,
    this.workshop,
    this.notes,
    this.category,
    this.documentUrls = const [],
  });

  factory Entry.fromFuelLog(String id, Map<String, dynamic> map) {
    return Entry(
      id: id,
      type: EntryType.fuel,
      date: DateTime.parse(map['date']),
      cost: (map['totalCost'] ?? 0).toDouble(),
      mileage: map['mileage'],
      description: 'Tanken',
      subtitle: map['station'],
      liters: (map['liters'] ?? 0).toDouble(),
      pricePerLiter: (map['pricePerLiter'] ?? 0).toDouble(),
      fullTank: map['fullTank'],
      station: map['station'],
      documentUrls: List<String>.from(map['documentUrls'] ?? []),
    );
  }

  factory Entry.fromService(String id, Map<String, dynamic> map) {
    final legacy = map['serviceType'] as String?;
    return Entry(
      id: id,
      type: EntryType.service,
      date: DateTime.parse(map['date']),
      cost: (map['cost'] ?? 0).toDouble(),
      mileage: map['mileage'],
      description: map['description'] ?? legacy ?? 'Service',
      subtitle: map['workshop'],
      serviceType: legacy,
      includesOilChange: map['includesOilChange'] ?? (legacy == 'Ölwechsel'),
      includesInspection: map['includesInspection'] ?? (legacy == 'Inspektion'),
      includesTuev: map['includesTuev'] ?? (legacy == 'TÜV/HU'),
      workshop: map['workshop'],
      notes: map['notes'],
      documentUrls: List<String>.from(map['documentUrls'] ?? []),
    );
  }

  factory Entry.fromOtherCost(String id, Map<String, dynamic> map) {
    return Entry(
      id: id,
      type: EntryType.otherCost,
      date: DateTime.parse(map['date']),
      cost: (map['cost'] ?? 0).toDouble(),
      description: map['description'] ?? 'Sonstiges',
      subtitle: map['category'],
      category: map['category'],
      notes: map['notes'],
      documentUrls: List<String>.from(map['documentUrls'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'date': date.toIso8601String(),
      'cost': cost,
      'description': description,
    };
    if (mileage != null) map['mileage'] = mileage;
    if (type == EntryType.fuel) {
      map['liters'] = liters;
      map['pricePerLiter'] = pricePerLiter;
      map['fullTank'] = fullTank;
      map['station'] = station;
      map['totalCost'] = cost;
    }
    if (type == EntryType.service) {
      map['includesOilChange'] = includesOilChange;
      map['includesInspection'] = includesInspection;
      map['includesTuev'] = includesTuev;
      map['workshop'] = workshop;
      map['notes'] = notes;
    }
    if (type == EntryType.otherCost) {
      map['category'] = category;
      map['notes'] = notes;
    }
    if (documentUrls.isNotEmpty) map['documentUrls'] = documentUrls;
    return map;
  }
}
