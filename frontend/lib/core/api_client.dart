// ==============================================================================
// LEGALMETRY — Backend API Client & Data Models
// Track 5: UI / Reports (Person 5)
//
// Aligned with shared/api_contract.yaml (POST /scan)
// ==============================================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Rule 6 Mandatory Declarations extracted via OCR
class ExtractedFields {
  final String? mrp;
  final String? netQuantity;
  final String? manufacturerName;
  final String? manufacturerAddress;
  final String? mfgDate;
  final String? consumerCare;

  const ExtractedFields({
    this.mrp,
    this.netQuantity,
    this.manufacturerName,
    this.manufacturerAddress,
    this.mfgDate,
    this.consumerCare,
  });

  factory ExtractedFields.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ExtractedFields();
    return ExtractedFields(
      mrp: json['mrp'] as String?,
      netQuantity: json['net_quantity'] as String?,
      manufacturerName: json['manufacturer_name'] as String?,
      manufacturerAddress: json['manufacturer_address'] as String?,
      mfgDate: json['mfg_date'] as String?,
      consumerCare: json['consumer_care'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'mrp': mrp,
    'net_quantity': netQuantity,
    'manufacturer_name': manufacturerName,
    'manufacturer_address': manufacturerAddress,
    'mfg_date': mfgDate,
    'consumer_care': consumerCare,
  };
}

/// Optical font-size and physical calibration measurements
class Measurements {
  final double? mmPerPixel;
  final double? fontHeightMm;
  final double? tableIMinimumMm;
  final double? principalDisplayAreaSqCm;

  const Measurements({
    this.mmPerPixel,
    this.fontHeightMm,
    this.tableIMinimumMm,
    this.principalDisplayAreaSqCm,
  });

  bool get isFontCompliant {
    if (fontHeightMm == null || tableIMinimumMm == null) return true;
    return fontHeightMm! >= tableIMinimumMm!;
  }

  double get fontDeficitMm {
    if (fontHeightMm == null || tableIMinimumMm == null) return 0.0;
    final diff = tableIMinimumMm! - fontHeightMm!;
    return diff > 0 ? diff : 0.0;
  }

