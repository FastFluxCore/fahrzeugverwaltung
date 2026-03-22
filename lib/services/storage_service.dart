import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  /// Uploads a file and returns the download URL.
  Future<String> uploadDocument({
    required String vehicleId,
    required String entryType,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'users/$_uid/vehicles/$vehicleId/$entryType/${timestamp}_$fileName';
    final ref = _storage.ref(path);
    await ref.putData(bytes);
    return await ref.getDownloadURL();
  }

  /// Deletes a file by its download URL.
  Future<void> deleteDocument(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // File may already be deleted
    }
  }
}
