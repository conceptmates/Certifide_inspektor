import 'package:certifide_openapp/routes/routes.dart';
import 'package:flutter/material.dart';

class CarSpyTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CarSpyTopAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64,
      elevation: 1,
      scrolledUnderElevation: 1,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shadowColor: Colors.blueGrey.withOpacity(0.1),
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.speed, color: Colors.blue.shade700, size: 24),
            const SizedBox(width: 8),
            const Text(
              'CARSPY',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E40AF),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline, color: Color(0xFF1E40AF)),
          onPressed: () => Navigator.pushNamed(context, Routes.profile),
          tooltip: 'Profile',
        ),
      ],
    );
  }
}
