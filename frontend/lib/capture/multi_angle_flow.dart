// ==============================================================================
// LEGALMETRY — Multi-Angle Capture Flow Controller (Person 2 / Module 1.3)
// Track 2: Capture & Ingest
//
// Manages multi-angle shot capture for cylindrical or curved packages (e.g. bottles, cans).
// ==============================================================================

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class CapturedAngle {
  final int index;
  final String imagePath;
  final double qualityScore;
  final DateTime timestamp;

  const CapturedAngle({
    required this.index,
    required this.imagePath,
    required this.qualityScore,
    required this.timestamp,
  });
}

class MultiAngleFlowController extends ChangeNotifier {
  final int maxAngles;
  final List<CapturedAngle> _angles = [];

  MultiAngleFlowController({this.maxAngles = 3});

  List<CapturedAngle> get angles => List.unmodifiable(_angles);
  int get currentAngleIndex => _angles.length + 1;
  bool get isComplete => _angles.length >= maxAngles;

  void addAngle(String imagePath, {double qualityScore = 0.90}) {
    if (_angles.length < maxAngles) {
      _angles.add(
        CapturedAngle(
          index: _angles.length + 1,
          imagePath: imagePath,
          qualityScore: qualityScore,
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }

  void reset() {
    _angles.clear();
    notifyListeners();
  }
}

class MultiAngleIndicatorUi extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const MultiAngleIndicatorUi({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.rotate_right, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            'Angle $currentStep of $totalSteps',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
