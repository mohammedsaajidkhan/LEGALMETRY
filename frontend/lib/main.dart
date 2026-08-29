// frontend/lib/main.dart [Person 5 owns -- the app entrypoint]
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/role_based_router.dart';

void main() {
  runApp(const LegalMetrologyApp());
}

class LegalMetrologyApp extends StatelessWidget {
  const LegalMetrologyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LEGALMETRY Scanner',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const RoleBasedRouter(),
    );
  }
}
