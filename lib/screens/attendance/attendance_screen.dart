import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import 'leave_application_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFF0F172A);
  static const _accent = Color(0xFF3B82F6);
  static const _accentLight = Color(0xFFEFF6FF);
  static const _surface = Color(0xFFF8FAFC);
  static const _textSecondary = Color(0xFF64748B);
  static const _green = Color(0xFF10B981);
  static const _greenLight = Color(0xFFECFDF5);
  static const _red = Color(0xFFEF4444);
  static const _redLight = Color(0xFFFEF2F2);
  static const _amber = Color(0xFFF59E0B);
  static const _amberLight = Color(0xFFFFFBEB);

  bool _isCheckedIn = false;
  bool _isLocating = false;
  DateTime? _checkInTime;
  DateTime? _checkOutTime;
  Position? _checkInLocation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<_AttendanceLog> _logs = [
    _AttendanceLog(
      date: DateTime.now().subtract(const Duration(days: 1)),
      checkIn: const TimeOfDay(hour: 9, minute: 3),
      checkOut: const TimeOfDay(hour: 18, minute: 12),
      status: _LogStatus.present,
    ),
    _AttendanceLog(
      date: DateTime.now().subtract(const Duration(days: 2)),
      checkIn: const TimeOfDay(hour: 9, minute: 45),
      checkOut: const TimeOfDay(hour: 18, minute: 0),
      status: _LogStatus.late,
    ),
    _AttendanceLog(
      date: DateTime.now().subtract(const Duration(days: 3)),
      checkIn: const TimeOfDay(hour: 9, minute: 1),
      checkOut: const TimeOfDay(hour: 17, minute: 55),
      status: _LogStatus.present,
    ),
    _AttendanceLog(
      date: DateTime.now().subtract(const Duration(days: 4)),
      checkIn: null,
      checkOut: null,
      status: _LogStatus.absent,
    ),
    _AttendanceLog(
      date: DateTime.now().subtract(const Duration(days: 5)),
      checkIn: const TimeOfDay(hour: 9, minute: 0),
      checkOut: const TimeOfDay(hour: 18, minute: 5),
      status: _LogStatus.present,
    ),
    _AttendanceLog(
      date: DateTime.now().subtract(const Duration(days: 8)),
      checkIn: null,
      checkOut: null,
      status: _LogStatus.leave,
      note: 'Approved leave',
    ),
    _AttendanceLog(
      date: DateTime.now().subtract(const Duration(days: 9)),
      checkIn: const TimeOfDay(hour: 9, minute: 10),
      checkOut: const TimeOfDay(hour: 18, minute: 0),
      status: _LogStatus.present,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckInOut() async {
    if (_isCheckedIn) {
      setState(() {
        _checkOutTime = DateTime.now();
        _isCheckedIn = false;
      });
      return;
    }

    setState(() => _isLocating = true);

    try {
      final position = await _fetchLocation();
      if (!mounted) return;
      setState(() {
        _checkInTime = DateTime.now();
        _checkOutTime = null;
        _checkInLocation = position;
        _isCheckedIn = true;
        _isLocating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLocating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<Position> _fetchLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) throw 'Location unavailable';
      await _showLocationDialog(
        title: 'Turn on Location',
        message:
            'Location services are off. Please enable GPS to record your check-in location.',
        actionLabel: 'Open Settings',
        onAction: Geolocator.openLocationSettings,
      );
      throw 'Location services are disabled.';
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) throw 'Location unavailable';
      await _showLocationDialog(
        title: 'Location Permission Required',
        message:
            'Allow location access so your check-in coordinates can be recorded.',
        actionLabel: 'Open Settings',
        onAction: Geolocator.openAppSettings,
      );
      throw 'Location permission not granted.';
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  Future<void> _showLocationDialog({
    required String title,
    required String message,
    required String actionLabel,
    required Future<void> Function() onAction,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _accentLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.location_on_rounded,
                  size: 20, color: _accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: _textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await onAction();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) => DateFormat('hh:mm a').format(dt);

  String _elapsedTime() {
    if (_checkInTime == null) return '0h 0m';
    final end = _checkOutTime ?? DateTime.now();
    final diff = end.difference(_checkInTime!);
    return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Attendance',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _primary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LeaveApplicationScreen(),
                ),
              ),
              icon: const Icon(Icons.event_available_rounded, size: 18),
              label: const Text('Apply Leave'),
              style: TextButton.styleFrom(
                foregroundColor: _accent,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildTodayCard(),
          const SizedBox(height: 16),
          _buildStatsRow(),
          const SizedBox(height: 24),
          _buildLogsSection(),
        ],
      ),
    );
  }

  Widget _buildTodayCard() {
    final now = DateTime.now();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE').format(now),
                    style: const TextStyle(
                      fontSize: 13,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('d MMMM yyyy').format(now),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isCheckedIn ? _greenLight : _surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _isCheckedIn ? _green : _textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isCheckedIn ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isCheckedIn ? _green : _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTimeInfo(
                  label: 'Check In',
                  value: _checkInTime != null
                      ? _formatTime(_checkInTime!)
                      : '--:--',
                  icon: Icons.login_rounded,
                  iconColor: _green,
                  iconBg: _greenLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeInfo(
                  label: 'Check Out',
                  value: _checkOutTime != null
                      ? _formatTime(_checkOutTime!)
                      : '--:--',
                  icon: Icons.logout_rounded,
                  iconColor: _red,
                  iconBg: _redLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeInfo(
                  label: 'Duration',
                  value: _checkInTime != null ? _elapsedTime() : '--',
                  icon: Icons.timer_rounded,
                  iconColor: _accent,
                  iconBg: _accentLight,
                ),
              ),
            ],
          ),
          if (_checkInLocation != null && _isCheckedIn) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _greenLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 14, color: _green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Check-in location: '
                      '${_checkInLocation!.latitude.toStringAsFixed(5)}, '
                      '${_checkInLocation!.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          ScaleTransition(
            scale: _isCheckedIn
                ? _pulseAnimation
                : const AlwaysStoppedAnimation(1.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLocating ? null : _handleCheckInOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCheckedIn ? _red : _accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      (_isCheckedIn ? _red : _accent).withValues(alpha: 0.7),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLocating
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Getting location...',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isCheckedIn
                                ? Icons.logout_rounded
                                : Icons.login_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isCheckedIn ? 'Check Out' : 'Check In',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final present = _logs
        .where((l) =>
            l.status == _LogStatus.present || l.status == _LogStatus.late)
        .length;
    final absent =
        _logs.where((l) => l.status == _LogStatus.absent).length;
    final leaves =
        _logs.where((l) => l.status == _LogStatus.leave).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Present',
            value: '$present',
            color: _green,
            bgColor: _greenLight,
            icon: Icons.check_circle_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: 'Absent',
            value: '$absent',
            color: _red,
            bgColor: _redLight,
            icon: Icons.cancel_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: 'On Leave',
            value: '$leaves',
            color: _amber,
            bgColor: _amberLight,
            icon: Icons.event_busy_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: _textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Attendance Logs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _primary,
              ),
            ),
            Text(
              '${_logs.length} records',
              style: const TextStyle(
                fontSize: 13,
                color: _textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _logs.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: Colors.grey.withValues(alpha: 0.1),
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, i) => _buildLogTile(_logs[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildLogTile(_AttendanceLog log) {
    final statusConfig = _statusConfig(log.status);

    String checkInStr = '--';
    String checkOutStr = '--';
    String durationStr = '--';

    if (log.checkIn != null) {
      checkInStr =
          '${_pad(log.checkIn!.hour)}:${_pad(log.checkIn!.minute)} ${log.checkIn!.period.name.toUpperCase()}';
    }
    if (log.checkOut != null) {
      checkOutStr =
          '${_pad(log.checkOut!.hour)}:${_pad(log.checkOut!.minute)} ${log.checkOut!.period.name.toUpperCase()}';
    }
    if (log.checkIn != null && log.checkOut != null) {
      final inMin = log.checkIn!.hour * 60 + log.checkIn!.minute;
      final outMin = log.checkOut!.hour * 60 + log.checkOut!.minute;
      final diff = outMin - inMin;
      durationStr = '${diff ~/ 60}h ${diff % 60}m';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusConfig.bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusConfig.icon, size: 18, color: statusConfig.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEE, d MMM').format(log.date),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                ),
                const SizedBox(height: 4),
                if (log.note != null)
                  Text(
                    log.note!,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusConfig.color,
                    ),
                  )
                else
                  Row(
                    children: [
                      _buildMiniTag(
                          Icons.login_rounded, checkInStr, _textSecondary),
                      const SizedBox(width: 8),
                      _buildMiniTag(
                          Icons.logout_rounded, checkOutStr, _textSecondary),
                      const SizedBox(width: 8),
                      _buildMiniTag(
                          Icons.timer_outlined, durationStr, _textSecondary),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusConfig.bgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusConfig.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusConfig.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTag(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 2),
        Text(text, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  _StatusConfig _statusConfig(_LogStatus status) {
    switch (status) {
      case _LogStatus.present:
        return _StatusConfig(
          label: 'Present',
          color: _green,
          bgColor: _greenLight,
          icon: Icons.check_circle_outline_rounded,
        );
      case _LogStatus.late:
        return _StatusConfig(
          label: 'Late',
          color: _amber,
          bgColor: _amberLight,
          icon: Icons.watch_later_outlined,
        );
      case _LogStatus.absent:
        return _StatusConfig(
          label: 'Absent',
          color: _red,
          bgColor: _redLight,
          icon: Icons.cancel_outlined,
        );
      case _LogStatus.leave:
        return _StatusConfig(
          label: 'Leave',
          color: _accent,
          bgColor: _accentLight,
          icon: Icons.event_busy_rounded,
        );
    }
  }
}

enum _LogStatus { present, late, absent, leave }

class _AttendanceLog {
  final DateTime date;
  final TimeOfDay? checkIn;
  final TimeOfDay? checkOut;
  final _LogStatus status;
  final String? note;

  const _AttendanceLog({
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    this.note,
  });
}

class _StatusConfig {
  final String label;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const _StatusConfig({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.icon,
  });
}