  factory Measurements.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Measurements();
    return Measurements(
      mmPerPixel: (json['mm_per_pixel'] as num?)?.toDouble(),
      fontHeightMm: (json['font_height_mm'] as num?)?.toDouble(),
      tableIMinimumMm: (json['table_i_minimum_mm'] as num?)?.toDouble() ??
          (json['required_min_font_height_mm'] as num?)?.toDouble(),
      principalDisplayAreaSqCm: (json['principal_display_area_sq_cm'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'mm_per_pixel': mmPerPixel,
    'font_height_mm': fontHeightMm,
    'table_i_minimum_mm': tableIMinimumMm,
    if (principalDisplayAreaSqCm != null) 'principal_display_area_sq_cm': principalDisplayAreaSqCm,
  };
}

/// Statutory violation item conforming to shared/api_contract.yaml
class Violation {
  final String field;
  final String ruleReference;
  final String description;
  final String severity; // Minor, Moderate, Critical
  final String? remedy;

  const Violation({
    required this.field,
    required this.ruleReference,
    required this.description,
    required this.severity,
    this.remedy,
  });

  factory Violation.fromJson(Map<String, dynamic> json) {
    return Violation(
      field: json['field'] as String? ?? 'general',
      ruleReference: json['rule_reference'] as String? ?? (json['rule_id'] as String? ?? 'Statutory Rule'),
      description: json['description'] as String? ?? 'Non-compliance detected',
      severity: json['severity'] as String? ?? 'Minor',
      remedy: json['remedy'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'field': field,
    'rule_reference': ruleReference,
    'description': description,
    'severity': severity,
    if (remedy != null) 'remedy': remedy,
  };
}

/// Entity resolution & Manufacturer Health Index (MHI) summary
class ManufacturerResult {
  final String? manufacturerId;
  final String matchType; // exact, none
  final double? mhiScore;

  const ManufacturerResult({
    this.manufacturerId,
    this.matchType = 'none',
    this.mhiScore,
  });

  factory ManufacturerResult.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ManufacturerResult();
    return ManufacturerResult(
      manufacturerId: json['manufacturer_id'] as String?,
      matchType: json['match_type'] as String? ?? 'none',
      mhiScore: (json['mhi_score'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'manufacturer_id': manufacturerId,
    'match_type': matchType,
    'mhi_score': mhiScore,
  };
}

/// Cryptographic evidence manifest
class EvidenceManifest {
  final String? photoUrl;
  final String? sha256Hash;

  const EvidenceManifest({
    this.photoUrl,
    this.sha256Hash,
  });

  factory EvidenceManifest.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const EvidenceManifest();
    return EvidenceManifest(
      photoUrl: json['photo_url'] as String?,
      sha256Hash: json['sha256_hash'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'photo_url': photoUrl,
    'sha256_hash': sha256Hash,
  };
}

/// Complete Scan Response Payload matching shared/api_contract.yaml
class ScanResult {
  final String scanId;
  final String status; // ok, no_coin_detected, ocr_failed, no_declarations_found, low_confidence
  final String category;
  final ExtractedFields extractedFields;
  final Measurements measurements;
  final List<Violation> violations;
  final String severity; // None, Minor, Moderate, Critical
  final ManufacturerResult? manufacturer;
  final EvidenceManifest? evidence;
  final String? manualCheckRequired;
  final DateTime timestamp;

  const ScanResult({
    required this.scanId,
    this.status = 'ok',
    required this.category,
    required this.extractedFields,
    required this.measurements,
    required this.violations,
    required this.severity,
    this.manufacturer,
    this.evidence,
    this.manualCheckRequired,
    required this.timestamp,
  });

  bool get isCompliant =>
      severity.toUpperCase() == 'NONE' ||
      severity.toUpperCase() == 'COMPLIANT' ||
      violations.isEmpty;

  bool get hasViolations => violations.isNotEmpty;

  factory ScanResult.fromJson(Map<String, dynamic> json, {String category = 'packaged_food'}) {
    final rawViolations = json['violations'] as List<dynamic>? ?? [];
    final violationsList = rawViolations
        .map((v) => Violation.fromJson(v as Map<String, dynamic>))
        .toList();

    return ScanResult(
      scanId: json['scan_id'] as String? ?? 'SCAN_${DateTime.now().millisecondsSinceEpoch}',
      status: json['status'] as String? ?? 'ok',
      category: json['category'] as String? ?? category,
      extractedFields: ExtractedFields.fromJson(json['extracted_fields'] as Map<String, dynamic>?),
      measurements: Measurements.fromJson(
        (json['measurements'] ?? json['measurements_mm']) as Map<String, dynamic>?,
      ),
      violations: violationsList,
      severity: json['severity'] as String? ??
          (json['overall_severity'] as String? ?? (violationsList.isEmpty ? 'None' : violationsList.first.severity)),
      manufacturer: ManufacturerResult.fromJson(json['manufacturer'] as Map<String, dynamic>?),
      evidence: EvidenceManifest.fromJson(json['evidence'] as Map<String, dynamic>?),
      manualCheckRequired: json['manual_check_required'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ApiClient {
  final String baseUrl;

  const ApiClient({this.baseUrl = 'http://localhost:8000'});

  /// Submits scan photo to the backend /scan endpoint
  Future<ScanResult> submitScan({
    required Uint8List imageBytes,
    required String fileName,
    required String category,
    bool coinDetected = true,
    String? referenceType = 'coin',
    double? knownDiameterMm = 27.0,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/scan');
      final request = http.MultipartRequest('POST', uri);

      request.fields['category'] = category;
      request.fields['coin_detected'] = coinDetected.toString();
      if (referenceType != null) {
        request.fields['reference_type'] = referenceType;
      }
      if (knownDiameterMm != null) {
        request.fields['known_diameter_mm'] = knownDiameterMm.toString();
      }

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
        return getMockScanResult(category: category, scenario: MockScenario.compliant);
      }
    } catch (_) {
      return getMockScanResult(category: category, scenario: MockScenario.compliant);
    }
  }

  /// Provides standardized Mock data covering all contract scenarios for testing and demonstration
  static ScanResult getMockScanResult({
    String category = 'Packaged Food',
    MockScenario scenario = MockScenario.fontDeficitAndMissingOrigin,
    bool simulateViolation = false,
  }) {
    if (simulateViolation) {
      scenario = MockScenario.fontDeficitAndMissingOrigin;
    }

    switch (scenario) {
      case MockScenario.compliant:
        return ScanResult(
          scanId: 'SCAN-2026-DL-1081',
          status: 'ok',
          category: category,
          extractedFields: const ExtractedFields(
            mrp: '₹85.00 (Incl. of all taxes)',
            netQuantity: '500 g',
            manufacturerName: 'National Foods Corporation Ltd',
            manufacturerAddress: 'Plot 18, Industrial Estate, Gurugram, Haryana 122015',
            mfgDate: '01/2026',
            consumerCare: 'care@nationalfoods.in | 1800-22-9900',
          ),
          measurements: const Measurements(
            mmPerPixel: 0.082,
            fontHeightMm: 2.35,
            tableIMinimumMm: 2.00,
            principalDisplayAreaSqCm: 180.0,
          ),
          violations: const [],
          severity: 'None',
          manufacturer: const ManufacturerResult(
            manufacturerId: 'MFR-IND-00482',
            matchType: 'exact',
            mhiScore: 96.5,
          ),
          evidence: const EvidenceManifest(
            photoUrl: 'minio://legalmetry-evidence/scans/SCAN-2026-DL-1081.jpg',
            sha256Hash: '4a7d1ed414474e4033ac29ccb8653d9b048a82d01d120a1f0a20cb88e8983995',
          ),
          manualCheckRequired: 'Rule 19: Conduct standard random tare check if package seal shows handling marks.',
          timestamp: DateTime.now(),
        );

      case MockScenario.fontDeficitAndMissingOrigin:
        return ScanResult(
          scanId: 'SCAN-2026-DL-1082',
          status: 'ok',
          category: category,
          extractedFields: const ExtractedFields(
            mrp: '₹45.00 (Incl. of all taxes)',
            netQuantity: '200 g',
            manufacturerName: 'Hindustan Consumer Goods Pvt Ltd',
            manufacturerAddress: 'Plot 44, Okhla Phase III, New Delhi 110020',
            mfgDate: '11/2025',
            consumerCare: 'support@hindustanconsumer.in | 1800-11-4455',
          ),
          measurements: const Measurements(
            mmPerPixel: 0.076,
            fontHeightMm: 1.35,
            tableIMinimumMm: 2.00,
            principalDisplayAreaSqCm: 140.0,
          ),
          violations: const [
            Violation(
              field: 'font_height',
              ruleReference: 'Table I - Font Minimums',
              description: 'Measured numeral font height is 1.35 mm; statutory minimum is 2.00 mm for PDP area 100-200 cm² (Deficit: 0.65 mm).',
              severity: 'Moderate',
              remedy: 'Increase font size to minimum 2.0 mm in future print runs.',
            ),
            Violation(
              field: 'country_of_origin',
              ruleReference: 'Rule 6(1)(e) - Mandatory Origin',
              description: 'Country of Origin declaration is completely missing from principal display panel.',
              severity: 'Critical',
              remedy: 'Print "Country of Origin: India" prominently in equal size on the PDP.',
            ),
          ],
          severity: 'Critical',
          manufacturer: const ManufacturerResult(
            manufacturerId: 'MFR-IND-00129',
            matchType: 'exact',
            mhiScore: 68.0,
          ),
          evidence: const EvidenceManifest(
            photoUrl: 'minio://legalmetry-evidence/scans/SCAN-2026-DL-1082.jpg',
            sha256Hash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
          ),
          manualCheckRequired: 'Sixth Schedule: Check gross vs net weight tolerance band (maximum permissible error ±4.5g).',
          timestamp: DateTime.now(),
        );

      case MockScenario.noCoinDetected:
        return ScanResult(
          scanId: 'SCAN-2026-DL-1083',
          status: 'no_coin_detected',
          category: category,
          extractedFields: const ExtractedFields(
            mrp: '₹120.00',
            netQuantity: '1 kg',
            manufacturerName: 'CleanCare Products India Ltd',
            manufacturerAddress: 'Industrial Area, Haridwar',
            mfgDate: '10/2025',
            consumerCare: '1800-44-3322',
          ),
          measurements: const Measurements(),
          violations: const [
            Violation(
              field: 'calibration',
              ruleReference: 'Standard Reference Protocol',
              description: 'Reference coin not detected in image. Physical mm font measurements could not be calibrated.',
              severity: 'Minor',
              remedy: 'Retake photo placing a valid standard coin flat on the package surface.',
            ),
          ],
          severity: 'Minor',
          manualCheckRequired: 'Please re-scan with a reference coin to obtain legal font measurements.',
          timestamp: DateTime.now(),
        );

      case MockScenario.lowConfidenceOcr:
        return ScanResult(
          scanId: 'SCAN-2026-DL-1084',
          status: 'low_confidence',
          category: category,
          extractedFields: const ExtractedFields(
            mrp: '₹??.00',
            netQuantity: '100 ml',
            manufacturerName: 'Aura Cosmetics Ltd',
            manufacturerAddress: null,
            mfgDate: '??/2025',
            consumerCare: null,
          ),
          measurements: const Measurements(
            mmPerPixel: 0.080,
            fontHeightMm: 1.10,
            tableIMinimumMm: 1.50,
            principalDisplayAreaSqCm: 60.0,
          ),
          violations: const [
            Violation(
              field: 'ocr_confidence',
              ruleReference: 'Confidence Router (Tiered Evaluation)',
              description: 'OCR confidence is below 70% due to curved bottle glare. Requires manual inspector verification.',
              severity: 'Moderate',
              remedy: 'Verify manufacturer address and MRP physically before issuing statutory notice.',
            ),
          ],
          severity: 'Moderate',
          manualCheckRequired: 'Curved Surface Check: Re-verify text legibility across curved perimeter.',
          timestamp: DateTime.now(),
        );
    }
  }
}

enum MockScenario {
  compliant,
  fontDeficitAndMissingOrigin,
  noCoinDetected,
  lowConfidenceOcr,
}
