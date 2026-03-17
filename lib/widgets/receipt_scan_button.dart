import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/receipt_scanner_service.dart';
import '../theme.dart';

class ReceiptScanButton extends StatefulWidget {
  final ReceiptType receiptType;
  final String apiKey;
  final ValueChanged<ScanResult> onScanned;
  final ValueChanged<Uint8List>? onImagePicked;

  const ReceiptScanButton({
    super.key,
    required this.receiptType,
    required this.apiKey,
    required this.onScanned,
    this.onImagePicked,
  });

  @override
  State<ReceiptScanButton> createState() => _ReceiptScanButtonState();
}

class _ReceiptScanButtonState extends State<ReceiptScanButton> {
  bool _isScanning = false;

  Future<void> _scan() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) return;

    final bytes = result.files.single.bytes!;
    widget.onImagePicked?.call(bytes);

    setState(() => _isScanning = true);
    try {
      final scanner = ReceiptScannerService(widget.apiKey);
      final scanResult = await scanner.scan(bytes, widget.receiptType);
      widget.onScanned(scanResult);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Beleg erkannt — Felder wurden ausgefüllt'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Scannen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _isScanning ? null : _scan,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.brand.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.brand.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.brand.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isScanning
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.document_scanner_outlined,
                      color: context.brand, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isScanning ? 'Beleg wird analysiert...' : 'Beleg scannen',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.brand,
                    ),
                  ),
                  Text(
                    'Foto oder PDF hochladen — Felder werden automatisch ausgefüllt',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (!_isScanning)
              Icon(Icons.chevron_right, color: context.brand, size: 22),
          ],
        ),
      ),
    );
  }
}
