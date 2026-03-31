import 'package:flutter/material.dart';

import '../car_spy_data.dart';

class CarSpyHeroSection extends StatelessWidget {
  const CarSpyHeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 340,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBZZl9y6ns2Xt-xDgHnZ-9CKXJC_O0pSFYTKVYi-U5sBpT7tk8TLEuiD3xLAvM3SmEz6u_sYCm0RzFgI53Au0NCeinw2VZWWS9ekH1G0mY37Vpwf_NGMqkBgSdaUYmUJAZwfaugBXBEPZoV02Y9A3qTCqSu5e6EM8t5HZRAgoRgevFYjc7dAp5VivcDkq0GUH9C-wPulYkRL-V05pmonim1Qlovzfm6LDx6xrEl2h-WBuLH-R-kJ0EZ267kaQ9677JKy2sCPHDqUwQ',
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.shade300,
                    child: const Center(
                        child: CircularProgressIndicator.adaptive()),
                  );
                },
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0x22000000),
                      Color(0xCC000000),
                    ],
                    stops: [0.0, 0.4, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 28,
                left: 24,
                right: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: CarSpyColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: CarSpyColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: const Text(
                        'ADVANCED TECH',
                        style: TextStyle(
                          color: Color(0xFF60A5FA),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Self-\nInspection\nRedefined.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Execute high-precision diagnostics and visual\nappraisals through our proprietary kinetic\nblueprint scanner.',
                      style: TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.qr_code_scanner, size: 18),
                      label: const Text(
                        'Initialize Scan',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CarSpyColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                        shadowColor: CarSpyColors.primary.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
