import 'dart:async';

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

  // All entries combined — reacts to changes in any of the three collections
  Stream<List<Entry>> getAllEntries(String vehicleId) {
    final controller = StreamController<List<Entry>>();

    List<Entry> fuel = [];
    List<Entry> services = [];
    List<Entry> other = [];

    void emit() {
      final all = [...fuel, ...services, ...other];
      all.sort((a, b) => b.date.compareTo(a.date));
      controller.add(all);
    }

    final sub1 = getFuelLogs(vehicleId).listen((data) {
      fuel = data;
      emit();
    });
    final sub2 = getServices(vehicleId).listen((data) {
      services = data;
      emit();
    });
    final sub3 = getOtherCosts(vehicleId).listen((data) {
      other = data;
      emit();
    });

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
      sub3.cancel();
      controller.close();
    };

    return controller.stream;
  }
}
