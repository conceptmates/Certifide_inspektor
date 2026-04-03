import 'package:flutter/material.dart';

import '../../../../constants/const.dart';
import '../car_spy_data.dart';

class CarSpyCoreServicesSection extends StatelessWidget {
  const CarSpyCoreServicesSection({
    super.key,
    this.onServiceTap,
  });

  /// Index matches [carSpyServices] (0 = New Car, 1 = Used Car, …).
  final void Function(int index)? onServiceTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick actions',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: CarSpyColors.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tap a card to browse cars, look up RC details, check challans, and more.',
          style: TextStyle(
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w400,
            color: CarSpyColors.onSurfaceVariant.withOpacity(0.95),
          ),
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: carSpyServices.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.08,
          ),
          itemBuilder: (context, index) {
            final service = carSpyServices[index];
            return _ServiceItem(
              service: service,
              onTap: () => onServiceTap?.call(index),
            );
          },
        ),
      ],
    );
  }
}

class _ServiceItem extends StatelessWidget {
  const _ServiceItem({
    required this.service,
    this.onTap,
  });

  final ServiceItemData service;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hintColor = service.isWarning
        ? const Color(0xFFF59E0B)
        : CarSpyColors.onSurfaceVariant;

    return Semantics(
      button: true,
      label: '${service.title}. ${service.subtitle}',
      child: Container(
        decoration: BoxDecoration(
          color: CarSpyColors.surface,
          borderRadius: BorderRadius.circular(22),
          border:
              Border.all(color: CarSpyColors.outlineVariant.withOpacity(0.6)),
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
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: CarSpyColors.outlineVariant.withOpacity(0.35),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          service.icon,
                          color: service.isWarning
                              ? const Color(0xFFF59E0B)
                              : CarSpyColors.primary,
                          size: 26,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: CarSpyColors.onSurfaceVariant.withOpacity(0.45),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    service.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: CarSpyColors.onSurface,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    service.subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CarSpyPendingReportCard extends StatelessWidget {
  const CarSpyPendingReportCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CarSpyColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CarSpyColors.outlineVariant.withOpacity(0.4)),
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
                      color: CarSpyColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'SYSTEM ALERT',
                    style: TextStyle(
                      color: CarSpyColors.primary,
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
                  color: CarSpyColors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your last appraisal for the Porsche GT3 RS requires document verification.',
                style: TextStyle(
                  fontSize: 13,
                  color: CarSpyColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(
                    width: 72,
                    height: 40,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                            left: 0, child: _AvatarIcon(icon: Icons.person)),
                        Positioned(
                            left: 32, child: _AvatarIcon(icon: Icons.shield)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CarSpyColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 4,
                      shadowColor: CarSpyColors.primary.withOpacity(0.3),
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
}

class _AvatarIcon extends StatelessWidget {
  const _AvatarIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
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
      child: Icon(icon, color: CarSpyColors.primary, size: 18),
    );
  }
}

class CarSpyStatsRow extends StatelessWidget {
  const CarSpyStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.analytics_outlined,
            label: 'Market Pulse',
            value: '98.2%',
            description: 'Accuracy Rating in Appraisals',
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Icons.speed,
            label: 'Diagnostics',
            value: '1.4s',
            description: 'Mean Response Time',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.description,
  });

  final IconData icon;
  final String label;
  final String value;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CarSpyColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CarSpyColors.outlineVariant.withOpacity(0.4)),
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
                  border: Border.all(
                    color: CarSpyColors.outlineVariant.withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(icon, color: CarSpyColors.primary, size: 18),
              ),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: CarSpyColors.onSurfaceVariant,
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
              color: CarSpyColors.onSurface,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 10,
              color: CarSpyColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

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
