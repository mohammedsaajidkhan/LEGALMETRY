// ==============================================================================
// LEGALMETRY — Camera Capture Screen (Person 2 / Module 1.2)
// Track 2: Capture & Ingest
//
// Features:
// - Camera preview with ₹10 coin alignment guide overlay (CoinCalibrationUi)
// - Category tag with direct picker navigation (CategorySelectorScreen)
// - 48px touch targets and GIGW 3.0 accessibility standards
// ==============================================================================

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/theme/app_theme.dart';
import 'coin_calibration_ui.dart';
import '../category/category_selector_screen.dart';

class CameraScreen extends StatefulWidget {
  final String category;

  const CameraScreen({super.key, this.category = 'General'});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isCapturing = false;
  String? _error;
  late String _currentCategory;

  @override
  void initState() {
    super.initState();
    _currentCategory = widget.category;
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() {
        _error = "Camera permission is required to scan a product.";
        _isInitializing = false;
      });
      return;
    }

    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) return;
      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _error = "Could not start the camera. Please try again.";
        _isInitializing = false;
      });
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final photo = await controller.takePicture();
      final dir = await getApplicationDocumentsDirectory();
      final savedPath =
          '${dir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(photo.path).copy(savedPath);

      if (!mounted) return;

      Navigator.of(context).pushNamed(
        '/scan-review',
        arguments: {'imagePath': savedPath, 'category': _currentCategory},
      );
    } catch (e) {
      setState(() {
        _error = "Capture failed. Please try again.";
      });
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _controller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error ?? "Camera unavailable.",
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),

          // Coin Reference Calibration Reticle Overlay
          const CoinCalibrationUi(),

          // Category Selector Chip (Top-Left)
          Positioned(
            top: 48,
            left: 16,
            child: Semantics(
              label: 'Selected category: $_currentCategory. Tap to change.',
              button: true,
              child: InkWell(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CategorySelectorScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryNavy.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.category_outlined, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        _currentCategory,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Shutter Button (Bottom-Center)
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Semantics(
                label: 'Capture product photo',
                button: true,
                child: GestureDetector(
                  onTap: _isCapturing ? null : _capture,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isCapturing
                          ? AppTheme.primaryNavy.withOpacity(0.4)
                          : Colors.white,
                      border: Border.all(color: AppTheme.primaryNavy, width: 4),
                    ),
                    child: _isCapturing
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}