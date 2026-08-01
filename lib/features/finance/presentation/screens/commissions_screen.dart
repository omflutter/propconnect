import 'package:flutter/material.dart';
import 'package:propconnect/core/constants/app_colors.dart';

class CommissionsScreen extends StatelessWidget {
  const CommissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Commissions & Earnings')),
      body: const Center(child: Text('Detailed Commission Breakdown (Mock)')),
    );
  }
}
