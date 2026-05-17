import 'package:flutter/material.dart';

import '../car_spy_data.dart';

class CarSpyBottomNavBar extends StatelessWidget {
  const CarSpyBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.disabledIndices = const [],
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<int> disabledIndices;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: List.generate(carSpyBottomNavItems.length, (index) {
              final item = carSpyBottomNavItems[index];
              final isSelected = selectedIndex == index;
              final isDisabled = disabledIndices.contains(index);
              final Color iconColor = isDisabled
                  ? Colors.grey.shade300
                  : isSelected
                      ? const Color(0xFF1D4ED8)
                      : Colors.grey.shade400;
              return Expanded(
                child: GestureDetector(
                  onTap: isDisabled ? null : () => onTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFEFF6FF)
                          : const Color(0x00EFF6FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          color: iconColor,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: iconColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
