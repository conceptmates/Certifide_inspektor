import 'package:flutter/material.dart';

/// Disables Material 3 stretch "rubber band" on overscroll and uses clamping
/// physics on all platforms so lists don't elastic-expand.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const AlwaysScrollableScrollPhysics(
      parent: ClampingScrollPhysics(),
    );
  }
}
