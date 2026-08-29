// ==============================================================================
// LEGALMETRY — Results & Review Screen (Screen B5 / Module 1.5)
// Track 5: UI / Reports (Person 5)
//
// Governing Standard: GIGW 3.0 / UI Design Context Document B5
// Displays compliance verdict, Rule 6 declarations, real-world font mm
// measurements, MHI manufacturer index, severity badges, and physical routing.
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
  String _selectedSeverityFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _result = widget.initialResult ??
        ApiClient.getMockScanResult(scenario: MockScenario.fontDeficitAndMissingOrigin);
  }

  void _switchScenario(MockScenario scenario) {
    setState(() {
      _result = ApiClient.getMockScanResult(scenario: scenario);
      _selectedSeverityFilter = 'ALL';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width >= 850;

    return Scaffold(
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          // Scenario Switcher for Interactive Demo & Multi-Case Testing
          _buildScenarioSwitcherBar(isDark),

          // Main Scrollable Results Feed
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Overall Verdict Banner
                      _buildVerdictBanner(isDark),
                      const SizedBox(height: AppTheme.spacing16),

                      // 2. Degradation / Pipeline Warning Banner (if status != 'ok')
                      if (_result.status != 'ok') ...[
                        _buildDegradationWarningBanner(isDark),
                        const SizedBox(height: AppTheme.spacing16),
                      ],

                      // 3. Manufacturer & MHI Health Index Card
                      if (_result.manufacturer != null && _result.manufacturer!.manufacturerId != null) ...[
                        _buildManufacturerMhiCard(isDark),
                        const SizedBox(height: AppTheme.spacing16),
                      ],

                      // 4. Optical Font & PDP Physical Measurements Card
                      _buildMeasurementCard(isDark),
                      const SizedBox(height: AppTheme.spacing20),

                      // 5. Rule 6 Mandatory Declarations Section
                      _buildSectionHeader(
                        _isHindi ? 'अनिवार्य लेबल घोषणाएं (नियम 6)' : 'Mandatory Label Declarations (Rule 6)',
                        Icons.checklist_rtl,
                        isDark,
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                      if (isWide) _buildDeclarationsGrid(isDark) else _buildDeclarationsList(isDark),
                      const SizedBox(height: AppTheme.spacing20),

                      // 6. Statutory Violations Section (if any exist)
                      if (_result.hasViolations) ...[
                        _buildViolationsSection(isDark),
                        const SizedBox(height: AppTheme.spacing20),
                      ],

                      // 7. Category-Aware Verification Router Note (Honesty Card)
                      if (_result.manualCheckRequired != null) ...[
                        _buildManualCheckCard(isDark),
                        const SizedBox(height: AppTheme.spacing20),
                      ],

                      // 8. Cryptographic Evidence Fingerprint Manifest
                      if (_result.evidence != null && _result.evidence!.sha256Hash != null) ...[
                        _buildEvidenceManifestCard(isDark),
                        const SizedBox(height: AppTheme.spacing20),
                      ],

                      const SizedBox(height: AppTheme.spacing32),
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
  // Top App Bar with Language Toggle & Emblem Identity
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isHindi ? 'विधिक मापविज्ञान अनुपालन प्रणाली' : 'LEGALMETRY Scanner',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            _isHindi ? 'परीक्षण परिणाम एवं वैधानिक समीक्षा' : 'Inspection Verdict & Statutory Review',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
      actions: [
        // Persistent GIGW 3.0 Language Toggle
        TextButton.icon(
          onPressed: () => setState(() => _isHindi = !_isHindi),
          icon: const Icon(Icons.translate, color: Colors.white, size: 18),
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
  // Scenario Switcher Bar (For testing all real pipeline responses)
  // ---------------------------------------------------------------------------
  Widget _buildScenarioSwitcherBar(bool isDark) {
    return Container(
      color: isDark ? AppTheme.darkSurface : AppTheme.surfaceLight,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              _isHindi ? 'परिदृश्य:' : 'Pipeline Response:',
              style: AppTheme.caption.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: AppTheme.spacing12),
            _buildScenarioChip(
              label: 'Compliant Pass',
              isSelected: _result.isCompliant && _result.status == 'ok',
              color: AppTheme.compliantGreen,
              onTap: () => _switchScenario(MockScenario.compliant),
            ),
            const SizedBox(width: AppTheme.spacing8),
            _buildScenarioChip(
              label: 'Font Deficit & Origin Violation',
              isSelected: _result.hasViolations && _result.status == 'ok',
              color: AppTheme.criticalRed,
              onTap: () => _switchScenario(MockScenario.fontDeficitAndMissingOrigin),
            ),
            const SizedBox(width: AppTheme.spacing8),
            _buildScenarioChip(
              label: 'No Coin Detected',
              isSelected: _result.status == 'no_coin_detected',
              color: AppTheme.needsReviewGold,
              onTap: () => _switchScenario(MockScenario.noCoinDetected),
            ),
            const SizedBox(width: AppTheme.spacing8),
            _buildScenarioChip(
              label: 'Low Confidence OCR',
              isSelected: _result.status == 'low_confidence',
              color: AppTheme.moderateAmber,
              onTap: () => _switchScenario(MockScenario.lowConfidenceOcr),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: color.withOpacity(0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? color : null,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Overall Verdict Banner
  // ---------------------------------------------------------------------------
  Widget _buildVerdictBanner(bool isDark) {
    final severityColor = AppTheme.severityColor(_result.severity);
    final severityLabel = AppTheme.severityLabel(_result.severity);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: AppTheme.cardDecorationWithSeverity(_result.severity, isDark: isDark),
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
                      'Scan Reference: ${_result.scanId}',
                      style: AppTheme.caption.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Category: ${_result.category}',
                      style: AppTheme.headingSmall.copyWith(
                        color: isDark ? Colors.white70 : AppTheme.secondaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              // Overall Severity Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12, vertical: AppTheme.spacing6),
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _result.isCompliant ? Icons.verified : Icons.gavel,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: AppTheme.spacing6),
                    Text(
                      severityLabel.toUpperCase(),
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
          const Divider(height: AppTheme.spacing20),
          Text(
            _result.isCompliant
                ? (_isHindi
                    ? 'लेबल की सभी घोषणाएं और फॉन्ट आयाम विधिक मापविज्ञान (पैकेज्ड कमोडिटीज) नियम, 2011 के अनुसार पूर्णतः वैध हैं।'
                    : 'All mandatory label declarations and physical font dimensions comply fully with Legal Metrology Rules, 2011.')
                : (_isHindi
                    ? 'कुल ${_result.violations.length} वैधानिक उल्लंघन पाए गए। जन विश्वास अधिनियम, 2026 के अंतर्गत 15-दिवसीय सुधार नोटिस देय है।'
                    : 'Total ${_result.violations.length} statutory violation(s) detected. Statutory 15-day Improvement Notice required under Jan Vishwas Reform.'),
            style: AppTheme.bodyBold.copyWith(
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Degradation / Pipeline Warning Banner
  // ---------------------------------------------------------------------------
  Widget _buildDegradationWarningBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.moderateAmber.withOpacity(isDark ? 0.25 : 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.moderateAmber, width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.moderateAmber, size: 22),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Text(
              _result.status == 'no_coin_detected'
                  ? 'Reference coin not detected in image. Fallback mode enabled: font height estimated using default pixel density.'
                  : 'Low OCR confidence detected on label segment. Please review ambiguous fields physically.',
              style: AppTheme.body.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Manufacturer Entity & MHI Card
  // ---------------------------------------------------------------------------
  Widget _buildManufacturerMhiCard(bool isDark) {
    final mfr = _result.manufacturer!;
    final mhi = mfr.mhiScore ?? 100.0;
    final mhiColor = mhi >= 80 ? AppTheme.compliantGreen : (mhi >= 50 ? AppTheme.moderateAmber : AppTheme.criticalRed);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: AppTheme.cardDecoration(isDark: isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.business, size: 20, color: AppTheme.primaryNavy),
                  const SizedBox(width: AppTheme.spacing8),
                  Text(
                    _isHindi ? 'निर्माता स्वास्थ्य सूचकांक (MHI)' : 'Entity Resolution & Health Index',
                    style: AppTheme.headingSmall.copyWith(
                      color: isDark ? Colors.white : AppTheme.primaryNavy,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: mhiColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  border: Border.all(color: mhiColor),
                ),
                child: Text(
                  'Match: ${mfr.matchType.toUpperCase()}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mhiColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _result.extractedFields.manufacturerName ?? 'Identified Manufacturer',
                      style: AppTheme.bodyBold,
                    ),
                    const SizedBox(height: 2),
                    Text('Entity ID: ${mfr.manufacturerId}', style: AppTheme.caption),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: mhiColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: mhiColor, width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(
                      '${mhi.toStringAsFixed(1)} / 100',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: mhiColor),
                    ),
                    Text('MHI Score', style: AppTheme.caption.copyWith(fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Real-World Optical Font & PDP Measurements Card
  // ---------------------------------------------------------------------------
  Widget _buildMeasurementCard(bool isDark) {
    final m = _result.measurements;
    final isFontPass = m.isFontCompliant;
    final fontHeight = m.fontHeightMm ?? 0.0;
    final minReq = m.tableIMinimumMm ?? 2.0;
    final pdp = m.principalDisplayAreaSqCm ?? 140.0;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: AppTheme.cardDecoration(isDark: isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.straighten, size: 20, color: AppTheme.secondaryBlue),
                  const SizedBox(width: AppTheme.spacing8),
                  Text(
                    _isHindi ? 'ऑप्टिकल फॉन्ट और PDP माप (तालिका I)' : 'Optical Font & PDP Dimensions',
                    style: AppTheme.headingSmall.copyWith(
                      color: isDark ? Colors.white : AppTheme.secondaryBlue,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: AppTheme.statusChipDecoration(isFontPass ? 'COMPLIANT' : 'CRITICAL', isDark: isDark),
                child: Text(
                  isFontPass ? 'TABLE I PASS' : 'FONT SIZE DEFICIT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isFontPass ? AppTheme.compliantGreen : AppTheme.criticalRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: _isHindi ? 'मापा गया फॉन्ट आकार' : 'Measured Font Height',
                  value: '${fontHeight.toStringAsFixed(2)} mm',
                  subtitle: 'Mandatory Minimum: ${minReq.toStringAsFixed(2)} mm',
                  isPassing: isFontPass,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: _buildMetricTile(
                  title: _isHindi ? 'मुख्य प्रदर्शन क्षेत्र (PDP)' : 'Display Area (PDP)',
                  value: '${pdp.toStringAsFixed(1)} cm²',
                  subtitle: 'Table I Bracket: 100-200 cm²',
                  isPassing: true,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          if (!isFontPass) ...[
            const SizedBox(height: AppTheme.spacing8),
            Text(
              '⚠️ Font Deficit of ${m.fontDeficitMm.toStringAsFixed(2)} mm detected against Table I statutory threshold.',
              style: AppTheme.caption.copyWith(color: AppTheme.criticalRed, fontWeight: FontWeight.bold),
            ),
          ],
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
    final statusColor = isPassing ? AppTheme.compliantGreen : AppTheme.criticalRed;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: statusColor, width: 1.2),
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
            style: AppTheme.caption.copyWith(fontSize: 11, color: statusColor),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Rule 6 Mandatory Declarations Cards
  // ---------------------------------------------------------------------------
  Widget _buildDeclarationsList(bool isDark) {
    final f = _result.extractedFields;
    return Column(
      children: [
        _buildFieldCard('Maximum Retail Price (MRP)', f.mrp, 'Rule 6(1)(e)', isDark),
        const SizedBox(height: AppTheme.spacing8),
        _buildFieldCard('Net Quantity & Units', f.netQuantity, 'Rule 6(1)(d)', isDark),
        const SizedBox(height: AppTheme.spacing8),
        _buildFieldCard('Manufacturer / Packer Details', f.manufacturerAddress, 'Rule 6(1)(a)', isDark),
        const SizedBox(height: AppTheme.spacing8),
        _buildFieldCard('Month & Year of Mfg / Import', f.mfgDate, 'Rule 6(1)(b)', isDark),
        const SizedBox(height: AppTheme.spacing8),
        _buildFieldCard('Consumer Care Contact', f.consumerCare, 'Rule 6(1)(g)', isDark),
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
          child: _buildFieldCard('Net Quantity & Units', f.netQuantity, 'Rule 6(1)(d)', isDark),
        ),
        SizedBox(
          width: 480,
          child: _buildFieldCard('Manufacturer / Packer Details', f.manufacturerAddress, 'Rule 6(1)(a)', isDark),
        ),
        SizedBox(
          width: 480,
          child: _buildFieldCard('Month & Year of Mfg / Import', f.mfgDate, 'Rule 6(1)(b)', isDark),
        ),
        SizedBox(
          width: 480,
          child: _buildFieldCard('Consumer Care Contact', f.consumerCare, 'Rule 6(1)(g)', isDark),
        ),
      ],
    );
  }

  Widget _buildFieldCard(String label, String? value, String ruleCitation, bool isDark) {
    final bool isMissing = value == null || value.toLowerCase().contains('not detected') || value.trim().isEmpty;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: AppTheme.cardDecorationWithSeverity(isMissing ? 'MODERATE' : 'COMPLIANT', isDark: isDark),
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
            isMissing ? 'Declaration missing or unreadable on package' : value,
            style: AppTheme.bodyBold.copyWith(
              color: isMissing ? AppTheme.criticalRed : (isDark ? Colors.white : AppTheme.textPrimary),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ruleCitation,
            style: AppTheme.caption.copyWith(fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Statutory Violations & Remedies List
  // ---------------------------------------------------------------------------
  Widget _buildViolationsSection(bool isDark) {
    final filteredViolations = _selectedSeverityFilter == 'ALL'
        ? _result.violations
        : _result.violations.where((v) => v.severity.toUpperCase() == _selectedSeverityFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(
              _isHindi ? 'पाए गए वैधानिक उल्लंघन' : 'Identified Statutory Violations',
              Icons.gavel,
              isDark,
              color: AppTheme.criticalRed,
            ),
            // Severity Filter Buttons
            Row(
              children: [
                _buildFilterChip('ALL'),
                const SizedBox(width: 4),
                _buildFilterChip('CRITICAL'),
                const SizedBox(width: 4),
                _buildFilterChip('MODERATE'),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        if (filteredViolations.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            child: Text('No violations matching filter.', style: AppTheme.caption),
          )
        else
          ...filteredViolations.map((v) => _buildViolationCard(v, isDark)),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedSeverityFilter == label;
    return InkWell(
      onTap: () => setState(() => _selectedSeverityFilter = label),
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: AppTheme.borderGrey),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildViolationCard(Violation v, bool isDark) {
    final severityColor = AppTheme.severityColor(v.severity);

    return Container(
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
                v.ruleReference,
                style: AppTheme.bodyBold.copyWith(color: severityColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: AppTheme.statusChipDecoration(v.severity, isDark: isDark),
                child: Text(
                  v.severity.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: severityColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(v.description, style: AppTheme.body),
          if (v.remedy != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBackground : Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.build_circle_outlined, size: 16, color: AppTheme.secondaryBlue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Statutory Remedy: ${v.remedy}',
                      style: AppTheme.caption.copyWith(
                        color: isDark ? Colors.white70 : AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. Category-Aware Verification Router Note (Honesty Card per B5)
  // ---------------------------------------------------------------------------
  Widget _buildManualCheckCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing14),
      decoration: BoxDecoration(
        color: AppTheme.needsReviewGold.withOpacity(isDark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.needsReviewGold, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fact_check, color: AppTheme.needsReviewGold, size: 24),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isHindi ? 'छठी अनुसूची / भौतिक सत्यापन निर्देश' : 'Sixth Schedule Physical Verification Directive',
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
  // 8. Cryptographic Evidence Manifest Card
  // ---------------------------------------------------------------------------
  Widget _buildEvidenceManifestCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.borderGrey),
      ),
      child: Row(
        children: [
          const Icon(Icons.fingerprint, color: AppTheme.primaryNavy, size: 24),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SHA-256 Cryptographic Evidence Fingerprint', style: AppTheme.caption.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                SelectableText(
                  _result.evidence!.sha256Hash!,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sticky Bottom Action Bar
  // ---------------------------------------------------------------------------
  Widget _buildStickyActionBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border(top: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.borderGrey, width: 1.0)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: AppTheme.secondaryButtonStyle,
                child: Text(_isHindi ? 'नया उत्पाद स्कैन' : 'Scan Next Commodity'),
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReportExportScreen(scanResult: _result),
                    ),
                  );
                },
                style: AppTheme.primaryButtonStyle,
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: Text(_isHindi ? 'वैधानिक रिपोर्ट (PDF)' : 'Generate Report (PDF)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? (isDark ? Colors.white70 : AppTheme.primaryNavy)),
        const SizedBox(width: AppTheme.spacing8),
        Text(
          title,
          style: AppTheme.headingMedium.copyWith(
            color: color ?? (isDark ? AppTheme.darkTextPrimary : AppTheme.primaryNavy),
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
