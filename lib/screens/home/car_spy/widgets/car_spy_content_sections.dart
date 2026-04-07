import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../car_spy_data.dart';
export 'components/car_spy_heritage_vault_card.dart';
export 'components/car_spy_pending_report_card.dart';
export 'components/car_spy_stats_row.dart';

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
    _setPressedIndexSafely(index);
    _controller.forward();
  }

  void _onTapUp(int index) {
    _setPressedIndexSafely(null);
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
    _setPressedIndexSafely(null);
    _controller.reverse();
  }

  void _setPressedIndexSafely(int? index) {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    final canSetStateNow = phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks;

    if (canSetStateNow) {
      setState(() => _pressedIndex = index);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _pressedIndex = index);
    });
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

