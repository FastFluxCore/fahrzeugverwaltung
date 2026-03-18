import 'dart:convert';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

class ScanResult {
  final DateTime? date;
  final double? totalCost;
  final double? liters;
  final double? pricePerLiter;
  final String? station;
  final int? mileage;
  // Service fields
  final String? serviceType;
  final String? workshop;
  final String? description;
  final String? notes;
  // Other cost fields
  final String? category;

  ScanResult({
    this.date,
    this.totalCost,
    this.liters,
    this.pricePerLiter,
    this.station,
    this.mileage,
    this.serviceType,
    this.workshop,
    this.description,
    this.notes,
    this.category,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? s) {
      if (s == null || s.isEmpty) return null;
      try {
        return DateTime.parse(s);
      } catch (_) {
        return null;
      }
    }

    return ScanResult(
      date: parseDate(json['date'] as String?),
      totalCost: (json['totalCost'] as num?)?.toDouble(),
      liters: (json['liters'] as num?)?.toDouble(),
      pricePerLiter: (json['pricePerLiter'] as num?)?.toDouble(),
      station: json['station'] as String?,
      mileage: (json['mileage'] as num?)?.toInt(),
      serviceType: json['serviceType'] as String?,
      workshop: json['workshop'] as String?,
      description: json['description'] as String?,
      notes: json['notes'] as String?,
      category: json['category'] as String?,
    );
  }
}

enum ReceiptType { fuel, service, otherCost }

class ReceiptScannerService {
  final String _apiKey;
  late final GenerativeModel _model;

  ReceiptScannerService(this._apiKey) {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );
  }

  Future<ScanResult> scan(Uint8List imageBytes, ReceiptType type) async {
    final prompt = _buildPrompt(type);
    final mimeType = _detectMimeType(imageBytes);

    final content = Content.multi([
      TextPart(prompt),
      DataPart(mimeType, imageBytes),
    ]);

    final response = await _model.generateContent([content]);
    final text = response.text;
    if (text == null || text.isEmpty) {
      throw Exception('Keine Daten erkannt');
    }

    final json = _extractJson(text);
    return ScanResult.fromJson(json);
  }

  String _buildPrompt(ReceiptType type) {
    const base = 'Analysiere diesen Beleg/Rechnung und extrahiere die Daten als JSON. '
        'Antworte NUR mit dem JSON-Objekt, kein anderer Text. '
        'Verwende null für Felder die nicht erkennbar sind. '
        'Datumsformat: YYYY-MM-DD. Zahlen als Dezimalzahlen mit Punkt.';

    switch (type) {
      case ReceiptType.fuel:
        return '$base\n\nFelder: {"date": "YYYY-MM-DD", "totalCost": number, '
            '"liters": number, "pricePerLiter": number, "station": "string", "mileage": number}';
      case ReceiptType.service:
        return '$base\n\nFelder: {"date": "YYYY-MM-DD", "totalCost": number, '
            '"serviceType": "string (eine von: Ölwechsel, Inspektion, Bremsen, Reifen, TÜV/HU, Zahnriemen, Batterie, Klimaanlage, Auspuff, Sonstiges)", '
            '"workshop": "string", "mileage": number, "notes": "string (kurze Zusammenfassung der Arbeiten)"}';
      case ReceiptType.otherCost:
        return '$base\n\nFelder: {"date": "YYYY-MM-DD", "totalCost": number, '
            '"description": "string", "category": "string (eine von: Versicherung, Steuer, Parkgebühren, Maut, Waschen, Zubehör, Finanzierung, Sonstiges)", '
            '"notes": "string (kurze Zusammenfassung)"}';
    }
  }

  String _detectMimeType(Uint8List bytes) {
    if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 4 && bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) {
      return 'image/webp';
    }
    // PDF
    if (bytes.length >= 4 && bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46) {
      return 'application/pdf';
    }
    return 'image/jpeg';
  }

  Map<String, dynamic> _extractJson(String text) {
    // Try to find JSON in the response (may be wrapped in ```json blocks)
    var cleaned = text.trim();

    // Remove markdown code blocks
    final jsonBlockRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final match = jsonBlockRegex.firstMatch(cleaned);
    if (match != null) {
      cleaned = match.group(1)!.trim();
    }

    // Find first { to last }
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      throw Exception('Keine Daten im Beleg erkannt');
    }

    cleaned = cleaned.substring(start, end + 1);
    return jsonDecode(cleaned) as Map<String, dynamic>;
  }
}
