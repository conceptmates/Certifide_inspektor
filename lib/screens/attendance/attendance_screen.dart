import 'package:flutter/material.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Attendance',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF172B4D),
          ),
        ),
      ),
      body: const Center(
        child: Text(
          'Attendance',
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF44546F),
          ),
        ),
      ),
    );
  }
}
