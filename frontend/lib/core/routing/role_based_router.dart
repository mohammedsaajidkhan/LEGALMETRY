// ============ PERSON 5 ============
// Role based router (Inspector, Officer, Controller, Director)
import 'package:flutter/material.dart';
import '../../capture/camera_screen.dart';

class RoleBasedRouter extends StatelessWidget {
  const RoleBasedRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return const CameraScreen(category: 'General');
  }
}
