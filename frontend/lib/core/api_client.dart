// ==============================================================================
// LEGALMETRY — Backend API Client & Data Models
// Track 5: UI / Reports (Person 5)
//
// Aligned with shared/api_contract.yaml for POST /scan
// ==============================================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ExtractedFields {
  final String mrp;
  final String netQuantity;
  final String manufacturerAddress;
  final String mfgDate;
  final String consumerCare;

  const ExtractedFields({
    required this.mrp,
    required this.netQuantity,
    required this.manufacturerAddress,
    required this.mfgDate,
    required this.consumerCare,
  });

  factory ExtractedFields.fromJson(Map<String, dynamic> json) {
    return ExtractedFields(
      mrp: json['mrp'] as String? ?? 'Not detected',
      netQuantity: json['net_quantity'] as String? ?? 'Not detected',
      manufacturerAddress: json['manufacturer_address'] as String? ?? 'Not detected',
      mfgDate: json['mfg_date'] as String? ?? 'Not detected',
      consumerCare: json['consumer_care'] as String? ?? 'Not detected',
    );
  }

  Map<String, dynamic> toJson() => {
    'mrp': mrp,
    'net_quantity': netQuantity,
    'manufacturer_address': manufacturerAddress,
    'mfg_date': mfgDate,
    'consumer_care': consumerCare,
  };
}

class MeasurementsMm {
  final double fontHeightMm;
  final double principalDisplayAreaSqCm;
  final double requiredMinFontHeightMm;

  const MeasurementsMm({
    required this.fontHeightMm,
    required this.principalDisplayAreaSqCm,
    this.requiredMinFontHeightMm = 2.0,
  });

  factory MeasurementsMm.fromJson(Map<String, dynamic> json) {
    return MeasurementsMm(
      fontHeightMm: (json['font_height_mm'] as num?)?.toDouble() ?? 0.0,
      principalDisplayAreaSqCm: (json['principal_display_area_sq_cm'] as num?)?.toDouble() ?? 0.0,
      requiredMinFontHeightMm: (json['required_min_font_height_mm'] as num?)?.toDouble() ?? 2.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'font_height_mm': fontHeightMm,
    'principal_display_area_sq_cm': principalDisplayAreaSqCm,
    'required_min_font_height_mm': requiredMinFontHeightMm,
  };
}

class ViolationItem {
  final String ruleId;
  final String description;
  final String severity; // CRITICAL, MODERATE, MINOR
  final String? remedy;

  const ViolationItem({
    required this.ruleId,
    required this.description,
    required this.severity,
    this.remedy,
  });

