import 'package:flutter/material.dart';

class FieldInfoContentCard extends StatelessWidget {
  const FieldInfoContentCard({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    required this.accentColor,
  });

  final IconData icon;
  final String title;
  final String text;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? accentColor.withAlpha(25)
            : accentColor.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withAlpha(76),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}
