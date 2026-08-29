// ==============================================================================
// LEGALMETRY — Inspector Dashboard Screen (Screen B6 / Module 1.5/1.6)
// Track 5: UI / Reports (Person 5)
//
// Governing Standard: GIGW 3.0 / UI Design Context Document B6
// Shows recent inspector scan history with severity left borders and
// active statutory improvement notices.
// ==============================================================================

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/api_client.dart';
import '../results/scan_results_screen.dart';

class InspectorDashboard extends StatefulWidget {
  const InspectorDashboard({super.key});

  @override
  State<InspectorDashboard> createState() => _InspectorDashboardState();
}

class _InspectorDashboardState extends State<InspectorDashboard> {
  bool _isLoading = false;

  final List<ScanResult> _recentScans = [
    ApiClient.getMockScanResult(category: 'Packaged Food & Beverage', simulateViolation: true),
    ApiClient.getMockScanResult(category: 'Personal Care & Cosmetics', simulateViolation: false),
    ScanResult(
      scanId: 'SCAN-2026-IND-0839',
      category: 'Household Detergents',
      extractedFields: const ExtractedFields(
        mrp: 'Rs. 120.00',
        netQuantity: '1 kg',
        manufacturerAddress: 'CleanCare India Ltd, Haridwar',
        mfgDate: '10/2025',
        consumerCare: '1800-44-3322',
      ),
      measurementsMm: const MeasurementsMm(
        fontHeightMm: 1.8,
        principalDisplayAreaSqCm: 250.0,
        requiredMinFontHeightMm: 2.5,
      ),
      violations: const [
        ViolationItem(
          ruleId: 'Rule 8 / Table I',
          description: 'Font height 1.8 mm is below the mandatory 2.5 mm for PDP area >200 cm².',
          severity: 'MODERATE',
        ),
      ],
      overallSeverity: 'MODERATE',
      manualCheckRequired: 'Sixth Schedule: Check net quantity scale variation.',
      evidenceHash: 'a1b2c3d4e5f67890123456789abcdef0123456789abcdef0123456789abcdef0',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspector Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Scans',
            onPressed: _handleRefresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary Metrics Top Row
              _buildStatsRow(isDark),
              const SizedBox(height: AppTheme.spacing20),

              // Section 1: Recent Scans with Severity Borders
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Inspections', style: AppTheme.headingMedium.copyWith(
                    color: isDark ? Colors.white : AppTheme.primaryNavy,
                  )),
                  Text('${_recentScans.length} logged', style: AppTheme.caption),
                ],
              ),
              const SizedBox(height: AppTheme.spacing8),
              ..._recentScans.map((scan) => _buildScanRowItem(context, scan, isDark)),

              const SizedBox(height: AppTheme.spacing24),

              // Section 2: My Pending Statutory Improvement Notices (Jan Vishwas 2026)
              Text('Pending Improvement Notices', style: AppTheme.headingMedium.copyWith(
                color: isDark ? Colors.white : AppTheme.primaryNavy,
              )),
              const SizedBox(height: AppTheme.spacing8),
              _buildNoticeCard(
                title: 'Notice #IN-2026-0041 • Hindustan Consumer Goods',
                subtitle: 'Violation: Rule 8(1) Font height non-compliance',
                status: 'NOTICE_ISSUED',
                daysRemaining: '12 days left in correction window',
                isDark: isDark,
              ),
              const SizedBox(height: AppTheme.spacing8),
              _buildNoticeCard(
                title: 'Notice #IN-2026-0038 • CleanCare India Ltd',
                subtitle: 'Violation: Table I net quantity height deficit',
                status: 'PENDING_SUPERVISOR_VERIFICATION',
                daysRemaining: 'Awaiting supervisor physical spot-check',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile('Total Scans', '${_recentScans.length + 14}', AppTheme.secondaryBlue, isDark),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: _buildStatTile('Violations', '6', AppTheme.criticalRed, isDark),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: _buildStatTile('Open Notices', '2', AppTheme.moderateAmber, isDark),
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, String count, Color accent, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.borderGrey),
      ),
      child: Column(
        children: [
          Text(count, style: AppTheme.headingLarge.copyWith(color: accent, fontSize: 20)),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.caption.copyWith(fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildScanRowItem(BuildContext context, ScanResult scan, bool isDark) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ScanResultsScreen(initialResult: scan),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
        padding: const EdgeInsets.all(AppTheme.spacing12),
        decoration: AppTheme.cardDecorationWithSeverity(scan.overallSeverity, isDark: isDark),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(scan.scanId, style: AppTheme.bodyBold.copyWith(fontSize: 13)),
                      const SizedBox(width: 8),
                      Text('• ${scan.category}', style: AppTheme.caption),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scan.extractedFields.manufacturerAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: AppTheme.statusChipDecoration(scan.overallSeverity, isDark: isDark),
              child: Text(
                AppTheme.severityLabel(scan.overallSeverity),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.severityColor(scan.overallSeverity),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeCard({
    required String title,
    required String subtitle,
    required String status,
    required String daysRemaining,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: AppTheme.cardDecorationWithSeverity(status, isDark: isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title, style: AppTheme.bodyBold.copyWith(fontSize: 13)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: AppTheme.statusChipDecoration(status, isDark: isDark),
                child: Text(
                  AppTheme.severityLabel(status),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.severityColor(status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTheme.body.copyWith(fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(daysRemaining, style: AppTheme.caption.copyWith(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