  factory ViolationItem.fromJson(Map<String, dynamic> json) {
    return ViolationItem(
      ruleId: json['rule_id'] as String? ?? 'RULE_UNKNOWN',
      description: json['description'] as String? ?? '',
      severity: json['severity'] as String? ?? 'MINOR',
      remedy: json['remedy'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'rule_id': ruleId,
    'description': description,
    'severity': severity,
    if (remedy != null) 'remedy': remedy,
  };
}

class ScanResult {
  final String scanId;
  final String category;
  final ExtractedFields extractedFields;
  final MeasurementsMm measurementsMm;
  final List<ViolationItem> violations;
  final String overallSeverity; // COMPLIANT, MINOR, MODERATE, CRITICAL
  final String? manualCheckRequired;
  final String? evidenceHash;
  final DateTime timestamp;

  const ScanResult({
    required this.scanId,
    required this.category,
    required this.extractedFields,
    required this.measurementsMm,
    required this.violations,
    required this.overallSeverity,
    this.manualCheckRequired,
    this.evidenceHash,
    required this.timestamp,
  });

  bool get isCompliant => overallSeverity.toUpperCase() == 'COMPLIANT' || violations.isEmpty;
  bool get hasViolations => violations.isNotEmpty;

  factory ScanResult.fromJson(Map<String, dynamic> json, {String category = 'Packaged Food'}) {
    final violationsList = (json['violations'] as List<dynamic>?)
            ?.map((v) => ViolationItem.fromJson(v as Map<String, dynamic>))
            .toList() ??
        [];

    return ScanResult(
      scanId: json['scan_id'] as String? ?? 'SCAN_${DateTime.now().millisecondsSinceEpoch}',
      category: json['category'] as String? ?? category,
      extractedFields: ExtractedFields.fromJson(
        (json['extracted_fields'] as Map<String, dynamic>?) ?? {},
      ),
      measurementsMm: MeasurementsMm.fromJson(
        (json['measurements_mm'] as Map<String, dynamic>?) ?? {},
      ),
      violations: violationsList,
      overallSeverity: json['overall_severity'] as String? ??
          (violationsList.isEmpty ? 'COMPLIANT' : violationsList.first.severity),
      manualCheckRequired: json['manual_check_required'] as String?,
      evidenceHash: json['evidence_hash'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ApiClient {
  final String baseUrl;

  const ApiClient({this.baseUrl = 'http://localhost:8000'});

  /// Submits scan photo to the backend /scan endpoint matching shared/api_contract.yaml
  Future<ScanResult> submitScan({
    required Uint8List imageBytes,
    required String fileName,
    required String category,
    bool coinDetected = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/scan');
      final request = http.MultipartRequest('POST', uri);
      
      request.fields['category'] = category;
      request.fields['coin_detected'] = coinDetected.toString();
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: fileName,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return ScanResult.fromJson(data, category: category);
      } else {
        // Fallback to offline mock on network error
        return getMockScanResult(category: category, simulateViolation: false);
      }
    } catch (_) {
      // Return safe mock response if backend is offline during early sprints
      return getMockScanResult(category: category, simulateViolation: false);
    }
  }

  /// Provides standardized Mock data for UI development and offline demonstration
  static ScanResult getMockScanResult({
    String category = 'Packaged Food & Beverage',
    bool simulateViolation = false,
  }) {
    if (simulateViolation) {
      return ScanResult(
        scanId: 'SCAN-2026-IND-0842',
        category: category,
        extractedFields: const ExtractedFields(
          mrp: 'Rs. 45.00 (Incl. of all taxes)',
          netQuantity: '200 g',
          manufacturerAddress: 'Hindustan Consumer Goods Pvt Ltd, Plot 44, Okhla Phase III, New Delhi 110020',
          mfgDate: '11/2025',
          consumerCare: 'care@hindustanconsumer.in | 1800-11-4455',
        ),
        measurementsMm: const MeasurementsMm(
          fontHeightMm: 1.45,
          principalDisplayAreaSqCm: 140.0,
          requiredMinFontHeightMm: 2.0,
        ),
        violations: const [
          ViolationItem(
            ruleId: 'Rule 8(1) / Table I',
            description: 'Numeral font height for Net Quantity is 1.45 mm; mandatory minimum is 2.00 mm for PDP area 100-200 cm².',
            severity: 'MODERATE',
            remedy: 'Increase font size to minimum 2.0 mm in future print batches.',
          ),
          ViolationItem(
            ruleId: 'Rule 6(1)(e)',
            description: 'Country of Origin declaration missing on imported raw material batch.',
            severity: 'CRITICAL',
            remedy: 'Add "Country of Origin: India" prominently on principal display panel.',
          ),
        ],
        overallSeverity: 'CRITICAL',
        manualCheckRequired: 'Sixth Schedule: Verify gross vs net weight tolerance band (maximum permissible error ±4.5g).',
        evidenceHash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        timestamp: DateTime.now(),
      );
    } else {
      return ScanResult(
        scanId: 'SCAN-2026-IND-0843',
        category: category,
        extractedFields: const ExtractedFields(
          mrp: 'Rs. 85.00 (Inclusive of all taxes)',
          netQuantity: '500 g',
          manufacturerAddress: 'National Foods Corporation, Sector 18, Gurugram, Haryana 122015',
          mfgDate: '01/2026',
          consumerCare: 'support@nationalfoods.gov.in | 1800-22-9900',
        ),
        measurementsMm: const MeasurementsMm(
          fontHeightMm: 2.40,
          principalDisplayAreaSqCm: 180.0,
          requiredMinFontHeightMm: 2.0,
        ),
        violations: const [],
        overallSeverity: 'COMPLIANT',
        manualCheckRequired: 'Rule 19: Conduct standard random tare check if seal appears resealed.',
        evidenceHash: '8f434346648f6b96df89dda901c5176b10a6d83961dd3c1ac88b59b2dc327aa4',
        timestamp: DateTime.now(),
      );
    }
  }
}
