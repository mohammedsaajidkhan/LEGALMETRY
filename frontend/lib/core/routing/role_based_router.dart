// ==============================================================================
// LEGALMETRY — Role-Based Navigation Router (Section A5)
// Track 5: UI / Reports (Person 5)
//
// Governing Standard: GIGW 3.0 / UI Design Context Document Section A5
// Provides Inspector Bottom Navigation Bar and supervisory role routing.
// ==============================================================================

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../capture/camera_screen.dart';
import '../../dashboard/inspector_dashboard.dart';
import '../../results/scan_results_screen.dart';

class RoleBasedRouter extends StatefulWidget {
  const RoleBasedRouter({super.key});

  @override
  State<RoleBasedRouter> createState() => _RoleBasedRouterState();
}

class _RoleBasedRouterState extends State<RoleBasedRouter> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CameraScreen(),
    const ScanResultsScreen(),
    const InspectorDashboard(),
    const _ProfilePlaceholderScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        selectedItemColor: isDark ? AppTheme.secondaryBlue : AppTheme.primaryNavy,
        unselectedItemColor: AppTheme.textSecondary,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            activeIcon: Icon(Icons.qr_code_scanner, size: 26),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check_outlined),
            activeIcon: Icon(Icons.fact_check, size: 26),
            label: 'Verdict',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard, size: 26),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person, size: 26),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _ProfilePlaceholderScreen extends StatelessWidget {
  const _ProfilePlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Inspector Profile')),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              decoration: AppTheme.cardDecoration(isDark: isDark),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primaryNavy,
                    child: Icon(Icons.badge, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: AppTheme.spacing16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Inspector R. Sharma', style: AppTheme.headingMedium.copyWith(
                          color: isDark ? Colors.white : AppTheme.primaryNavy,
                        )),
                        const SizedBox(height: 2),
                        const Text('Zone: North District • ID: LM-DL-2024', style: AppTheme.caption),
                        const SizedBox(height: 2),
                        const Text('Department of Legal Metrology', style: AppTheme.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out successfully.')),
                  );
                },
                style: AppTheme.secondaryButtonStyle,
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
