import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:hive_ce/hive.dart';
import 'dart:convert';
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

class _ProfilePageState extends State<ProfilePage> {
  final _storage = const FlutterSecureStorage();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(
          () => _appVersion = 'Version ${info.version} +${info.buildNumber}');
    } catch (_) {
      // Leave version blank if it can't be read.
    }
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
      if (_shouldRefreshData(lastUpdateStr)) {
        if (!mounted) return;
        final result = await ApiService.getProfile(context);
        if (!mounted) return;

        if (result['success']) {
          setState(() => _userData = result['data']['user']);
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _shouldRefreshData(String? lastUpdateStr) {
    if (lastUpdateStr == null) return true;
    try {
      return DateTime.now().difference(DateTime.parse(lastUpdateStr)).inHours >=
          1;
    } catch (_) {
      return true;
    }
  }

  String _getRoleLabel() {
    final roles = _userData?['roles'] as List?;
    if (roles == null || roles.isEmpty) return 'Inspector';
    final name = roles.first['name'] as String? ?? 'inspector';
    return name[0].toUpperCase() + name.substring(1);
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

      final inspectionBox = Hive.isBoxOpen(HiveConstants.INSPECTION_BOX)
          ? Hive.box<InspectionStorageModel>(HiveConstants.INSPECTION_BOX)
          : await Hive.openBox<InspectionStorageModel>(
              HiveConstants.INSPECTION_BOX);
      final historyBox = Hive.isBoxOpen(HiveConstants.INSPECTION_HISTORY_BOX)
          ? Hive.box<InspectionStorageModel>(
              HiveConstants.INSPECTION_HISTORY_BOX)
          : await Hive.openBox<InspectionStorageModel>(
              HiveConstants.INSPECTION_HISTORY_BOX);
      await inspectionBox.clear();
      await historyBox.clear();

      if (!context.mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(Routes.login, (route) => false);
    }
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: CarSpyColors.primary),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CarSpyColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, indent: 50, color: Colors.grey.shade100),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    Color? iconColor,
    Color? textColor,
    VoidCallback? onTap,
    bool isLast = false,
  }) {
    final color = iconColor ?? CarSpyColors.primary;
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor ?? CarSpyColors.onSurface,
            ),
          ),
          trailing: Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: Colors.grey.shade400),
        ),
        if (!isLast)
          Divider(height: 1, indent: 70, color: Colors.grey.shade100),
      ],
    );
  }

  Widget _buildSectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 24),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _userData?['name'] ?? '—';
    final email = _userData?['email'] ?? '—';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: CarSpyColors.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: Colors.grey.shade600, size: 18),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: CarSpyColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),

                  // Avatar + Name + Role badge
                  Center(
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: CarSpyColors.primary
                                    .withValues(alpha: 0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: CarSpyColors.primary,
                            child: Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: CarSpyColors.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: CarSpyColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getRoleLabel(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: CarSpyColors.primary,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Account info
                  _buildSectionLabel('ACCOUNT'),
                  _buildCard(children: [
                    _buildInfoRow(
                      icon: Icons.mail_outline_rounded,
                      label: 'Email',
                      value: email,
                    ),
                    _buildInfoRow(
                      icon: Icons.verified_rounded,
                      label: 'Status',
                      value: 'Active',
                      isLast: true,
                    ),
                  ]),

                  // Settings
                  _buildSectionLabel('SETTINGS'),
                  _buildCard(children: [
                    _buildMenuTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Personal Information',
                      onTap: () {},
                    ),
                    _buildMenuTile(
                      icon: Icons.shield_outlined,
                      title: 'Security & Password',
                      isLast: true,
                      onTap: () {},
                    ),
                  ]),

                  // Support
                  _buildSectionLabel('SUPPORT'),
                  _buildCard(children: [
                    _buildMenuTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Help Center',
                      onTap: () {},
                    ),
                    _buildMenuTile(
                      icon: Icons.info_outline_rounded,
                      title: 'About App',
                      isLast: true,
                      onTap: () {},
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Logout
                  _buildCard(children: [
                    ListTile(
                      onTap: () => _showLogoutDialog(context),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 2),
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.logout_rounded,
                            color: Colors.red, size: 20),
                      ),
                      title: const Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // App version
                  if (_appVersion.isNotEmpty)
                    Center(
                      child: Text(
                        _appVersion,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: CarSpyColors.onSurface.withValues(alpha: 0.4),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
    );
  }
}
