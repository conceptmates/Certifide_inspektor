import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../../constants/hive_constants.dart';
import '../../data/inspection_storage_model.dart';
import '../../routes/routes.dart';
import '../../widgets/fade_animation.dart';
import '../../widgets/menu_icon.dart';
import '../../providers/user_provider.dart';
import '../../providers/inspection_provider.dart';

class MainContent extends StatefulWidget {
  final VoidCallback onMenuTap;
  final bool isDrawerOpen;

  const MainContent({
    super.key,
    required this.onMenuTap,
    required this.isDrawerOpen,
  });
  @override
  _MainContentState createState() => _MainContentState();
}

class _MainContentState extends State<MainContent>
    with TickerProviderStateMixin {
  final _storage = FlutterSecureStorage();
  String _userName = 'User';
  late AnimationController rippleController;
  late AnimationController scaleController;
  late Animation<double> rippleAnimation;
  Box<InspectionStorageModel>? _inspectionBox;
  late Animation<double> scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initHive();
    _initializeAnimations();
    _loadUserName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<InspectionProvider>(context, listen: false)
            .loadInspections();
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
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
        _inspectionBox = Hive.box<InspectionStorageModel>(
          HiveConstants.INSPECTION_BOX,
        );
      }
    } catch (e) {
      print('Error initializing Hive: $e');
      // Try to recover from error
      await Hive.deleteBoxFromDisk(HiveConstants.INSPECTION_BOX);
      await Hive.initFlutter();
      _inspectionBox = await Hive.openBox<InspectionStorageModel>(
        HiveConstants.INSPECTION_BOX,
      );
    }
  }

  Future<bool> hasExistingInspection() async {
    try {
      if (!Hive.isBoxOpen(HiveConstants.INSPECTION_BOX)) {
        _inspectionBox = await Hive.openBox<InspectionStorageModel>(
          HiveConstants.INSPECTION_BOX,
        );
      }

      // Get current inspection data
      final existingData =
          _inspectionBox?.get(HiveConstants.CURRENT_INSPECTION_KEY);

      // Check if there's existing data, it's not completed, and has valid content
      if (existingData != null) {
        // First check if it's completed or submitted
        if (existingData.isCompleted ||
            existingData.status == 'submitted' ||
            existingData.status == 'offline') {
          return false; // Return false if inspection is completed or saved offline
        }

        // Check if the inspection has valid data
        bool hasValidData = existingData.itemValues.isNotEmpty ||
            existingData.itemImages.isNotEmpty ||
            existingData.itemRemarks.isNotEmpty;

        // Additional check: Ensure the inspection is not too old (e.g., more than 24 hours)
        if (hasValidData) {
          final inspectionTime = existingData.timestamp;
          final currentTime = DateTime.now();
          final timeDifference = currentTime.difference(inspectionTime);

          // If inspection is less than 24 hours old, consider it existing
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

      final hasExisting = await hasExistingInspection();
      print('Has existing inspection: $hasExisting');

      if (!mounted) return;

      if (hasExisting) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Continue Previous Inspection?'),
              content: const Text(
                'Would you like to continue your previous inspection or start a new one?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToInspection(true);
                  },
                  child: const Text('Start New'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToInspection(false);
                  },
                  child: const Text('Continue Previous'),
                ),
              ],
            );
          },
        );
      } else {
        _navigateToInspection(true);
      }
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
      // For new inspections, go to vehicle details form first
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
      // For continuing inspections, go directly to inspection screen
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
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 3,
        shadowColor: Colors.black12,
        color: Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 18, color: Colors.grey[400]),
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
      child: Consumer2<UserProvider, InspectionProvider>(
        builder: (context, userProvider, inspectionProvider, child) {
          final pendingCount = inspectionProvider.inspections.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with menu and greeting
                FadeAnimation(
                  1.0,
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                        children: [
                        NeumorphicAnimatedIcon(
                          onTap: widget.onMenuTap,
                          isDrawerOpen: widget.isDrawerOpen,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                            _getGreeting(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                            _userName,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            ),
                          ],
                          ),
                        ),
                        Badge(
                          backgroundColor: Colors.red,
                          label: Text('3'),
                          child: IconButton(
                          onPressed: () {
                            // Handle notification tap
                          },
                          icon: Icon(
                            Icons.notifications_outlined,
                            color: Colors.blue[600],
                            size: 24,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.blue.withValues(alpha: 0.1),
                            padding: const EdgeInsets.all(12),
                            shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Main action - Start Inspection
                FadeAnimation(
                  1.4,
                  Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A73E8), Color(0xFF1557B0)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A73E8).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: _handleInspectionTap,
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Start Inspection',
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Begin your quality control process',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white
                                            .withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedBuilder(
                                animation: rippleAnimation,
                                builder: (context, child) => Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                  child: Transform.scale(
                                    scale: rippleAnimation.value / 62.5,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white
                                            .withValues(alpha: 0.25),
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Actions Section
                FadeAnimation(
                  1.6,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      _buildQuickActionCard(
                        icon: Icons.handshake_outlined,
                        title: 'Expert Opinion',
                        subtitle: 'Get expert reviews on inspections',
                        color: Color(0xFF6366F1),
                        onTap: () {
                          // Navigate to history
                        },
                      ),
                      _buildQuickActionCard(
                        icon: Icons.bookmark_added_outlined,
                        title: 'Inspection Booking',
                        subtitle: 'Get your car inspected by Professionals',
                        color: Color(0xFF6366F1),
                        onTap: _launchBookingWebsite,
                      ),
                      if (pendingCount > 0)
                        _buildQuickActionCard(
                          icon: Icons.cloud_upload_rounded,
                          title: 'Sync Pending ($pendingCount)',
                          subtitle: 'Upload pending inspections',
                          color: Color(0xFFF59E0B),
                          onTap: () async {
                            await inspectionProvider.loadInspections();
                          },
                        ),
                      _buildQuickActionCard(
                        icon: Icons.replay,
                        title: 'Recent Inspections',
                        subtitle: 'View your recent inspection history',
                        color: Color(0xFF6366F1),
                        onTap: () {
                          // Navigate to history
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
