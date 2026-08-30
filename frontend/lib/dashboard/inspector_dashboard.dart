// ==============================================================================
// LEGALMETRY — Inspector Dashboard Screen (Screen B6 / 80% Target Scope)
// Track 5: UI / Reports (Person 5)
//
// Governing Standard: GIGW 3.0 / UI Design Context Document B6 & Part C
// Features:
// 1. Inspector's own scan history with severity left borders.
// 2. Simple risk-sorted manufacturer list (ranked worst-first by dynamic MHI).
// 3. Dynamic Jan Vishwas improvement notices.
// 4. Zero hardcoded mock data — displays GIGW 3.0 empty states on clean install.
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

class _InspectorDashboardState extends State<InspectorDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isHindi = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 350));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scans = ScanStore.instance.scans;
    final totalScans = ScanStore.instance.totalScans;
    final totalViolations = ScanStore.instance.totalViolations;
    final totalOpenNotices = ScanStore.instance.totalOpenNotices;
    final manufacturers = ScanStore.instance.riskSortedManufacturers;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isHindi ? 'निरीक्षक डैशबोर्ड' : 'Inspector Dashboard',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              _isHindi ? 'अनुपालन इतिहास एवं निर्माता जोखिम सूची' : 'Scan History & Manufacturer Risk Rankings',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          // Persistent Language Toggle (GIGW 3.0 Standard)
          TextButton.icon(
            onPressed: () => setState(() => _isHindi = !_isHindi),
            icon: const Icon(Icons.translate, color: Colors.white, size: 18),
            label: Text(
              _isHindi ? 'EN' : 'हिन्दी',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _handleRefresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3.0,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              icon: const Icon(Icons.history, size: 18),
              text: _isHindi ? 'स्कैन इतिहास ($totalScans)' : 'My Scans ($totalScans)',
            ),
            Tab(
              icon: const Icon(Icons.analytics_outlined, size: 18),
              text: _isHindi ? 'निर्माता जोखिम (${manufacturers.length})' : 'Manufacturer Risk (${manufacturers.length})',
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Column(
          children: [
            // Top Dynamic Stat Cards Row
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, AppTheme.spacing16, AppTheme.spacing16, AppTheme.spacing8),
              child: _buildStatsRow(totalScans, totalViolations, manufacturers.length, totalOpenNotices, isDark),
            ),

            // Tab Views for Scan History and Manufacturer Risk
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Inspector's Own Scan History & Active Notices
                  _buildScanHistoryTab(scans, isDark),

                  // Tab 2: Simple Risk-Sorted Manufacturer List (Worst-First)
                  _buildManufacturerRiskTab(manufacturers, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Summary Stats Row (Real Dynamic Metrics)
  // ---------------------------------------------------------------------------
  Widget _buildStatsRow(int totalScans, int totalViolations, int totalMfrs, int totalNotices, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(_isHindi ? 'कुल स्कैन' : 'Total Scans', '$totalScans', AppTheme.secondaryBlue, isDark),
        ),
        const SizedBox(width: AppTheme.spacing8),
        Expanded(
          child: _buildStatTile(_isHindi ? 'उल्लंघन' : 'Violations', '$totalViolations', AppTheme.criticalRed, isDark),
        ),
        const SizedBox(width: AppTheme.spacing8),
        Expanded(
          child: _buildStatTile(_isHindi ? 'निर्माता' : 'Entities', '$totalMfrs', AppTheme.primaryNavy, isDark),
        ),
        const SizedBox(width: AppTheme.spacing8),
        Expanded(
          child: _buildStatTile(_isHindi ? 'सक्रिय नोटिस' : 'Notices', '$totalNotices', AppTheme.moderateAmber, isDark),
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, String count, Color accent, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.borderGrey),
      ),
      child: Column(
        children: [
          Text(count, style: AppTheme.headingLarge.copyWith(color: accent, fontSize: 20)),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.caption.copyWith(fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 1: Scan History & Active Notices
  // ---------------------------------------------------------------------------
  Widget _buildScanHistoryTab(List<ScanResult> scans, bool isDark) {
    if (scans.isEmpty) {
      return _buildEmptyScansState(isDark);
    }

    final activeNotices = scans.where((s) => s.hasViolations).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section: Recent Inspections
          Text(
            _isHindi ? 'हाल ही में किए गए स्कैन' : 'Recent Inspections',
            style: AppTheme.headingMedium.copyWith(
              color: isDark ? Colors.white : AppTheme.primaryNavy,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          ...scans.map((scan) => _buildScanRowItem(scan, isDark)),

          // Section: Active Jan Vishwas Notices (if any)
          if (activeNotices.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacing20),
            Text(
              _isHindi ? 'सक्रिय वैधानिक सुधार नोटिस (जन विश्वास अधिनियम, 2026)' : 'Active Improvement Notices (Jan Vishwas Act, 2026)',
              style: AppTheme.headingMedium.copyWith(
                color: isDark ? Colors.white : AppTheme.primaryNavy,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            ...activeNotices.map((s) => _buildActiveNoticeCard(s, isDark)),
          ],
        ],
      ),
    );
  }

  Widget _buildScanRowItem(ScanResult scan, bool isDark) {
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

  // ---------------------------------------------------------------------------
  // Tab 2: Simple Risk-Sorted Manufacturer List (Worst-First / Lowest MHI)
  // ---------------------------------------------------------------------------
  Widget _buildManufacturerRiskTab(List<ManufacturerRiskSummary> manufacturers, bool isDark) {
    if (manufacturers.isEmpty) {
      return _buildEmptyRiskState(isDark);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Subtitle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isHindi ? 'जोखिम-आधारित रैंकिंग (निम्नतम MHI पहले)' : 'Risk-Ranked Entities (Worst-First)',
                style: AppTheme.headingMedium.copyWith(
                  color: isDark ? Colors.white : AppTheme.primaryNavy,
                  fontSize: 15,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  'MHI Metric',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.secondaryBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),

          // Render each risk summary card
          ...manufacturers.map((mfr) => _buildManufacturerRiskCard(mfr, isDark)),
        ],
      ),
    );
  }

  Widget _buildManufacturerRiskCard(ManufacturerRiskSummary mfr, bool isDark) {
    final mhi = mfr.mhiScore;
    final Color mhiColor = mhi >= 80
        ? AppTheme.compliantGreen
        : (mhi >= 50 ? AppTheme.moderateAmber : AppTheme.criticalRed);
    final String riskTier = mhi >= 80 ? 'LOW RISK' : (mhi >= 50 ? 'MEDIUM RISK' : 'HIGH RISK');

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing10),
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border(
          left: BorderSide(color: mhiColor, width: 4.0),
          top: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.borderGrey),
          right: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.borderGrey),
          bottom: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.borderGrey),
        ),
      ),
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
                    Text(mfr.name, style: AppTheme.bodyBold.copyWith(fontSize: 14)),
                    if (mfr.entityId != null) ...[
                      const SizedBox(height: 2),
                      Text('Entity ID: ${mfr.entityId}', style: AppTheme.caption.copyWith(fontSize: 11)),
                    ],
                  ],
                ),
              ),
              // MHI Score Gauge Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: mhiColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: mhiColor, width: 1.2),
                ),
                child: Column(
                  children: [
                    Text(
                      '${mhi.toStringAsFixed(0)} / 100',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: mhiColor),
                    ),
                    Text(riskTier, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: mhiColor)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: AppTheme.spacing16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Scans: ${mfr.totalScans} • Violations: ${mfr.totalViolations}',
                style: AppTheme.caption.copyWith(fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  if (mfr.criticalCount > 0)
                    _buildMiniBadge('${mfr.criticalCount} Critical', AppTheme.criticalRed),
                  if (mfr.moderateCount > 0) ...[
                    const SizedBox(width: 4),
                    _buildMiniBadge('${mfr.moderateCount} Moderate', AppTheme.moderateAmber),
                  ],
                  if (mfr.minorCount > 0) ...[
                    const SizedBox(width: 4),
                    _buildMiniBadge('${mfr.minorCount} Minor', AppTheme.minorGreen),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // GIGW 3.0 Standard Empty States
  // ---------------------------------------------------------------------------
  Widget _buildEmptyScansState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner, size: 56, color: isDark ? Colors.white38 : AppTheme.borderGrey),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              _isHindi ? 'कोई निरीक्षण रिकॉर्ड नहीं मिला' : 'No Inspections Recorded Yet',
              style: AppTheme.headingMedium.copyWith(
                color: isDark ? Colors.white : AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              _isHindi
                  ? 'निरीक्षण शुरू करने के लिए विधिक मापविज्ञान स्कैनर द्वारा उत्पाद की तस्वीर लें।'
                  : 'Capture or upload a packaged commodity photo with a standard coin to record inspection findings.',
              textAlign: TextAlign.center,
              style: AppTheme.caption.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRiskState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.query_stats, size: 56, color: isDark ? Colors.white38 : AppTheme.borderGrey),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              _isHindi ? 'कोई निर्माता जोखिम डेटा उपलब्ध नहीं' : 'No Manufacturer Risk Data',
              style: AppTheme.headingMedium.copyWith(
                color: isDark ? Colors.white : AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              _isHindi
                  ? 'जैसे ही आप उत्पादों का निरीक्षण करेंगे, विधिक स्वास्थ्य सूचकांक (MHI) यहां स्वचालित रूप से परिकलित होगा।'
                  : 'As you inspect products, the Manufacturer Health Index (MHI) will dynamically calculate and rank entities here worst-first.',
              textAlign: TextAlign.center,
              style: AppTheme.caption.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
