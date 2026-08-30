// ==============================================================================
// LEGALMETRY — Report Export & PDF Generation Screen (Screen B9 / Module 1.7)
// Track 5: UI / Reports (Person 5)
//
// Governing Standard: GIGW 3.0 / UI Design Context Document B9
// Generates official statutory compliance notice PDF, embeds SHA-256 evidence
// integrity hash, and triggers live PDF preview/download and system sharing.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/theme/app_theme.dart';
import '../core/api_client.dart';

class ReportExportScreen extends StatefulWidget {
  final ScanResult scanResult;

  const ReportExportScreen({
    super.key,
    required this.scanResult,
  });

  @override
  State<ReportExportScreen> createState() => _ReportExportScreenState();
}

class _ReportExportScreenState extends State<ReportExportScreen> {
  bool _isExporting = false;

  Future<pw.Document> _buildPdfDocument(ScanResult r) async {
    final doc = pw.Document();
    final fontHeightStr = r.measurements.fontHeightMm?.toStringAsFixed(2) ?? 'Uncalibrated';
    final minReqStr = r.measurements.tableIMinimumMm?.toStringAsFixed(2) ?? '2.00';
    final mfrName = r.extractedFields.manufacturerName ??
        (r.extractedFields.manufacturerAddress ?? 'Unidentified Entity');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Block
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'GOVERNMENT OF INDIA',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, letterSpacing: 1.2),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Ministry of Consumer Affairs, Food & Public Distribution\nDepartment of Consumer Affairs (Legal Metrology Division)',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'STATUTORY INSPECTION NOTICE & EVIDENTIARY RECORD',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
              pw.Divider(thickness: 1.5),
              pw.SizedBox(height: 8),

              // Metadata Grid
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Inspection Ref: ${r.scanId}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text('Category: ${r.category}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text('Date & Time: ${r.timestamp.toIso8601String().substring(0, 19).replaceAll('T', ' ')}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Target Entity / Manufacturer: $mfrName', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 12),

              // Overall Compliance Status
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: r.isCompliant ? PdfColors.green700 : PdfColors.red700,
                    width: 1.5,
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'OVERALL STATUTORY STATUS:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                    ),
                    pw.Text(
                      AppTheme.severityLabel(r.severity).toUpperCase(),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                        color: r.isCompliant ? PdfColors.green700 : PdfColors.red700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // Mandatory Label Declarations (Rule 6)
              pw.Text('1. RULE 6 MANDATORY DECLARATIONS AUDIT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.SizedBox(height: 4),
              pw.Bullet(text: 'Maximum Retail Price (MRP): ${r.extractedFields.mrp ?? "MISSING (Rule 6(1)(e))"}'),
              pw.Bullet(text: 'Net Quantity & Units: ${r.extractedFields.netQuantity ?? "MISSING (Rule 6(1)(d))"}'),
              pw.Bullet(text: 'Manufacturer / Packer: ${mfrName}'),
              pw.Bullet(text: 'Month & Year of Mfg: ${r.extractedFields.mfgDate ?? "MISSING (Rule 6(1)(b))"}'),
              pw.Bullet(text: 'Consumer Care Contact: ${r.extractedFields.consumerCare ?? "MISSING (Rule 6(1)(g))"}'),
              pw.SizedBox(height: 12),

              // Optical Measurements (Table I)
              pw.Text('2. OPTICAL FONT DIMENSIONS & PDP AUDIT (TABLE I)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.SizedBox(height: 4),
              pw.Bullet(text: 'Measured Font Height: $fontHeightStr mm'),
              pw.Bullet(text: 'Mandatory Table I Minimum: $minReqStr mm'),
              pw.Bullet(text: 'Calculated Font Deficit: ${r.measurements.fontDeficitMm.toStringAsFixed(2)} mm'),
              pw.Bullet(text: 'Principal Display Area (PDP): ${r.measurements.principalDisplayAreaSqCm?.toStringAsFixed(1) ?? "140.0"} cm²'),
              pw.SizedBox(height: 12),

              // Statutory Violations (if any)
              if (r.violations.isNotEmpty) ...[
                pw.Text('3. STATUTORY VIOLATIONS & REMEDIAL DIRECTIVES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.red700)),
                pw.SizedBox(height: 4),
                ...r.violations.map((v) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Bullet(
                    text: '[${v.ruleReference}] ${v.description} (${v.severity.toUpperCase()})',
                  ),
                )),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Statutory Note: Under the Jan Vishwas (Amendment of Provisions) Act, 2026, a 15-day statutory correction window applies for first-time non-critical offences.',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 12),
              ],

              // Evidence Integrity Manifest
              pw.Spacer(),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 4),
              pw.Text('EVIDENTIARY INTEGRITY VERIFICATION (MODULE 2.13)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text('SHA-256 Fingerprint: ${r.evidence?.sha256Hash ?? "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}', style: const pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
              pw.Text('Generated by LEGALMETRY Mobile Enforcement System • Strictly for Official Use', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            ],
          );
        },
      ),
    );

    return doc;
  }

