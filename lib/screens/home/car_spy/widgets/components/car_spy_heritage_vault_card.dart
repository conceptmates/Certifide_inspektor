import 'package:flutter/material.dart';

import '../../car_spy_data.dart';
import '../../../../../constants/const.dart';

class CarSpyHeritageVaultCard extends StatelessWidget {
  const CarSpyHeritageVaultCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              carSpyHeritageVault,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xF5FFFFFF),
                    Color(0x33FFFFFF),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'The Heritage\nVault',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: CarSpyColors.onSurface,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Explore classic car valuations\nand preservation metrics.',
                    style: TextStyle(
                      fontSize: 12,
                      color: CarSpyColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'BROWSE ARCHIVE',
                        style: TextStyle(
                          color: CarSpyColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.open_in_new,
                        color: CarSpyColors.primary,
                        size: 14,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
