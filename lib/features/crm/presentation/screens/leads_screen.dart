import 'package:flutter/material.dart';
import 'package:propconnect/core/constants/app_colors.dart';

class LeadsScreen extends StatelessWidget {
  const LeadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Active Leads')),
      body: const Center(child: Text('Client Leads Management (Mock)')),
    );
  }
}