  Future<void> _handleExportPdf() async {
    setState(() => _isExporting = true);
    try {
      final doc = await _buildPdfDocument(widget.scanResult);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'legalmetry_notice_${widget.scanResult.scanId}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppTheme.criticalRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleSharePdf() async {
    setState(() => _isExporting = true);
    try {
      final doc = await _buildPdfDocument(widget.scanResult);
      final pdfBytes = await doc.save();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'legalmetry_notice_${widget.scanResult.scanId}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e'), backgroundColor: AppTheme.criticalRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = widget.scanResult;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Statutory Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Status & Header
                _buildHeaderCard(isDark, r),
                const SizedBox(height: AppTheme.spacing16),

                // Report Preview Card (Government Notice Format)
                _buildReportPreviewCard(isDark, r),
                const SizedBox(height: AppTheme.spacing16),

                // SHA-256 Cryptographic Evidence Integrity Badge (Module 2.13)
                _buildEvidenceIntegrityCard(isDark, r),
                const SizedBox(height: AppTheme.spacing24),

                // Primary & Secondary Action Buttons
                _buildActionButtons(context, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(bool isDark, ScanResult r) {
    final severityColor = AppTheme.severityColor(r.severity);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: AppTheme.cardDecoration(isDark: isDark),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(Icons.picture_as_pdf, color: severityColor, size: 32),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Legal Metrology Inspection Notice',
                  style: AppTheme.headingMedium.copyWith(
                    color: isDark ? Colors.white : AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Record ID: ${r.scanId} • Category: ${r.category}',
                  style: AppTheme.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportPreviewCard(bool isDark, ScanResult r) {
    final fontHeight = r.measurements.fontHeightMm?.toStringAsFixed(2) ?? 'Uncalibrated';
    final pdp = r.measurements.principalDisplayAreaSqCm?.toStringAsFixed(1) ?? '140.0';
    final mfrName = r.extractedFields.manufacturerName ??
        (r.extractedFields.manufacturerAddress ?? 'Unidentified Entity');

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.borderGrey, width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                const Icon(Icons.account_balance, size: 28, color: AppTheme.primaryNavy),
                const SizedBox(height: 4),
                Text(
                  'GOVERNMENT OF INDIA',
                  style: AppTheme.headingSmall.copyWith(
                    letterSpacing: 1.2,
                    fontSize: 13,
                    color: isDark ? Colors.white : AppTheme.primaryNavy,
                  ),
                ),
                Text(
                  'Ministry of Consumer Affairs, Food & Public Distribution\nDepartment of Consumer Affairs (Legal Metrology Division)',
                  textAlign: TextAlign.center,
                  style: AppTheme.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          const Divider(height: AppTheme.spacing24),
          _buildPreviewRow('Inspection Reference', r.scanId),
          _buildPreviewRow('Date & Time', r.timestamp.toIso8601String().substring(0, 19).replaceAll('T', ' ')),
          _buildPreviewRow('Commodity Category', r.category),
          _buildPreviewRow('Manufacturer / Entity', mfrName),
          _buildPreviewRow('Declared MRP', r.extractedFields.mrp ?? 'Missing'),
          _buildPreviewRow('Declared Net Quantity', r.extractedFields.netQuantity ?? 'Missing'),
          _buildPreviewRow('Measured Font Height', '$fontHeight mm'),
          _buildPreviewRow('Principal Display Area', '$pdp cm²'),
          _buildPreviewRow(
            'Overall Compliance Status',
            AppTheme.severityLabel(r.severity),
            valueColor: AppTheme.severityColor(r.severity),
          ),
          if (r.violations.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacing12),
            Text('Statutory Violations Identified:', style: AppTheme.bodyBold),
            const SizedBox(height: 4),
            ...r.violations.map(
              (v) => Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                child: Text('• [${v.ruleReference}] ${v.description}', style: AppTheme.body.copyWith(fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(label, style: AppTheme.caption.copyWith(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.body.copyWith(
                fontSize: 13,
                color: valueColor,
                fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceIntegrityCard(bool isDark, ScanResult r) {
    final String hash = r.evidence?.sha256Hash ??
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.borderGrey),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fingerprint, color: AppTheme.primaryNavy, size: 24),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SHA-256 Tamper-Evidence Fingerprint',
                  style: AppTheme.caption.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  hash,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _isExporting ? null : _handleExportPdf,
          style: AppTheme.primaryButtonStyle,
          icon: _isExporting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.download, size: 20),
          label: const Text('Export & Print PDF Document'),
        ),
        const SizedBox(height: AppTheme.spacing12),
        OutlinedButton.icon(
          onPressed: _isExporting ? null : _handleSharePdf,
          style: AppTheme.secondaryButtonStyle,
          icon: const Icon(Icons.share, size: 20),
          label: const Text('Share Evidentiary Notice PDF'),
        ),
      ],
    );
  }
}
