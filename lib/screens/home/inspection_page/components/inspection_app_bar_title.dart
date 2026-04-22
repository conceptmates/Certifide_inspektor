import 'package:flutter/material.dart';

class InspectionAppBarTitle extends StatelessWidget {
  const InspectionAppBarTitle({
    super.key,
    required this.sectionTitle,
    required this.itemCount,
    required this.currentItemIndex,
    required this.sectionIcon,
    this.currentSection,
    this.totalSections,
  });

  final String sectionTitle;
  final int itemCount;
  final int currentItemIndex;
  final IconData sectionIcon;
  final int? currentSection;
  final int? totalSections;

  @override
  Widget build(BuildContext context) {
    final String subtitle;
    if (itemCount > 0 && currentSection != null && totalSections != null) {
      subtitle =
          'Field ${currentItemIndex + 1} of $itemCount · Section ${currentSection! + 1}/$totalSections';
    } else if (itemCount > 0) {
      subtitle = 'Field ${currentItemIndex + 1} of $itemCount';
    } else {
      subtitle = '';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              sectionIcon,
              color: const Color(0xFF448AFF),
              size: 16,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                sectionTitle,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
      ],
    );
  }
}
