import 'package:flutter/material.dart';

class NeumorphicAnimatedIcon extends StatefulWidget {
  final VoidCallback onTap;
  final bool isDrawerOpen;
  final bool isDark;

  const NeumorphicAnimatedIcon({
    super.key,
    required this.onTap,
    required this.isDrawerOpen,
    this.isDark = false,
  });

  @override
  State<NeumorphicAnimatedIcon> createState() => _NeumorphicAnimatedIconState();
}

class _NeumorphicAnimatedIconState extends State<NeumorphicAnimatedIcon>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void didUpdateWidget(NeumorphicAnimatedIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDrawerOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color customBlackColor =
        widget.isDark ? Colors.white : const Color.fromARGB(255, 53, 53, 53);
    final Color customWhiteColor =
        widget.isDark ? Colors.black : const Color.fromARGB(255, 237, 237, 237);
    final Color shadowColor =
        widget.isDark ? Colors.white24 : Colors.grey.shade400;
    final Color lightShadowColor =
        widget.isDark ? Colors.white10 : Colors.white;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: customWhiteColor,
          boxShadow: [
            BoxShadow(
              blurRadius: 15,
              offset: widget.isDrawerOpen
                  ? const Offset(5, -5)
                  : const Offset(5, 5),
              color: shadowColor,
            ),
            BoxShadow(
              blurRadius: 15,
              offset: widget.isDrawerOpen
                  ? const Offset(-5, 5)
                  : const Offset(-5, -5),
              color: lightShadowColor,
            ),
          ],
        ),
        child: Center(
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _controller,
            size: 25,
            color: customBlackColor,
          ),
        ),
      ),
    );
  }
}
