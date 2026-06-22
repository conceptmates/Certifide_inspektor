import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import 'attendance_screen.dart';

/// A single check-in/check-out working session held in local UI state.
///
/// Attendance isn't persisted to the API yet, so these live only for the
/// lifetime of the screen. [checkOut] is null while a session is still open.
class _Session {
  _Session({
    required this.checkIn,
    this.checkOut,
    this.latitude,
    this.longitude,
  });

  final DateTime checkIn;
  DateTime? checkOut;
  final double? latitude;
  final double? longitude;

  bool get isOpen => checkOut == null;
  bool get hasLocation => latitude != null && longitude != null;

  Duration get duration => (checkOut ?? DateTime.now()).difference(checkIn);
}

/// The inspector's main Attendance page: a check-in/check-out tracker with a
/// live hero card, a manual "Add Attendance" logger, and recent activity.
/// Leaves are reached via the app-bar button so attendance stays front and
/// centre.
class InspectorAttendanceScreen extends StatefulWidget {
  const InspectorAttendanceScreen({super.key});

  @override
  State<InspectorAttendanceScreen> createState() =>
      _InspectorAttendanceScreenState();
}

class _InspectorAttendanceScreenState extends State<InspectorAttendanceScreen> {
  static const _primary = Color(0xFF0F172A);
  static const _accent = Color(0xFF3B82F6);
  static const _surface = Color(0xFFF8FAFC);
  static const _textSecondary = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);
  static const _green = Color(0xFF10B981);
  static const _red = Color(0xFFEF4444);

  final List<_Session> _sessions = [];

  /// Drives the live elapsed-time read-out while a session is open.
  Timer? _ticker;
  bool _locating = false;

  _Session? get _openSession {
    for (final s in _sessions) {
      if (s.isOpen) return s;
    }
    return null;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  // ─────────────────────────────── Actions ──────────────────────────────

  Future<void> _checkIn() async {
    setState(() => _locating = true);
    final pos = await _currentPosition();
    if (!mounted) return;
    setState(() {
      _sessions.insert(
        0,
        _Session(
          checkIn: DateTime.now(),
          latitude: pos?.latitude,
          longitude: pos?.longitude,
        ),
      );
      _locating = false;
    });
    _startTicker();
    _toast(
      pos == null
          ? 'Checked in — location unavailable.'
          : 'Checked in successfully.',
      color: _green,
    );
  }

  void _checkOut() {
    final open = _openSession;
    if (open == null) return;
    setState(() => open.checkOut = DateTime.now());
    _stopTicker();
    _toast('Checked out. Have a good one!', color: _accent);
  }

  Future<void> _addManual() async {
    final session = await showModalBottomSheet<_Session>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ManualAttendanceSheet(),
    );
    if (session == null || !mounted) return;
    setState(() {
      _sessions.add(session);
      _sessions.sort((a, b) => b.checkIn.compareTo(a.checkIn));
    });
    _toast('Attendance logged.', color: _green);
  }

  void _openLeaves() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InspectorLeavesScreen()),
    );
  }

  /// Best-effort current location; returns null if services/permissions are
  /// unavailable rather than blocking the check-in.
  Future<Position?> _currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        log('geolocator: location services disabled', name: 'attendance');
        return null;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      log('geolocator: permission = $perm', name: 'attendance');
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 12));
      log(
        'geolocator: position = lat ${pos.latitude}, lng ${pos.longitude}, '
        'accuracy ${pos.accuracy}m',
        name: 'attendance',
      );
      return pos;
    } catch (e) {
      log('geolocator error: $e', name: 'attendance');
      return null;
    }
  }

  void _toast(String msg, {required Color color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ──────────────────────────────── Build ───────────────────────────────

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
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _openLeaves,
              icon: const Icon(Icons.beach_access_rounded, size: 18),
              label: const Text('Leaves'),
              style: TextButton.styleFrom(
                foregroundColor: _accent,
                backgroundColor: const Color(0xFFEFF6FF),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildHeroCard(),
          const SizedBox(height: 14),
          _buildAddAttendanceButton(),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text(
                'Recent activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
              const Spacer(),
              if (_sessions.isNotEmpty)
                Text(
                  '${_sessions.length} session${_sessions.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontSize: 12, color: _textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_sessions.isEmpty)
            _buildEmptyState()
          else
            ..._sessions.map(_buildSessionCard),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    final open = _openSession;
    final isActive = open != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActive
              ? const [Color(0xFF059669), Color(0xFF10B981)]
              : const [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        boxShadow: [
          BoxShadow(
            color: (isActive ? _green : _primary).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isActive ? 'On the clock' : 'Off the clock',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('EEE, d MMM').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (isActive) ...[
            Text(
              _fmtDuration(open.duration),
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Since ${DateFormat('h:mm a').format(open.checkIn)}'
              '${open.hasLocation ? '  •  📍 Location captured' : ''}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ] else ...[
            const Text(
              'Ready to start your shift?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Check in to record your working hours and location.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _locating
                  ? null
                  : (isActive ? _checkOut : _checkIn),
              icon: _locating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF0F172A)),
                      ),
                    )
                  : Icon(
                      isActive
                          ? Icons.logout_rounded
                          : Icons.login_rounded,
                      size: 20,
                    ),
              label: Text(
                _locating
                    ? 'Getting location…'
                    : (isActive ? 'Check Out' : 'Check In'),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: isActive ? _red : _primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddAttendanceButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _addManual,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Add Attendance Manually'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _accent,
          backgroundColor: Colors.white,
          side: const BorderSide(color: _border),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(Icons.access_time_rounded,
              size: 48, color: _border.withValues(alpha: 1)),
          const SizedBox(height: 12),
          const Text(
            'No attendance yet today',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: _primary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Check in above or add a session manually.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(_Session s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: s.isOpen
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  s.isOpen
                      ? Icons.timelapse_rounded
                      : Icons.check_circle_rounded,
                  color: s.isOpen ? _green : _accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEE, d MMM yyyy').format(s.checkIn),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.isOpen ? 'In progress' : 'Completed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: s.isOpen ? _green : _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _fmtDuration(s.duration, short: true),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _primary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _metric(
                  'Check In',
                  DateFormat('h:mm a').format(s.checkIn),
                  Icons.login_rounded,
                  _green,
                ),
              ),
              Container(width: 1, height: 32, color: _border),
              Expanded(
                child: _metric(
                  'Check Out',
                  s.checkOut != null
                      ? DateFormat('h:mm a').format(s.checkOut!)
                      : '—',
                  Icons.logout_rounded,
                  s.checkOut != null ? _red : _textSecondary,
                ),
              ),
            ],
          ),
          if (s.hasLocation) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 15, color: _textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${s.latitude!.toStringAsFixed(5)}, '
                  '${s.longitude!.toStringAsFixed(5)}',
                  style: const TextStyle(
                      fontSize: 12, color: _textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: _primary),
        ),
      ],
    );
  }

  /// `2h 14m` (short) or `02:14:08` (live, with seconds).
  String _fmtDuration(Duration d, {bool short = false}) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (short) {
      if (h == 0) return '${m}m';
      return '${h}h ${m}m';
    }
    final s = d.inSeconds % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(h)}:${two(m)}:${two(s)}';
  }
}

