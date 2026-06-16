import 'dart:developer';

import 'package:flutter/material.dart';

import '../screens/history/history_page.dart';
import '../services/api_services.dart';
import '../utils/user_role.dart';
import 'menu_icon.dart';

class DrawerMenu extends StatefulWidget {
  final AnimationController drawerController;
  final double drawerWidth;
  final VoidCallback toggleDrawer;
  final bool isDrawerOpen;

  const DrawerMenu({
    super.key,
    required this.drawerController,
    required this.drawerWidth,
    required this.toggleDrawer,
    required this.isDrawerOpen,
  });

  @override
  State<DrawerMenu> createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  int availableTokens = 0;
  int usedTokens = 0;
  bool isLoading = true;
  bool isInspector = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final roles = await UserRole.getUserRoles();
    if (mounted) {
      setState(() {
        isInspector = roles.contains(UserRole.INSPECTOR);
      });
      if (isInspector) {
        _loadTokenBalance();
      }
    }
  }

  Future<void> _loadTokenBalance() async {
    if (!mounted) return;
    try {
      final userId = await ApiService.getUserId();
      if (userId != null) {
        final result = await ApiService.getTokenBalance(userId);
        if (result['success'] && mounted) {
          setState(() {
            availableTokens = result['data']['available_tokens'];
            usedTokens = result['data']['used_tokens'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      log('Error loading token balance: $e');
      if (mounted) {
        // Add mounted check
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          SizedBox(width: 15),
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary isolates the drawer's 60fps slide from the rest of
    // the app so the underlying screen isn't re-rasterized each frame.
    return RepaintBoundary(
      child: AnimatedBuilder(
      animation: widget.drawerController,
      builder: (context, child) {
        return Stack(
          children: [
            Transform.translate(
              offset: Offset(
                -widget.drawerWidth +
                    (widget.drawerWidth * widget.drawerController.value),
                0,
              ),
              child: GestureDetector(
                onTap: () {}, // Prevent tap from propagating
                child: Container(
                  width: widget.drawerWidth,
                  color: Colors.black,
                  child: SafeArea(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Background design
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.black,
                                Colors.black87,
                                Colors.black54,
                              ],
                            ),
                          ),
                        ),

                        // Main content column
                        Column(
                          children: [
                            // Header section
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  NeumorphicAnimatedIcon(
                                    onTap: widget.toggleDrawer,
                                    isDrawerOpen: widget.isDrawerOpen,
                                    isDark: true,
                                  ),
                                ],
                              ),
                            ),

                            // Menu items
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Column(
                                children: [
                                  InkWell(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => HistoryPage(),
                                      ),
                                    ),
                                    child: _buildMenuItem(
                                      Icons.history,
                                      'History',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Token balance circle - only shown for inspectors
                        if (isInspector)
                          Positioned(
                            right: -45,
                            top: MediaQuery.of(context).size.height * 0.5 - 90,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: widget.toggleDrawer,
                                customBorder: CircleBorder(),
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.black87,
                                        Colors.black,
                                      ],
                                      center: Alignment.center,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        spreadRadius: 2,
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      TweenAnimationBuilder<double>(
                                        duration: Duration(milliseconds: 200),
                                        tween: Tween<double>(
                                            begin: 1.0,
                                            end: widget.isDrawerOpen
                                                ? 1.05
                                                : 1.0),
                                        builder: (context, scale, child) {
                                          return Transform.scale(
                                            scale: scale,
                                            child: Container(
                                              width: 190,
                                              height: 190,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color: Colors.white24,
                                                    width: 2),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      Container(
                                        width: 170,
                                        height: 170,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black,
                                          border: Border.all(
                                              color: Colors.white24, width: 1),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.white.withValues(alpha: 0.1),
                                              blurRadius: 15,
                                              spreadRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            if (isLoading)
                                              CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              )
                                            else ...[
                                              Text(
                                                availableTokens.toString(),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                'available credits',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Used: $usedTokens',
                                                style: TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
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
          ],
        );
      },
    ));
  }
}

class DrawerMenuItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const DrawerMenuItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
