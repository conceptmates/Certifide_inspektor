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
      actions: const [_ProfileAvatar()],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFFEFF3FA),
        foregroundImage: const NetworkImage(
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDzwV3ne_WATyw86rC4SLc4GWf_5rbqcNUGriG8tR1oGL1uHipDsmMydqzuUQSwlwKPwNIaH24W9fCl4kgqoDW_GC7TvUedu9P3624E-CP5eovcYBCF4IJyqKhfOAQ07zJCg_jkxruwia--xmfaVDnnb0usyU4KL2nwbqbXTuVJDwNDBzskPJ29fVC8Y7rJMs0GZVR_gTP_VAM09EkKhlgUYAYygnY8ZcCvfWbeYIyjLXz1t1bUJdG5L6-VFj-IaRvWiNT6kQEFiSU',
        ),
        child: const Icon(Icons.person, color: Color(0xFF1E40AF)),
      ),
    );
  }
}