/// Bottom sheet to log a working session you forgot to check in for — pick a
/// date, a check-in time and an optional check-out time.
class _ManualAttendanceSheet extends StatefulWidget {
  const _ManualAttendanceSheet();

  @override
  State<_ManualAttendanceSheet> createState() => _ManualAttendanceSheetState();
}

class _ManualAttendanceSheetState extends State<_ManualAttendanceSheet> {
  static const _primary = Color(0xFF0F172A);
  static const _accent = Color(0xFF3B82F6);
  static const _textSecondary = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);
  static const _red = Color(0xFFEF4444);

  DateTime _date = DateTime.now();
  TimeOfDay _checkIn = TimeOfDay.now();
  TimeOfDay? _checkOut;
  String? _error;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool isCheckIn}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          isCheckIn ? _checkIn : (_checkOut ?? _checkIn),
    );
    if (picked == null) return;
    setState(() {
      if (isCheckIn) {
        _checkIn = picked;
      } else {
        _checkOut = picked;
      }
      _error = null;
    });
  }

  DateTime _combine(TimeOfDay t) =>
      DateTime(_date.year, _date.month, _date.day, t.hour, t.minute);

  void _submit() {
    final inAt = _combine(_checkIn);
    final outAt = _checkOut == null ? null : _combine(_checkOut!);
    if (outAt != null && !outAt.isAfter(inAt)) {
      setState(() => _error = 'Check-out must be after check-in.');
      return;
    }
    Navigator.pop(
      context,
      _Session(checkIn: inAt, checkOut: outAt),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Add Attendance',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _primary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Log a working session manually.',
              style: TextStyle(fontSize: 13, color: _textSecondary),
            ),
            const SizedBox(height: 20),
            _field(
              label: 'Date',
              value: DateFormat('EEE, d MMM yyyy').format(_date),
              icon: Icons.calendar_today_rounded,
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field(
                    label: 'Check In',
                    value: _checkIn.format(context),
                    icon: Icons.login_rounded,
                    onTap: () => _pickTime(isCheckIn: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    label: 'Check Out',
                    value: _checkOut?.format(context) ?? 'Optional',
                    icon: Icons.logout_rounded,
                    muted: _checkOut == null,
                    onTap: () => _pickTime(isCheckIn: false),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _red),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Save Attendance',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    bool muted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: muted ? _textSecondary : _primary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: _textSecondary),
          ],
        ),
      ),
    );
  }
}
