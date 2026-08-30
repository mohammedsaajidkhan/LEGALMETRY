// ==============================================================================
// LEGALMETRY — Coin Reticle Calibration Overlay (Person 2 / Module 1.3b)
// Track 2: Capture & Ingest
//
// Displays circular reference guide overlay for aligning the ₹10 (27mm) coin.
// ==============================================================================

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class CoinCalibrationUi extends StatelessWidget {
  final bool isCalibrated;
  final String coinDescription;

  const CoinCalibrationUi({
    super.key,
    this.isCalibrated = true,
    this.coinDescription = 'Place standard ₹10 (27mm) coin beside label',
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // Corner Alignment Brackets
          Center(
            child: Container(
              width: 280,
              height: 380,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white38, width: 1.5),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
          ),

          // Dedicated Coin Guide Reticle (Bottom-Right)
          Positioned(
            bottom: 120,
            right: 32,
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCalibrated ? AppTheme.compliantGreen : AppTheme.moderateAmber,
                      width: 2.0,
                    ),
                    color: (isCalibrated ? AppTheme.compliantGreen : AppTheme.moderateAmber).withOpacity(0.15),
                  ),
                  child: Center(
                    child: Text(
                      '₹10\nCOIN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isCalibrated ? AppTheme.compliantGreen : AppTheme.moderateAmber,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text(
                    isCalibrated ? '27.0 mm' : 'Align Coin',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
