import 'package:flutter/material.dart';
import '../../widgets/drawer_menu.dart';
import 'main_content.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late AnimationController _drawerController;
  bool isDrawerOpen = false;

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    setState(() {
      isDrawerOpen = !isDrawerOpen;
      if (isDrawerOpen) {
        _drawerController.forward();
      } else {
        _drawerController.reverse();
      }
    });
  }

  double getDrawerWidth(BuildContext context) {
    return MediaQuery.of(context).size.width * 0.4;
  }

  @override
  Widget build(BuildContext context) {
    final drawerWidth = getDrawerWidth(context);

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: Stack(
        children: [
          MainContent(
            onMenuTap: _toggleDrawer,
            isDrawerOpen: isDrawerOpen,
          ),
          if (isDrawerOpen)
            GestureDetector(
              onTap: _toggleDrawer,
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
            ),
          DrawerMenu(
            drawerController: _drawerController,
            drawerWidth: drawerWidth,
            toggleDrawer: _toggleDrawer,
            isDrawerOpen: isDrawerOpen,
          ),
        ],
      ),
    );
  }
}
