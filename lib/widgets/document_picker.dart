import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class DocumentFile {
  final String name;
  final String? url; // null = not yet uploaded
  final Uint8List? bytes; // null = already uploaded (existing)
  bool uploading;

  DocumentFile({required this.name, this.url, this.bytes, this.uploading = false});
}

class DocumentPicker extends StatefulWidget {
  final List<String> existingUrls;
  final ValueChanged<List<DocumentFile>> onChanged;

  const DocumentPicker({
    super.key,
    required this.existingUrls,
    required this.onChanged,
  });

  @override
  State<DocumentPicker> createState() => DocumentPickerState();
}

class DocumentPickerState extends State<DocumentPicker> {
  final List<DocumentFile> _documents = [];
  final List<String> _removedUrls = [];

  List<String> get removedUrls => _removedUrls;

  @override
  void initState() {
    super.initState();
    for (final url in widget.existingUrls) {
      final name = _fileNameFromUrl(url);
      _documents.add(DocumentFile(name: name, url: url));
    }
  }

  String _fileNameFromUrl(String url) {
    final uri = Uri.parse(url);
    final path = Uri.decodeFull(uri.path);
    final name = path.split('/').last;
    // Remove timestamp prefix
    final idx = name.indexOf('_');
    return idx > 0 ? name.substring(idx + 1) : name;
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: true,
      withData: true,
    );

    if (result == null) return;

    setState(() {
      for (final file in result.files) {
        if (file.bytes != null) {
          _documents.add(DocumentFile(
            name: file.name,
            bytes: file.bytes,
          ));
        }
      }
    });
    widget.onChanged(_documents);
  }

  void _removeDocument(int index) {
    setState(() {
      final doc = _documents.removeAt(index);
      if (doc.url != null) {
        _removedUrls.add(doc.url!);
      }
    });
    widget.onChanged(_documents);
  }

  /// Uploads all new documents and returns the final list of URLs.
  Future<List<String>> uploadAll({
    required String vehicleId,
    required String entryType,
    required StorageService storageService,
  }) async {
    final urls = <String>[];

    for (final doc in _documents) {
      if (doc.url != null) {
        // Already uploaded
        urls.add(doc.url!);
      } else if (doc.bytes != null) {
        // New file — upload
        final url = await storageService.uploadDocument(
          vehicleId: vehicleId,
          entryType: entryType,
          fileName: doc.name,
          bytes: doc.bytes!,
        );
        urls.add(url);
      }
    }

    // Delete removed files
    for (final url in _removedUrls) {
      await storageService.deleteDocument(url);
    }

    return urls;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _pickFiles,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8ECF0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A5276).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.attach_file,
                      color: Color(0xFF1A5276), size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dokument hinzufügen',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        'PDF, JPG, PNG',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.add, color: Color(0xFF1A5276), size: 22),
              ],
            ),
          ),
        ),
        if (_documents.isNotEmpty) ...[
          const SizedBox(height: 8),
          ..._documents.asMap().entries.map((e) {
            final index = e.key;
            final doc = e.value;
            final isImage = doc.name.toLowerCase().endsWith('.jpg') ||
                doc.name.toLowerCase().endsWith('.jpeg') ||
                doc.name.toLowerCase().endsWith('.png') ||
                doc.name.toLowerCase().endsWith('.webp');

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      isImage ? Icons.image_outlined : Icons.description_outlined,
                      color: const Color(0xFF1A5276),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        doc.name,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (doc.url == null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A5276).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Neu',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF1A5276)),
                        ),
                      ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _removeDocument(index),
                      child: const Icon(Icons.close,
                          size: 18, color: Color(0xFF8E8E93)),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
