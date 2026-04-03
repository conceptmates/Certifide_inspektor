import 'package:flutter/material.dart';

class CarSpyColors {
  static const Color primary = Color(0xFF0052CC);
  static const Color onSurface = Color(0xFF172B4D);
  static const Color surface = Color(0xFFF4F7FA);
  static const Color onSurfaceVariant = Color(0xFF44546F);
  static const Color outlineVariant = Color(0xFFD1D5DB);
}

class ServiceItemData {
  const ServiceItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isWarning = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isWarning;
}

class BottomNavItemData {
  const BottomNavItemData({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

const List<ServiceItemData> carSpyServices = [
  ServiceItemData(
    icon: Icons.add,
    title: 'New Car',
    subtitle: 'EXPLORE INVENTORY',
  ),
  ServiceItemData(
    icon: Icons.verified_outlined,
    title: 'Used Car',
    subtitle: 'VERIFIED LISTINGS',
  ),
  ServiceItemData(
    icon: Icons.fingerprint,
    title: 'RC Details',
    subtitle: 'OWNER & SPEC INFO',
  ),
  ServiceItemData(
    icon: Icons.policy_outlined,
    title: 'Challan',
    subtitle: 'PENDING DUES',
  ),
  ServiceItemData(
    icon: Icons.shield_outlined,
    title: 'Insurance',
    subtitle: 'RENEW POLICY',
  ),
  ServiceItemData(
    icon: Icons.toll_outlined,
    title: 'FASTag',
    subtitle: 'ACTION REQUIRED',
    isWarning: true,
  ),
];

const List<BottomNavItemData> carSpyBottomNavItems = [
  BottomNavItemData(icon: Icons.home_rounded, label: 'HOME'),
  BottomNavItemData(icon: Icons.history, label: 'HISTORY'),
  BottomNavItemData(icon: Icons.garage_outlined, label: 'GARAGE'),
  BottomNavItemData(icon: Icons.person_outline, label: 'PROFILE'),
];
