// ==============================================================================
// LEGALMETRY — Inspector Dashboard Screen (Screen B6 / Module 1.5/1.6)
// Track 5: UI / Reports (Person 5)
//
// Governing Standard: GIGW 3.0 / UI Design Context Document B6 & Part C
// Displays live inspector scan history with severity left borders, real stat
// counters, and GIGW plain-language empty states on fresh installation.
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

  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scans = ScanStore.instance.scans;
    final totalScans = ScanStore.instance.totalScans;
    final totalViolations = ScanStore.instance.totalViolations;
    final totalOpenNotices = ScanStore.instance.totalOpenNotices;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Inspector Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Field Compliance History & Notices', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Inspections',
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
              // Summary Metrics Top Row (Real Dynamic Stats)
              _buildStatsRow(totalScans, totalViolations, totalOpenNotices, isDark),
              const SizedBox(height: AppTheme.spacing24),

              // Section 1: Recent Scans Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Inspections',
                    style: AppTheme.headingMedium.copyWith(
                      color: isDark ? Colors.white : AppTheme.primaryNavy,
                    ),
                  ),
                  Text(
                    totalScans == 0 ? '0 logged' : '$totalScans logged',
                    style: AppTheme.caption,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing12),

              // Section 1 Content: List or GIGW Empty State
              if (scans.isEmpty)
                _buildEmptyScansState(context, isDark)
              else
                ...scans.map((scan) => _buildScanRowItem(context, scan, isDark)),

              const SizedBox(height: AppTheme.spacing28),

              // Section 2: Statutory Improvement Notices (Jan Vishwas Act, 2026)
              Text(
                'Active Statutory Notices',
                style: AppTheme.headingMedium.copyWith(
                  color: isDark ? Colors.white : AppTheme.primaryNavy,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),

              // Section 2 Content: Notice Cards or Empty State
              if (totalOpenNotices == 0)
                _buildEmptyNoticesState(isDark)
              else
                ...scans
                    .where((s) => s.hasViolations)
                    .map((s) => _buildActiveNoticeCard(s, isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(int totalScans, int totalViolations, int totalOpenNotices, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile('Total Scans', '$totalScans', AppTheme.secondaryBlue, isDark),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: _buildStatTile('Violations', '$totalViolations', AppTheme.criticalRed, isDark),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: _buildStatTile('Open Notices', '$totalOpenNotices', AppTheme.moderateAmber, isDark),
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, String count, Color accent, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.borderGrey),
      ),
      child: Column(
        children: [
          Text(count, style: AppTheme.headingLarge.copyWith(color: accent, fontSize: 22)),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.caption.copyWith(fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  /// GIGW 3.0 Standard Empty State for Scans List
  Widget _buildEmptyScansState(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: AppTheme.cardDecoration(isDark: isDark),
      child: Column(
        children: [
          Icon(Icons.qr_code_scanner, size: 48, color: isDark ? Colors.white38 : AppTheme.borderGrey),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            'No Inspections Recorded Yet',
            style: AppTheme.headingSmall.copyWith(
              color: isDark ? Colors.white70 : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Capture a packaged commodity photo with a standard coin to start automated compliance verification.',
            textAlign: TextAlign.center,
            style: AppTheme.caption,
          ),
        ],
      ),
    );
  }

  /// GIGW 3.0 Standard Empty State for Notices
  Widget _buildEmptyNoticesState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: AppTheme.cardDecoration(isDark: isDark),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppTheme.minorGreen, size: 28),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No Pending Statutory Notices', style: AppTheme.bodyBold),
                const SizedBox(height: 2),
                Text('All inspected commodities are either compliant or have resolved notices.', style: AppTheme.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanRowItem(BuildContext context, ScanResult scan, bool isDark) {
    final mfrText = scan.extractedFields.manufacturerName ??
        (scan.extractedFields.manufacturerAddress ?? 'Unidentified Entity');

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
        decoration: AppTheme.cardDecorationWithSeverity(scan.severity, isDark: isDark),
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
                    mfrText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: AppTheme.statusChipDecoration(scan.severity, isDark: isDark),
              child: Text(
                AppTheme.severityLabel(scan.severity),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.severityColor(scan.severity),
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

  Widget _buildActiveNoticeCard(ScanResult scan, bool isDark) {
    final mfr = scan.extractedFields.manufacturerName ?? 'Entity';
    final violationSummary = scan.violations.isNotEmpty
        ? scan.violations.first.ruleReference
        : 'Rule 6 Non-Compliance';

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: AppTheme.cardDecorationWithSeverity('MODERATE', isDark: isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('Notice #IN-${scan.scanId} • $mfr', style: AppTheme.bodyBold.copyWith(fontSize: 13)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: AppTheme.statusChipDecoration('MODERATE', isDark: isDark),
                child: const Text(
                  'NOTICE ISSUED',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.moderateAmber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Violation: $violationSummary', style: AppTheme.body.copyWith(fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: const [
              Icon(Icons.timer_outlined, size: 14, color: AppTheme.textSecondary),
              SizedBox(width: 4),
              Text('15 days statutory correction window (Jan Vishwas Act, 2026)', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
