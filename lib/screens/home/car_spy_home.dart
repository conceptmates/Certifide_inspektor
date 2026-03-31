import 'package:flutter/material.dart';

class CarSpyHome extends StatefulWidget {
  const CarSpyHome({super.key});

  @override
  State<CarSpyHome> createState() => _CarSpyHomeState();
}

class _CarSpyHomeState extends State<CarSpyHome> {
  int _selectedIndex = 0;

  static const Color primaryColor = Color(0xFF0052CC);
  static const Color onSurface = Color(0xFF172B4D);
  static const Color surfaceColor = Color(0xFFF4F7FA);
  static const Color onSurfaceVariant = Color(0xFF44546F);
  static const Color outlineVariant = Color(0xFFD1D5DB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      appBar: _buildTopAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeroSection(),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCoreServicesHeader(),
                    const SizedBox(height: 16),
                    _buildServicesList(),
                    const SizedBox(height: 32),
                    _buildPendingReportCard(),
                    const SizedBox(height: 24),
                    _buildStatsRow(),
                    const SizedBox(height: 24),
                    _buildHeritageVaultCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildTopAppBar() {
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
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFEFF3FA),
            foregroundImage: const NetworkImage(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuDzwV3ne_WATyw86rC4SLc4GWf_5rbqcNUGriG8tR1oGL1uHipDsmMydqzuUQSwlwKPwNIaH24W9fCl4kgqoDW_GC7TvUedu9P3624E-CP5eovcYBCF4IJyqKhfOAQ07zJCg_jkxruwia--xmfaVDnnb0usyU4KL2nwbqbXTuVJDwNDBzskPJ29fVC8Y7rJMs0GZVR_gTP_VAM09EkKhlgUYAYygnY8ZcCvfWbeYIyjLXz1t1bUJdG5L6-VFj-IaRvWiNT6kQEFiSU',
            ),
            child: const Icon(Icons.person, color: Color(0xFF1E40AF)),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
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
                    child: const Center(child: CircularProgressIndicator()),
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
                        color: primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.3),
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
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                        shadowColor: primaryColor.withOpacity(0.4),
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

  Widget _buildCoreServicesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'Core Services',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: onSurface,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'SELECT TIER',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildServicesList() {
    final services = [
      {
        'icon': Icons.add,
        'title': 'New Car',
        'subtitle': 'EXPLORE INVENTORY',
      },
      {
        'icon': Icons.verified_outlined,
        'title': 'Used Car',
        'subtitle': 'VERIFIED LISTINGS',
      },
      {
        'icon': Icons.fingerprint,
        'title': 'RC Details',
        'subtitle': 'OWNER & SPEC INFO',
      },
      {
        'icon': Icons.policy_outlined,
        'title': 'Challan',
        'subtitle': 'PENDING DUES',
      },
      {
        'icon': Icons.shield_outlined,
        'title': 'Insurance',
        'subtitle': 'RENEW POLICY',
      },
      {
        'icon': Icons.toll_outlined,
        'title': 'FASTag',
        'subtitle': 'ACTION REQUIRED',
        'isWarning': true,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        final service = services[index];
        return _buildServiceItem(
          icon: service['icon'] as IconData,
          title: service['title'] as String,
          subtitle: service['subtitle'] as String,
          isWarning: (service['isWarning'] as bool?) ?? false,
        );
      },
    );
  }

  Widget _buildServiceItem({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isWarning = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: outlineVariant.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: outlineVariant.withOpacity(0.35)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: isWarning ? const Color(0xFFF59E0B) : primaryColor,
                    size: 28,
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color:
                        isWarning ? const Color(0xFFF59E0B) : onSurfaceVariant,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingReportCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.gpp_maybe_outlined,
              size: 150,
              color: Colors.blue.shade900.withOpacity(0.05),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'SYSTEM ALERT',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Pending Report',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your last appraisal for the Porsche GT3 RS requires document verification.',
                style: TextStyle(
                  fontSize: 13,
                  color: onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 72,
                    height: 40,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          child: _buildAvatarIcon(Icons.person),
                        ),
                        Positioned(
                          left: 32,
                          child: _buildAvatarIcon(Icons.shield),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 4,
                      shadowColor: primaryColor.withOpacity(0.3),
                    ),
                    child: const Text(
                      'Resume',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
          ),
        ],
      ),
      child: Icon(icon, color: primaryColor, size: 18),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.analytics_outlined,
            label: 'Market Pulse',
            value: '98.2%',
            description: 'Accuracy Rating in Appraisals',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.speed,
            label: 'Diagnostics',
            value: '1.4s',
            description: 'Mean Response Time',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: outlineVariant.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(icon, color: primaryColor, size: 18),
              ),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: onSurface,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 10,
              color: onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeritageVaultCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuAmy81rY0oqiXmahKk59c_VNyodtccEl3MC_PdX9b2h7pk-KgJwWBwJGi6lAnLLkwD1ERkG7GdwpneN4vXcFKvXzIrhO08kBJjzu31kwqWQ3z3T0RvGTLHOXBvre9-KFJ5KaA1tzOIvujN3E2KoxuxIcrljn68_YfdAyxroYiLdDQwheTRmqCQQJ9d0_zyzmZ5Ab-2xwbO86xzsBV4wXzqnruKc6Z4fWFGTQCC9OcHw_OGAIySrCzhoMRAKTBxgb015qBAl8vLbT1g',
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(color: Colors.grey.shade300);
              },
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
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'The Heritage\nVault',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: onSurface,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Explore classic car valuations\nand preservation metrics.',
                    style: TextStyle(
                      fontSize: 12,
                      color: onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Text(
                        'BROWSE ARCHIVE',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.open_in_new,
                        color: primaryColor,
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

  Widget _buildBottomNavBar() {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'HOME'},
      {'icon': Icons.history, 'label': 'HISTORY'},
      {'icon': Icons.garage_outlined, 'label': 'GARAGE'},
      {'icon': Icons.person_outline, 'label': 'PROFILE'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = _selectedIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFEFF6FF)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[index]['icon'] as IconData,
                        color: isSelected
                            ? const Color(0xFF1D4ED8)
                            : Colors.grey.shade400,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[index]['label'] as String,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? const Color(0xFF1D4ED8)
                              : Colors.grey.shade400,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
