import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../constants/hive_constants.dart';
import '../../data/inspection_storage_model.dart';
import '../../routes/routes.dart';
import '../../services/api_services.dart';
import '../../utils/user_role.dart';
import '../home/car_spy/car_spy_data.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final storedData = await _storage.read(key: 'user_data');
      if (!mounted) return;

      if (storedData != null) {
        setState(() {
          _userData = json.decode(storedData);
          _isLoading = false;
        });
      }

      final lastUpdateStr = await _storage.read(key: 'last_profile_update');
      final shouldRefresh = _shouldRefreshData(lastUpdateStr);

      if (shouldRefresh) {
        if (!mounted) return;
        final result = await ApiService.getProfile(context);
        if (!mounted) return;

        if (result['success']) {
          setState(() {
            _userData = result['data']['user'];
          });
          await _storage.write(
            key: 'last_profile_update',
            value: DateTime.now().toIso8601String(),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _shouldRefreshData(String? lastUpdateStr) {
    if (lastUpdateStr == null) return true;
    try {
      final lastUpdate = DateTime.parse(lastUpdateStr);
      final now = DateTime.now();
      return now.difference(lastUpdate).inHours >= 1;
    } catch (e) {
      return true;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancel', style: TextStyle(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storage.deleteAll();
      await UserRole.clearRoles();

      final inspectionBox = await Hive.openBox<InspectionStorageModel>(
          HiveConstants.INSPECTION_BOX);
      final historyBox = await Hive.openBox<InspectionStorageModel>(
          HiveConstants.INSPECTION_HISTORY_BOX);
      await inspectionBox.clear();
      await historyBox.clear();

      if (!context.mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(Routes.login, (route) => false);
    }
  }

  Widget _buildProfileHeader() {
    return FlexibleSpaceBar(
      background: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2563EB), // Sleeker top color
              CarSpyColors.primary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Text(
                        _userData?['name']?.substring(0, 1).toUpperCase() ??
                            'U',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: CarSpyColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _userData?['name'] ?? 'Loading...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _userData?['email'] ?? 'Fetching email...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      {required IconData icon, required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CarSpyColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: CarSpyColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: CarSpyColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8, top: 24),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? textColor,
    bool showTrailing = true,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? CarSpyColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? CarSpyColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: textColor ?? CarSpyColors.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600))
          : null,
      trailing: showTrailing
          ? Icon(Icons.arrow_forward_ios_rounded,
              size: 16, color: Colors.grey.shade400)
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8FAFC), // A slightly off-white modern background
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: CarSpyColors.primary))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 260.0,
                  floating: false,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: CarSpyColors.primary,
                  elevation: 0,
                  flexibleSpace: _buildProfileHeader(),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Row
                        Row(
                          children: [
                            _buildStatCard(
                              icon: Icons.calendar_today_rounded,
                              label: 'Member Since',
                              value: _formatDate(_userData?['created_at']),
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              icon: Icons.verified_rounded,
                              label: 'Status',
                              value: 'Active',
                            ),
                          ],
                        ),

                        // General Settings Group
                        _buildSettingsGroup(
                          title: 'General',
                          children: [
                            _buildListTile(
                              icon: Icons.person_outline_rounded,
                              title: 'Personal Information',
                              subtitle: 'Update your name and details',
                              onTap: () {
                                // Add navigation later
                              },
                            ),
                            Divider(
                                height: 1,
                                indent: 60,
                                color: Colors.grey.shade200),
                            _buildListTile(
                              icon: Icons.shield_outlined,
                              title: 'Security & Password',
                              subtitle: 'Manage your credentials',
                              onTap: () {},
                            ),
                          ],
                        ),

                        // Support & About Group
                        _buildSettingsGroup(
                          title: 'Support',
                          children: [
                            _buildListTile(
                              icon: Icons.help_outline_rounded,
                              title: 'Help Center',
                              onTap: () {},
                            ),
                            Divider(
                                height: 1,
                                indent: 60,
                                color: Colors.grey.shade200),
                            _buildListTile(
                              icon: Icons.info_outline_rounded,
                              title: 'About App',
                              onTap: () {},
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Logout Button (Styled as a cleaner card)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: _buildListTile(
                            icon: Icons.logout_rounded,
                            title: 'Log Out',
                            iconColor: Colors.red,
                            textColor: Colors.red,
                            showTrailing: false,
                            onTap: () => _showLogoutDialog(context),
                          ),
                        ),

                        const SizedBox(height: 40), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
