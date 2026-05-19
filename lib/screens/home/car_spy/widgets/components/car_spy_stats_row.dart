import 'package:flutter/material.dart';

import '../../car_spy_data.dart';

class CarSpyStatsRow extends StatelessWidget {
  const CarSpyStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.analytics_outlined,
            label: 'Market Pulse',
            value: '98.2%',
            description: 'Accuracy Rating in Appraisals',
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Icons.speed,
            label: 'Diagnostics',
            value: '1.4s',
            description: 'Mean Response Time',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.description,
  });

  final IconData icon;
  final String label;
  final String value;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CarSpyColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CarSpyColors.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: CarSpyColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(icon, color: CarSpyColors.primary, size: 18),
              ),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: CarSpyColors.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: CarSpyColors.onSurface,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 10,
              color: CarSpyColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
