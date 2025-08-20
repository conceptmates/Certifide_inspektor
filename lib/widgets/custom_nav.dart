import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final isAdmin = userProvider.isAdmin();
        final navItems = isAdmin ? _getAdminNavItems() : _getUserNavItems();
        return _buildNavBar(context, navItems);
      },
    );
  }

  List<_NavItem> _getAdminNavItems() {
    return [
      _NavItem(
        index: 0,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: 'Home',
      ),
      _NavItem(
        index: 1,
        icon: Icons.history_outlined,
        selectedIcon: Icons.history,
        label: 'History',
      ),
      // _NavItem(
      //   index: 2,
      //   icon: Icons.attach_money_sharp,
      //   selectedIcon: Icons.attach_money_sharp,
      //   label: 'Credits',
      // ),
      // _NavItem(
      //   index: 3,
      //   icon: Icons.approval_outlined,
      //   selectedIcon: Icons.approval,
      //   label: 'Approvals',
      // ),
      _NavItem(
        index: 2,
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: 'Profile',
      ),
    ];
  }

  List<_NavItem> _getUserNavItems() {
    return [
      _NavItem(
        index: 0,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: 'Home',
      ),
      _NavItem(
        index: 1,
        icon: Icons.history_outlined,
        selectedIcon: Icons.history,
        label: 'History',
      ),
      _NavItem(
        index: 2,
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: 'Profile',
      ),
    ];
  }

  Widget _buildNavBar(BuildContext context, List<_NavItem> items) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(35),
              color: colorScheme.surface.withOpacity(0.9),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surface.withOpacity(0.9),
                  colorScheme.surfaceVariant.withOpacity(0.9),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: items
                  .map((item) => Expanded(
                        child: _buildNavItem(context, item),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, _NavItem item) {
    final isSelected = selectedIndex == item.index;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => onItemSelected(item.index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: Icon(
                isSelected ? item.selectedIcon : item.icon,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface.withOpacity(0.7),
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.7),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final int index;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({
    required this.index,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
