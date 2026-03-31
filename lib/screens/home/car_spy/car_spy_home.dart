import 'package:flutter/material.dart';

import 'widgets/car_spy_bottom_nav_bar.dart';
import 'widgets/car_spy_content_sections.dart';
import 'widgets/car_spy_hero_section.dart';
import 'widgets/car_spy_top_app_bar.dart';

class CarSpyHome extends StatefulWidget {
  const CarSpyHome({super.key});

  @override
  State<CarSpyHome> createState() => _CarSpyHomeState();
}

class _CarSpyHomeState extends State<CarSpyHome> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      appBar: const CarSpyTopAppBar(),
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              CarSpyHeroSection(),
              SizedBox(height: 32),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CarSpyCoreServicesSection(),
                    SizedBox(height: 32),
                    CarSpyPendingReportCard(),
                    SizedBox(height: 24),
                    CarSpyStatsRow(),
                    SizedBox(height: 24),
                    CarSpyHeritageVaultCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CarSpyBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
