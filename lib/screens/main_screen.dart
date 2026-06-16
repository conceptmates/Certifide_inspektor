import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/user_provider.dart';
import '../screens/home/home.dart';
import '../screens/home/reports_page.dart';
import '../screens/profile/profile.dart';
import '../widgets/custom_nav.dart';

class MainScreen extends ConsumerStatefulWidget {
  final int? initialIndex;
  const MainScreen({
    super.key,
    this.initialIndex,
  });

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  int _previousIndex = 0;
  DateTime? _lastBackPressTime;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex ?? 0;
    // Add a small delay to allow the navigation transition to complete
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void changeSelectedIndex(int index) {
    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = index;
    });
  }

  final List<Widget> _userScreens = [
    const Home(key: ValueKey('home')),
    const ReportsPage(key: ValueKey('reports')),
    const ProfilePage(key: ValueKey('profile')),
  ];

  @override
  void didUpdateWidget(covariant MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedIndex >= _userScreens.length) {
      setState(() {
        _selectedIndex = 0;
      });
    }
  }

  Future<void> _handlePopInvokedWithResult(bool didPop, dynamic result) async {
    if (didPop) {
      return;
    }

    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return;
    }

    if (_lastBackPressTime == null ||
        DateTime.now().difference(_lastBackPressTime!) >
            const Duration(seconds: 2)) {
      _lastBackPressTime = DateTime.now();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Press back again to exit'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (mounted) {
      final bool? shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Exit App'),
          content: const Text('Are you sure you want to exit?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );

      if (shouldExit ?? false) {
        SystemNavigator.pop();
      }
    }
  }

  void _onItemSelected(int index) {
    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePopInvokedWithResult,
      child: Builder(
        builder: (context) {
          final userState = ref.watch(userNotifierProvider);
          if (userState.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator.adaptive()),
            );
          }

          final screens = _userScreens;
          if (_selectedIndex >= screens.length) _selectedIndex = 0;

          return Scaffold(
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: KeyedSubtree(
                key: ValueKey(_selectedIndex),
                child: screens[_selectedIndex],
              ),
            ),
            bottomNavigationBar: CustomBottomNavBar(
              selectedIndex: _selectedIndex,
              onItemSelected: _onItemSelected,
            ),
            resizeToAvoidBottomInset: false,
            extendBody: true,
          );
        },
      ),
    );
  }
}
