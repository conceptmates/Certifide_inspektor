import 'package:flutter/material.dart';

class InspectionAppBarTitle extends StatelessWidget {
  const InspectionAppBarTitle({
    super.key,
    required this.sectionTitle,
    required this.itemCount,
    required this.currentItemIndex,
    required this.sectionIcon,
  });

  final String sectionTitle;
  final int itemCount;
  final int currentItemIndex;
  final IconData sectionIcon;

  @override
  Widget build(BuildContext context) {
    final subtitleColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.white.withAlpha(204);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                sectionIcon,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                sectionTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (itemCount > 0)
          Padding(
            padding: const EdgeInsets.only(left: 40, top: 2),
            child: Text(
              'Item ${currentItemIndex + 1} of $itemCount',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: subtitleColor,
              ),
            ),
          ),
      ],
    );
  }
}
