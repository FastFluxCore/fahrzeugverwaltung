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
}
