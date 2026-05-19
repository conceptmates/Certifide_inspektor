import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/hive_constants.dart';
import '../../data/inspection_storage_model.dart';
import '../../providers/inspection_provider.dart';
import '../../routes/routes.dart';
import '../../widgets/fade_animation.dart';

class MainContent extends ConsumerStatefulWidget {
  const MainContent({super.key});

  @override
  ConsumerState<MainContent> createState() => _MainContentState();
}

class _MainContentState extends ConsumerState<MainContent>
    with TickerProviderStateMixin {
  final _storage = FlutterSecureStorage();
  String _userName = 'User';
  late AnimationController rippleController;
  late AnimationController scaleController;
  late Animation<double> rippleAnimation;
  late Animation<double> scaleAnimation;
  Box<InspectionStorageModel>? _inspectionBox;

  // Design tokens
  static const _primary = Color(0xFF0F172A);
  static const _accent = Color(0xFF3B82F6);
  static const _accentLight = Color(0xFFEFF6FF);
  static const _surface = Color(0xFFF8FAFC);
  static const _cardBg = Colors.white;
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _indigo = Color(0xFF6366F1);
  static const _indigoLight = Color(0xFFEEF2FF);

  @override
  void initState() {
    super.initState();
    _initHive();
    _initializeAnimations();
    _loadUserName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(inspectionNotifierProvider.notifier).loadInspections();
      }
    });
  }

  @override
  void dispose() {
    rippleController.dispose();
    scaleController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    try {
      final userData = await _storage.read(key: 'user_data');
      if (userData != null) {
        final decodedData = json.decode(userData);
        if (mounted) {
          setState(() {
            _userName = decodedData['name'] ?? 'User';
          });
        }
      }
    } catch (e) {
      print('Error loading user name: $e');
    }
  }

  void _initializeAnimations() {
    rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          scaleController.reverse();
        }
      });

    rippleAnimation =
        Tween<double>(begin: 60.0, end: 65.0).animate(rippleController)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              rippleController.reverse();
            } else if (status == AnimationStatus.dismissed) {
              rippleController.forward();
            }
          });

    scaleAnimation =
        Tween<double>(begin: 1.0, end: 1.2).animate(scaleController);

    rippleController.forward();
  }

  Future<void> _initHive() async {
    try {
      if (!Hive.isBoxOpen(HiveConstants.INSPECTION_BOX)) {
        await Hive.initFlutter();

        if (!Hive.isAdapterRegistered(0)) {
          Hive.registerAdapter(InspectionStorageModelAdapter());
        }

        _inspectionBox = await Hive.openBox<InspectionStorageModel>(
          HiveConstants.INSPECTION_BOX,
        );
      } else {
        _inspectionBox =
            Hive.box<InspectionStorageModel>(HiveConstants.INSPECTION_BOX);
      }
    } catch (e) {
      print('Error initializing Hive: $e');
      await Hive.deleteBoxFromDisk(HiveConstants.INSPECTION_BOX);
      await Hive.initFlutter();
      _inspectionBox = await Hive.openBox<InspectionStorageModel>(
        HiveConstants.INSPECTION_BOX,
      );
    }
  }

  // Check if there's an existing unfinished inspection
  Future<bool> hasExistingInspection() async {
    try {
      if (_inspectionBox == null || !(_inspectionBox?.isOpen ?? false)) {
        await _initHive();
      }

      final existingData =
          _inspectionBox?.get(HiveConstants.CURRENT_INSPECTION_KEY);

      if (existingData != null) {
        // Skip if already completed or submitted
        if (existingData.isCompleted ||
            existingData.status == 'submitted' ||
            existingData.status == 'offline') {
          return false;
        }

        // Check if there's any meaningful data saved
        bool hasValidData = existingData.itemValues.isNotEmpty ||
            existingData.itemImages.isNotEmpty ||
            existingData.itemRemarks.isNotEmpty ||
            existingData.itemVideos.isNotEmpty ||
            existingData.itemAudios.isNotEmpty ||
            existingData.itemFiles.isNotEmpty ||
            (existingData.multiImages?.isNotEmpty ?? false);

        if (hasValidData) {
          // Check if the inspection is less than 24 hours old
          final inspectionTime = existingData.timestamp;
          final currentTime = DateTime.now();
          final timeDifference = currentTime.difference(inspectionTime);
          return timeDifference.inHours < 24;
        }
      }
      return false;
    } catch (e) {
      print('Error checking existing inspection: $e');
      return false;
    }
  }

  Future<void> _handleInspectionTap() async {
    try {
      scaleController.forward();

      if (!mounted) return;

      // Always clear any stale session and start fresh.
      if (_inspectionBox?.isOpen ?? false) {
        await _inspectionBox?.delete(HiveConstants.CURRENT_INSPECTION_KEY);
      }

      if (!mounted) return;

      _navigateToInspection(true);
    } catch (e) {
      print('Error handling inspection tap: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error starting inspection. Please try again.'),
          ),
        );
      }
    }
  }

  void _navigateToInspection(bool isNew) {
    if (isNew) {
      Navigator.pushNamed(
        context,
        Routes.vehicleDetails,
        arguments: {'isNew': isNew},
      ).then((_) {
        if (mounted) {
          setState(() {});
        }
      });
    } else {
      Navigator.pushNamed(
        context,
        Routes.inspection,
        arguments: {'isNew': isNew},
      ).then((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  Future<void> _launchBookingWebsite() async {
    final Uri url = Uri.parse('https://bookings.certifide.in/');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error opening booking website'),
          ),
        );
      }
    }
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          splashColor: color.withValues(alpha: 0.08),
          highlightColor: color.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: _surface,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              FadeAnimation(
                1.0,
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          _userName.isNotEmpty
                              ? _userName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome back',
                            style: TextStyle(
                              fontSize: 13,
                              color: _textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _userName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Notification bell
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: _textPrimary,
                              size: 22,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                '3',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Start Inspection Hero Card ───────────────────────────
              FadeAnimation(
                1.3,
                GestureDetector(
                  onTap: _handleInspectionTap,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1E3A5F),
                          Color(0xFF1A73E8),
                          Color(0xFF2563EB),
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF1A73E8).withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          // Decorative circle top-right
                          Positioned(
                            top: -30,
                            right: -20,
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -20,
                            right: 40,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                          ),
                          // Content
                          Padding(
                            padding: const EdgeInsets.all(26),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          'QUALITY CONTROL',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Start\nInspection',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          height: 1.15,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Begin your quality check process',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white
                                              .withValues(alpha: 0.75),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Animated play button
                                AnimatedBuilder(
                                  animation: rippleAnimation,
                                  builder: (context, child) => SizedBox(
                                    width: 72,
                                    height: 72,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Outer pulse ring
                                        Container(
                                          width: rippleAnimation.value * 1.1,
                                          height: rippleAnimation.value * 1.1,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white
                                                .withValues(alpha: 0.08),
                                          ),
                                        ),
                                        // Inner button
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white
                                                .withValues(alpha: 0.18),
                                            border: Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.4),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.play_arrow_rounded,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Section heading ──────────────────────────────────────
              FadeAnimation(
                1.5,
                const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),

              // ── Action Cards ─────────────────────────────────────────
              FadeAnimation(
                1.6,
                Column(
                  children: [
                    _buildQuickActionCard(
                      icon: Icons.handshake_outlined,
                      title: 'Expert Opinion',
                      subtitle: 'Get expert reviews on inspections',
                      color: _indigo,
                      onTap: () {},
                    ),
                    _buildQuickActionCard(
                      icon: Icons.bookmark_added_outlined,
                      title: 'Inspection Booking',
                      subtitle: 'Get your car inspected by Professionals',
                      color: _accent,
                      onTap: _launchBookingWebsite,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
