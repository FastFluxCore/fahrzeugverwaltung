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
    // Delete subcollections
    final subcollections = ['services', 'fuelLogs', 'otherCosts', 'reminders', 'trips'];
    for (final sub in subcollections) {
      final docs = await _vehiclesRef.doc(vehicleId).collection(sub).get();
      for (final doc in docs.docs) {
        await doc.reference.delete();
      }
    }
    await _vehiclesRef.doc(vehicleId).delete();
  }

  Future<void> updateMileage(String vehicleId, int mileage) async {
    await _vehiclesRef.doc(vehicleId).update({'mileage': mileage});
  }

  /// Updates reminder fields based on a completed service type.
  Future<void> updateRemindersAfterService({
    required String vehicleId,
    required String serviceType,
    required DateTime serviceDate,
    required int? mileage,
  }) async {
    final updates = <String, dynamic>{};

    if (serviceType == 'TÜV/HU') {
      updates['nextTuev'] = DateTime(serviceDate.year + 2, serviceDate.month, serviceDate.day).toIso8601String();
    }

    if (serviceType == 'Inspektion') {
      updates['nextInspection'] = DateTime(serviceDate.year + 1, serviceDate.month, serviceDate.day).toIso8601String();
    }

    if (serviceType == 'Ölwechsel' && mileage != null) {
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
    required String deletedServiceType,
  }) async {
    // Fetch all services and filter in Dart (avoids needing composite Firestore indexes)
    final snap = await _vehiclesRef.doc(vehicleId).collection('services').get();
    final vehicleDoc = await _vehiclesRef.doc(vehicleId).get();
    final vehicleData = vehicleDoc.data() ?? {};
    final updates = <String, dynamic>{};

    final matchingEntries = snap.docs
        .where((doc) => doc.data()['serviceType'] == deletedServiceType)
        .toList();

    // Sort by date descending
    matchingEntries.sort((a, b) {
      final dateA = a.data()['date'] as String? ?? '';
      final dateB = b.data()['date'] as String? ?? '';
      return dateB.compareTo(dateA);
    });

    if (deletedServiceType == 'TÜV/HU') {
      if (matchingEntries.isNotEmpty) {
        final date = DateTime.parse(matchingEntries.first.data()['date']);
        updates['nextTuev'] = DateTime(date.year + 2, date.month, date.day).toIso8601String();
      } else if (vehicleData['originalNextTuev'] != null) {
        updates['nextTuev'] = vehicleData['originalNextTuev'];
      } else {
        updates['nextTuev'] = FieldValue.delete();
      }
    }

    if (deletedServiceType == 'Inspektion') {
      if (matchingEntries.isNotEmpty) {
        final date = DateTime.parse(matchingEntries.first.data()['date']);
        updates['nextInspection'] = DateTime(date.year + 1, date.month, date.day).toIso8601String();
      } else if (vehicleData['originalNextInspection'] != null) {
        updates['nextInspection'] = vehicleData['originalNextInspection'];
      } else {
        updates['nextInspection'] = FieldValue.delete();
      }
    }

    if (deletedServiceType == 'Ölwechsel') {
      if (matchingEntries.isNotEmpty) {
        final mileage = matchingEntries.first.data()['mileage'];
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
