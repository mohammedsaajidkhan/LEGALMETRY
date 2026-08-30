// ==============================================================================
// LEGALMETRY — Camera Quality Gate HUD Overlay (Person 2 / Module 1.2)
// Track 2: Capture & Ingest
//
// Provides real-time visual feedback for blur, lighting, glare, and distance.
// ==============================================================================

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class QualityGateUi extends StatelessWidget {
  final bool isBlurry;
  final bool isTooDark;
  final bool isTooBright;
  final bool coinDetected;
  final String? warningMessage;

  const QualityGateUi({
    super.key,
    this.isBlurry = false,
    this.isTooDark = false,
    this.isTooBright = false,
    this.coinDetected = true,
    this.warningMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 60,
      left: 16,
      right: 16,
      child: Column(
        children: [
          // Quality Metric Badges Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIndicatorBadge(
                label: 'Focus',
                isOk: !isBlurry,
                okIcon: Icons.center_focus_strong,
                warnIcon: Icons.blur_on,
              ),
              const SizedBox(width: 8),
              _buildIndicatorBadge(
                label: 'Lighting',
                isOk: !isTooDark && !isTooBright,
                okIcon: Icons.wb_sunny_outlined,
                warnIcon: Icons.brightness_medium,
              ),
              const SizedBox(width: 8),
              _buildIndicatorBadge(
                label: 'Reference Coin',
                isOk: coinDetected,
                okIcon: Icons.monetization_on_outlined,
                warnIcon: Icons.error_outline,
              ),
            ],
          ),

          // Actionable Warning Alert Banner
          if (warningMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.moderateAmber),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.moderateAmber, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    warningMessage!,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIndicatorBadge({
    required String label,
    required bool isOk,
    required IconData okIcon,
    required IconData warnIcon,
  }) {
    final color = isOk ? AppTheme.compliantGreen : AppTheme.moderateAmber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isOk ? okIcon : warnIcon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
