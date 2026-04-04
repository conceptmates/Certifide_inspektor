import 'package:flutter/material.dart';

import '../../../../constants/const.dart';
import '../car_spy_data.dart';

class CarSpyCoreServicesSection extends StatefulWidget {
  const CarSpyCoreServicesSection({
    super.key,
    this.onServiceTap,
  });

  final void Function(int index)? onServiceTap;

  @override
  State<CarSpyCoreServicesSection> createState() =>
      _CarSpyCoreServicesSectionState();
}

class _CarSpyCoreServicesSectionState extends State<CarSpyCoreServicesSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int? _pressedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(int index) {
    setState(() => _pressedIndex = index);
    _controller.forward();
  }

  void _onTapUp(int index) {
    setState(() => _pressedIndex = null);
    _controller.reverse();
    final onServiceTap = widget.onServiceTap;
    if (onServiceTap != null) {
      // Defer navigation so it does not run while the framework is still
      // processing this gesture / the subtree rebuild from setState above.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        onServiceTap(index);
      });
    }
  }

  void _onTapCancel() {
    setState(() => _pressedIndex = null);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: CarSpyColors.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: CarSpyColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    size: 14,
                    color: CarSpyColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Instant Access',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CarSpyColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Browse cars, verify RC details, check challans, and more.',
          style: TextStyle(
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w400,
            color: CarSpyColors.onSurfaceVariant.withValues(alpha: 0.95),
          ),
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: carSpyServices.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, index) {
            final service = carSpyServices[index];
            return _ServiceItem(
              key: ValueKey(service.title),
              service: service,
              isPressed: _pressedIndex == index,
              scaleAnimation:
                  _pressedIndex == index ? _scaleAnimation : null,
              onTapDown: () => _onTapDown(index),
              onTapUp: () => _onTapUp(index),
              onTapCancel: _onTapCancel,
            );
          },
        ),
      ],
    );
  }
}

class _ServiceItem extends StatefulWidget {
  const _ServiceItem({
    super.key,
    required this.service,
    required this.isPressed,
    required this.scaleAnimation,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
  });

  final ServiceItemData service;
  final bool isPressed;
  final Animation<double>? scaleAnimation;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;

  @override
  State<_ServiceItem> createState() => _ServiceItemState();
}

class _ServiceItemState extends State<_ServiceItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _iconController;
  late Animation<double> _iconBounceAnimation;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _iconBounceAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_ServiceItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPressed && !oldWidget.isPressed) {
      _iconController.forward().then((_) => _iconController.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWarning = widget.service.isWarning;
    final accentColor = isWarning
        ? const Color(0xFFF59E0B)
        : CarSpyColors.primary;

    Widget card = Semantics(
      button: true,
      label: '${widget.service.title}. ${widget.service.subtitle}',
      child: Container(
        decoration: BoxDecoration(
          color: CarSpyColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isPressed
                ? accentColor.withValues(alpha: 0.5)
                : CarSpyColors.outlineVariant.withValues(alpha: 0.6),
            width: widget.isPressed ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.isPressed
                  ? accentColor.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: widget.isPressed ? 12 : 8,
              offset: Offset(0, widget.isPressed ? 4 : 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTapDown: (_) => widget.onTapDown(),
            onTapUp: (_) => widget.onTapUp(),
            onTapCancel: widget.onTapCancel,
            splashColor: accentColor.withValues(alpha: 0.1),
            highlightColor: accentColor.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedBuilder(
                        animation: _iconBounceAnimation,
                        builder: (context, child) => Transform.scale(
                          scale: widget.isPressed ? _iconBounceAnimation.value : 1.0,
                          child: child,
                        ),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: widget.isPressed
                                  ? [accentColor.withValues(alpha: 0.2), accentColor.withValues(alpha: 0.1)]
                                  : [Colors.white, Colors.white],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: widget.isPressed
                                  ? accentColor.withValues(alpha: 0.3)
                                  : CarSpyColors.outlineVariant.withValues(alpha: 0.35),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.isPressed
                                    ? accentColor.withValues(alpha: 0.2)
                                    : Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.service.icon,
                            color: widget.isPressed
                                ? accentColor
                                : (isWarning
                                    ? const Color(0xFFF59E0B)
                                    : CarSpyColors.primary),
                            size: 24,
                          ),
                        ),
                      ),
                      const Spacer(),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: widget.isPressed
                              ? accentColor.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: widget.isPressed
                              ? accentColor
                              : CarSpyColors.onSurfaceVariant.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    widget.service.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: widget.isPressed
                          ? accentColor
                          : CarSpyColors.onSurface,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.service.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: isWarning
                          ? const Color(0xFFF59E0B)
                          : CarSpyColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.scaleAnimation != null) {
      return AnimatedBuilder(
        animation: widget.scaleAnimation!,
        builder: (context, child) => Transform.scale(
          scale: widget.scaleAnimation!.value,
          child: child,
        ),
        child: card,
      );
    }

    return card;
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
