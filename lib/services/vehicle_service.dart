import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/vehicle.dart';

class VehicleService {
  final _firestore = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _vehiclesRef =>
      _firestore.collection('users').doc(_uid).collection('vehicles');

  Stream<List<Vehicle>> getVehicles() {
    return _vehiclesRef.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Vehicle.fromMap(doc.id, doc.data())).toList());
  }

  Future<Vehicle> addVehicle(Vehicle vehicle) async {
    final docRef = await _vehiclesRef.add(vehicle.toMap());
    return Vehicle.fromMap(docRef.id, vehicle.toMap());
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    await _vehiclesRef.doc(vehicle.id).update(vehicle.toMap());
  }

  Future<void> deleteVehicle(String vehicleId) async {
    final subcollections = ['services', 'fuelLogs', 'otherCosts', 'reminders', 'trips'];
    // Fetch all subcollections in parallel
    final snapshots = await Future.wait(
      subcollections.map((sub) => _vehiclesRef.doc(vehicleId).collection(sub).get()),
    );
    // Delete all documents in parallel
    final deletions = <Future>[];
    for (final snapshot in snapshots) {
      for (final doc in snapshot.docs) {
        deletions.add(doc.reference.delete());
      }
    }
    await Future.wait(deletions);
    await _vehiclesRef.doc(vehicleId).delete();
  }

  Future<void> updateMileage(String vehicleId, int mileage) async {
    await _vehiclesRef.doc(vehicleId).update({'mileage': mileage});
  }

  /// Updates reminder fields based on completed service toggles.
  Future<void> updateRemindersAfterService({
    required String vehicleId,
    required bool includesTuev,
    required bool includesInspection,
    required bool includesOilChange,
    required DateTime serviceDate,
    required int? mileage,
  }) async {
    final updates = <String, dynamic>{};

    if (includesTuev) {
      updates['nextTuev'] = DateTime(serviceDate.year + 2, serviceDate.month, serviceDate.day).toIso8601String();
    }

    if (includesInspection) {
      updates['nextInspection'] = DateTime(serviceDate.year + 1, serviceDate.month, serviceDate.day).toIso8601String();
    }

    if (includesOilChange && mileage != null) {
      updates['lastOilChangeMileage'] = mileage;
    }

    if (updates.isNotEmpty) {
      await _vehiclesRef.doc(vehicleId).update(updates);
    }
  }

  /// Recalculates reminder fields from remaining service entries.
  /// Falls back to original values set by user if no entries remain.
  Future<void> recalculateReminders({
    required String vehicleId,
    required bool hadOilChange,
    required bool hadInspection,
    required bool hadTuev,
  }) async {
    final snap = await _vehiclesRef.doc(vehicleId).collection('services').get();
    final vehicleDoc = await _vehiclesRef.doc(vehicleId).get();
    final vehicleData = vehicleDoc.data() ?? {};
    final updates = <String, dynamic>{};

    // Helper: check if a doc matches a toggle (supports both new booleans and legacy serviceType)
    bool docMatches(Map<String, dynamic> data, String boolField, String legacyType) {
      if (data[boolField] == true) return true;
      return data['serviceType'] == legacyType;
    }

    List<QueryDocumentSnapshot<Map<String, dynamic>>> sortedByDate(
        bool Function(Map<String, dynamic>) filter) {
      final matched = snap.docs.where((doc) => filter(doc.data())).toList();
      matched.sort((a, b) {
        final dateA = a.data()['date'] as String? ?? '';
        final dateB = b.data()['date'] as String? ?? '';
        return dateB.compareTo(dateA);
      });
      return matched;
    }

    if (hadTuev) {
      final entries = sortedByDate((d) => docMatches(d, 'includesTuev', 'TÜV/HU'));
      if (entries.isNotEmpty) {
        final date = DateTime.parse(entries.first.data()['date']);
        updates['nextTuev'] = DateTime(date.year + 2, date.month, date.day).toIso8601String();
      } else if (vehicleData['originalNextTuev'] != null) {
        updates['nextTuev'] = vehicleData['originalNextTuev'];
      } else {
        updates['nextTuev'] = FieldValue.delete();
      }
    }

    if (hadInspection) {
      final entries = sortedByDate((d) => docMatches(d, 'includesInspection', 'Inspektion'));
      if (entries.isNotEmpty) {
        final date = DateTime.parse(entries.first.data()['date']);
        updates['nextInspection'] = DateTime(date.year + 1, date.month, date.day).toIso8601String();
      } else if (vehicleData['originalNextInspection'] != null) {
        updates['nextInspection'] = vehicleData['originalNextInspection'];
      } else {
        updates['nextInspection'] = FieldValue.delete();
      }
    }

    if (hadOilChange) {
      final entries = sortedByDate((d) => docMatches(d, 'includesOilChange', 'Ölwechsel'));
      if (entries.isNotEmpty) {
        final mileage = entries.first.data()['mileage'];
        if (mileage != null) {
          updates['lastOilChangeMileage'] = mileage;
        }
      } else if (vehicleData['originalLastOilChangeMileage'] != null) {
        updates['lastOilChangeMileage'] = vehicleData['originalLastOilChangeMileage'];
      } else {
        updates['lastOilChangeMileage'] = FieldValue.delete();
      }
    }

    if (updates.isNotEmpty) {
      await _vehiclesRef.doc(vehicleId).update(updates);
    }
  }
}
