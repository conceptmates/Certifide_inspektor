import 'package:flutter/material.dart';

class InspectionProgressHeader extends StatelessWidget {
  const InspectionProgressHeader({
    super.key,
    required this.currentSection,
    required this.totalSections,
  });

  final int currentSection;
  final int totalSections;

  @override
  Widget build(BuildContext context) {
    final progress = totalSections > 0 ? (currentSection + 1) / totalSections : 0.0;
    return LinearProgressIndicator(
      value: progress,
      minHeight: 3,
      backgroundColor: const Color(0xFFE4E7EB),
      color: const Color(0xFF448AFF),
    );
  }
}
