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
              'CERTIFIDE',
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
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, Routes.profile),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline,
                  color: Color(0xFF1E40AF), size: 22),
            ),
          ),
        ),
      ],
    );
  }
}
