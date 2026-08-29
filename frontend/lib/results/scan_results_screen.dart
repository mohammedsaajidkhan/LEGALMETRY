// ==============================================================================
// LEGALMETRY — Results & Review Screen (Screen B5 / Module 1.5)
// Track 5: UI / Reports (Person 5)
//
// Governing Standard: GIGW 3.0 / UI Design Context Document B5
// Shows scan verdict, extracted declaration fields, font mm measurements,
// severity badges, and physical verification routing checks.
// ==============================================================================

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/api_client.dart';
import '../reports/report_export_screen.dart';

class ScanResultsScreen extends StatefulWidget {
  final ScanResult? initialResult;

  const ScanResultsScreen({
    super.key,
    this.initialResult,
  });

  @override
  State<ScanResultsScreen> createState() => _ScanResultsScreenState();
}

class _ScanResultsScreenState extends State<ScanResultsScreen> {
  late ScanResult _result;
  bool _isHindi = false;

  @override
  void initState() {
    super.initState();
    // Default to initial result or standard mock with violations for evaluation
    _result = widget.initialResult ?? ApiClient.getMockScanResult(simulateViolation: true);
  }

  void _toggleMockData(bool hasViolation) {
    setState(() {
      _result = ApiClient.getMockScanResult(simulateViolation: hasViolation);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          // Mock data selector for rapid UI evaluation
          _buildQuickScenarioSwitcher(isDark),

          // Main scrolling results content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Verdict Banner Card
                      _buildVerdictBanner(isDark),
                      const SizedBox(height: AppTheme.spacing16),

                      // Measurements & Physical Area Summary
                      _buildMeasurementSummaryCard(isDark),
                      const SizedBox(height: AppTheme.spacing16),

                      // Section Title
                      Text(
                        _isHindi ? 'अनिवार्य घोषणा विवरण (नियम 6)' : 'Mandatory Declarations (Rule 6)',
                        style: AppTheme.headingMedium.copyWith(
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing12),

                      // Declaration Cards (Responsive Grid for Web / List for Mobile)
                      if (isWide)
                        _buildDeclarationsGrid(isDark)
                      else
                        _buildDeclarationsList(isDark),

                      // Violations Detail List if any
                      if (_result.hasViolations) ...[
                        const SizedBox(height: AppTheme.spacing20),
                        _buildViolationsSection(isDark),
                      ],

                      // Category-Aware Verification Router Note (Honesty styled)
                      if (_result.manualCheckRequired != null) ...[
                        const SizedBox(height: AppTheme.spacing16),
                        _buildManualCheckCard(isDark),
                      ],

                      const SizedBox(height: AppTheme.spacing24),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Sticky Bottom Action Bar
          _buildStickyActionBar(context, isDark),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top App Bar (Emblem / Name + Language Toggle per GIGW 3.0)
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isHindi ? 'विधिक मापविज्ञान अनुपालन' : 'LEGALMETRY Scanner',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            _isHindi ? 'सत्यापन परिणाम एवं समीक्षा' : 'Inspection Verdict & Review',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
      actions: [
        // Language Toggle (Persistent top-right per GIGW standard)
        TextButton.icon(
          onPressed: () => setState(() => _isHindi = !_isHindi),
          icon: const Icon(Icons.language, color: Colors.white, size: 18),
          label: Text(
            _isHindi ? 'EN' : 'हिन्दी',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: AppTheme.spacing8),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Scenario Switcher (Helpful for Live Demo & Verification)
  // ---------------------------------------------------------------------------
  Widget _buildQuickScenarioSwitcher(bool isDark) {
    return Container(
      color: isDark ? AppTheme.darkSurface : AppTheme.surfaceLight,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _isHindi ? 'सिम्युलेटेड परिदृश्य:' : 'Simulate Verdict:',
            style: AppTheme.caption.copyWith(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              ChoiceChip(
                label: Text(_isHindi ? 'उल्लंघन सहित' : 'With Violations'),
                selected: _result.hasViolations,
                onSelected: (_) => _toggleMockData(true),
                selectedColor: AppTheme.criticalRed.withOpacity(0.2),
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: _result.hasViolations ? AppTheme.criticalRed : null,
                  fontWeight: _result.hasViolations ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              ChoiceChip(
                label: Text(_isHindi ? 'अनुपालन (पास)' : 'Compliant (Pass)'),
                selected: !_result.hasViolations,
                onSelected: (_) => _toggleMockData(false),
                selectedColor: AppTheme.compliantGreen.withOpacity(0.2),
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: !_result.hasViolations ? AppTheme.compliantGreen : null,
                  fontWeight: !_result.hasViolations ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Verdict Summary Banner
  // ---------------------------------------------------------------------------
  Widget _buildVerdictBanner(bool isDark) {
    final Color severityColor = AppTheme.severityColor(_result.overallSeverity);
    final String severityText = AppTheme.severityLabel(_result.overallSeverity);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: AppTheme.cardDecorationWithSeverity(_result.overallSeverity, isDark: isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID: ${_result.scanId}',
                      style: AppTheme.caption.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _result.category,
                      style: AppTheme.headingSmall.copyWith(
                        color: isDark ? Colors.white70 : AppTheme.secondaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              // Overall Severity Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12, vertical: AppTheme.spacing4),
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _result.isCompliant ? Icons.check_circle : Icons.warning_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: AppTheme.spacing4),
                    Text(
                      severityText.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: AppTheme.spacing24),
          Text(
            _result.isCompliant
                ? (_isHindi
                    ? 'सभी अनिवार्य घोषणाएं और फॉन्ट आकार विधिक मापविज्ञान नियमों के अनुरूप हैं।'
                    : 'All mandatory label declarations and font dimensions comply with Legal Metrology Rules, 2011.')
                : (_isHindi
                    ? '${_result.violations.length} उल्लंघन पाए गए। वैधानिक सुधार नोटिस आवश्यक है।'
                    : '${_result.violations.length} non-compliance violation(s) detected. Statutory notice required under Jan Vishwas Act.'),
            style: AppTheme.bodyBold.copyWith(
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Measurement & Font Height Summary Card
  // ---------------------------------------------------------------------------
  Widget _buildMeasurementSummaryCard(bool isDark) {
    final m = _result.measurementsMm;
    final bool fontPass = m.fontHeightMm >= m.requiredMinFontHeightMm;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: AppTheme.cardDecoration(isDark: isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.straighten, size: 20, color: AppTheme.secondaryBlue),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                _isHindi ? 'सटीक ज्यामितीय माप (सिक्का कैलिब्रेटेड)' : 'Optical Font & PDP Measurements',
                style: AppTheme.headingSmall.copyWith(
                  color: isDark ? Colors.white : AppTheme.secondaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: _isHindi ? 'मापा गया फॉन्ट' : 'Measured Height',
                  value: '${m.fontHeightMm.toStringAsFixed(2)} mm',
                  subtitle: 'Min req: ${m.requiredMinFontHeightMm} mm',
                  isPassing: fontPass,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: _buildMetricTile(
                  title: _isHindi ? 'मुख्य प्रदर्शन क्षेत्र (PDP)' : 'Display Area (PDP)',
                  value: '${m.principalDisplayAreaSqCm.toStringAsFixed(1)} cm²',
                  subtitle: 'Table I Bracket: 100-200 cm²',
                  isPassing: true,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required bool isPassing,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: isPassing ? AppTheme.minorGreen : AppTheme.criticalRed,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.caption),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.headingMedium.copyWith(
              fontSize: 18,
              color: isPassing ? (isDark ? Colors.white : AppTheme.primaryNavy) : AppTheme.criticalRed,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTheme.caption.copyWith(
              fontSize: 11,
              color: isPassing ? AppTheme.minorGreen : AppTheme.criticalRed,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Declaration Field Cards
  // ---------------------------------------------------------------------------
  Widget _buildDeclarationsList(bool isDark) {
    final f = _result.extractedFields;
    return Column(
      children: [
        _buildFieldCard('Maximum Retail Price (MRP)', f.mrp, 'Rule 6(1)(e)', isDark),
        const SizedBox(height: AppTheme.spacing8),
        _buildFieldCard('Net Quantity', f.netQuantity, 'Rule 6(1)(d)', isDark),
        const SizedBox(height: AppTheme.spacing8),
        _buildFieldCard('Manufacturer / Packer Address', f.manufacturerAddress, 'Rule 6(1)(a)', isDark),
        const SizedBox(height: AppTheme.spacing8),
        _buildFieldCard('Month & Year of Mfg/Import', f.mfgDate, 'Rule 6(1)(b)', isDark),
        const SizedBox(height: AppTheme.spacing8),
        _buildFieldCard('Consumer Care Details', f.consumerCare, 'Rule 6(1)(g)', isDark),
      ],
    );
  }

  Widget _buildDeclarationsGrid(bool isDark) {
    final f = _result.extractedFields;
    return Wrap(
      spacing: AppTheme.spacing12,
      runSpacing: AppTheme.spacing12,
      children: [
        SizedBox(
          width: 480,
          child: _buildFieldCard('Maximum Retail Price (MRP)', f.mrp, 'Rule 6(1)(e)', isDark),
        ),
        SizedBox(
          width: 480,
          child: _buildFieldCard('Net Quantity', f.netQuantity, 'Rule 6(1)(d)', isDark),
        ),
        SizedBox(
          width: 480,
          child: _buildFieldCard('Manufacturer / Packer Address', f.manufacturerAddress, 'Rule 6(1)(a)', isDark),
        ),
        SizedBox(
          width: 480,
          child: _buildFieldCard('Month & Year of Mfg/Import', f.mfgDate, 'Rule 6(1)(b)', isDark),
        ),
        SizedBox(
          width: 480,
          child: _buildFieldCard('Consumer Care Details', f.consumerCare, 'Rule 6(1)(g)', isDark),
        ),
      ],
    );
  }

  Widget _buildFieldCard(String label, String value, String legalRule, bool isDark) {
    final bool isMissing = value.toLowerCase().contains('not detected') || value.trim().isEmpty;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: AppTheme.cardDecorationWithSeverity(
        isMissing ? 'MODERATE' : 'COMPLIANT',
        isDark: isDark,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTheme.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : AppTheme.secondaryBlue,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: AppTheme.statusChipDecoration(isMissing ? 'MODERATE' : 'COMPLIANT', isDark: isDark),
                child: Text(
                  isMissing ? 'MISSING' : 'VERIFIED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isMissing ? AppTheme.moderateAmber : AppTheme.compliantGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTheme.bodyBold.copyWith(
              color: isMissing ? AppTheme.criticalRed : (isDark ? Colors.white : AppTheme.textPrimary),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            legalRule,
            style: AppTheme.caption.copyWith(fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Violations Section
  // ---------------------------------------------------------------------------
  Widget _buildViolationsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isHindi ? 'पाए गए कानूनी उल्लंघन' : 'Identified Statutory Violations',
          style: AppTheme.headingMedium.copyWith(
            color: AppTheme.criticalRed,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        ..._result.violations.map(
          (v) => Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
            padding: const EdgeInsets.all(AppTheme.spacing12),
            decoration: AppTheme.cardDecorationWithSeverity(v.severity, isDark: isDark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      v.ruleId,
                      style: AppTheme.bodyBold.copyWith(color: AppTheme.criticalRed),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: AppTheme.statusChipDecoration(v.severity, isDark: isDark),
                      child: Text(
                        v.severity,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.severityColor(v.severity),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(v.description, style: AppTheme.body),
                if (v.remedy != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Remedy / Action: ${v.remedy}',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.moderateAmber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Category-Aware Verification Router Note (Honesty Card per B5)
  // ---------------------------------------------------------------------------
  Widget _buildManualCheckCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.needsReviewGold.withOpacity(isDark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.needsReviewGold, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fact_check, color: AppTheme.needsReviewGold, size: 22),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isHindi ? 'भौतिक सत्यापन आवश्यक (छठी अनुसूची)' : 'Physical Verification Required',
                  style: AppTheme.bodyBold.copyWith(color: AppTheme.needsReviewGold),
                ),
                const SizedBox(height: 4),
                Text(
                  _result.manualCheckRequired!,
                  style: AppTheme.body.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sticky Bottom Action Bar (Generate Report / Scan Next Product)
  // ---------------------------------------------------------------------------
  Widget _buildStickyActionBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border(top: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.borderGrey, width: 1.0)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: AppTheme.secondaryButtonStyle,
                child: Text(_isHindi ? 'अगला स्कैन' : 'Scan Next Product'),
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReportExportScreen(scanResult: _result),
                    ),
                  );
                },
                style: AppTheme.primaryButtonStyle,
                child: Text(_isHindi ? 'रिपोर्ट बनाएं (PDF)' : 'Generate Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
