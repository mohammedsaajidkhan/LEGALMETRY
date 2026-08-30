// ==============================================================================
// LEGALMETRY — Main Application Entrypoint
// Track 5: UI / Reports (Person 5)
//
// Governing Standard: GIGW 3.0 / UI Design Context Document
// Configures MaterialApp, theme tokens (light/dark), and centralized route handling.
// ==============================================================================

import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/role_based_router.dart';
import 'capture/camera_screen.dart';
import 'dashboard/inspector_dashboard.dart';
import 'results/scan_results_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LegalMetrologyApp());
}

class LegalMetrologyApp extends StatelessWidget {
  const LegalMetrologyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LEGALMETRY Scanner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const RoleBasedRouter(),
      routes: {
        '/home': (context) => const RoleBasedRouter(),
        '/scan': (context) => const CameraScreen(),
        '/scan-results': (context) => const ScanResultsScreen(),
        '/scan-review': (context) => const ScanResultsScreen(),
        '/dashboard': (context) => const InspectorDashboard(),
      },
    );
  }
}
