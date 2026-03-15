import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/entry.dart';

class EntryService {
  final _firestore = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> _vehicleRef(String vehicleId) =>
      _firestore.collection('users').doc(_uid).collection('vehicles').doc(vehicleId);

  // Fuel Logs
  Stream<List<Entry>> getFuelLogs(String vehicleId) {
    return _vehicleRef(vehicleId)
        .collection('fuelLogs')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Entry.fromFuelLog(doc.id, doc.data()))
            .toList());
  }

  Future<void> addFuelLog(String vehicleId, Entry entry) async {
    await _vehicleRef(vehicleId).collection('fuelLogs').add(entry.toMap());
  }

  Future<void> updateFuelLog(String vehicleId, Entry entry) async {
    await _vehicleRef(vehicleId).collection('fuelLogs').doc(entry.id).update(entry.toMap());
  }

  Future<void> deleteFuelLog(String vehicleId, String entryId) async {
    await _vehicleRef(vehicleId).collection('fuelLogs').doc(entryId).delete();
  }

  // Services
  Stream<List<Entry>> getServices(String vehicleId) {
    return _vehicleRef(vehicleId)
        .collection('services')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Entry.fromService(doc.id, doc.data()))
            .toList());
  }

  Future<void> addService(String vehicleId, Entry entry) async {
    await _vehicleRef(vehicleId).collection('services').add(entry.toMap());
  }

  Future<void> updateService(String vehicleId, Entry entry) async {
    await _vehicleRef(vehicleId).collection('services').doc(entry.id).update(entry.toMap());
  }

  Future<void> deleteService(String vehicleId, String entryId) async {
    await _vehicleRef(vehicleId).collection('services').doc(entryId).delete();
  }

  // Other Costs
  Stream<List<Entry>> getOtherCosts(String vehicleId) {
    return _vehicleRef(vehicleId)
        .collection('otherCosts')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Entry.fromOtherCost(doc.id, doc.data()))
            .toList());
  }

  Future<void> addOtherCost(String vehicleId, Entry entry) async {
    await _vehicleRef(vehicleId).collection('otherCosts').add(entry.toMap());
  }

  Future<void> updateOtherCost(String vehicleId, Entry entry) async {
    await _vehicleRef(vehicleId).collection('otherCosts').doc(entry.id).update(entry.toMap());
  }

  Future<void> deleteOtherCost(String vehicleId, String entryId) async {
    await _vehicleRef(vehicleId).collection('otherCosts').doc(entryId).delete();
  }

  // All entries combined
  Stream<List<Entry>> getAllEntries(String vehicleId) {
    final fuelStream = getFuelLogs(vehicleId);
    final serviceStream = getServices(vehicleId);
    final otherCostStream = getOtherCosts(vehicleId);

    return fuelStream.asyncExpand((fuelLogs) {
      return serviceStream.asyncExpand((services) {
        return otherCostStream.map((otherCosts) {
          final all = [...fuelLogs, ...services, ...otherCosts];
          all.sort((a, b) => b.date.compareTo(a.date));
          return all;
        });
      });
    });
  }
}
