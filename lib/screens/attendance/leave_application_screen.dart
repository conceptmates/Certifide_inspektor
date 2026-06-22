import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_services.dart';

/// Lets an inspector request leave via `POST /api/inspector/leaves`.
///
/// The API takes a single `leave_date`, so a date range is submitted as one
/// request per day and the per-day outcomes are aggregated into a summary.
/// Pops `true` once at least one day is successfully requested so the caller
/// can refresh its list.
class LeaveApplicationScreen extends StatefulWidget {
  const LeaveApplicationScreen({super.key});

  @override
  State<LeaveApplicationScreen> createState() => _LeaveApplicationScreenState();
}

class _LeaveApplicationScreenState extends State<LeaveApplicationScreen> {
  static const _primary = Color(0xFF0F172A);
  static const _accent = Color(0xFF3B82F6);
  static const _accentLight = Color(0xFFEFF6FF);
  static const _surface = Color(0xFFF8FAFC);
  static const _textSecondary = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);
  static const _green = Color(0xFF10B981);
  static const _greenLight = Color(0xFFECFDF5);
  static const _red = Color(0xFFEF4444);
  static const _amber = Color(0xFFF59E0B);
  static const _amberLight = Color(0xFFFFFBEB);

  /// Guard against accidentally firing dozens of requests for a huge range.
  static const _maxRangeDays = 31;

  final _reasonController = TextEditingController();

  // ignore: prefer_final_fields — reassigned by _setMode when range is re-enabled
  bool _isRange = false;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isSubmitting = false;
  int _submitProgress = 0;
  int _submitTotal = 0;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Number of days covered by the current selection (inclusive).
  int get _dayCount {
    if (_fromDate == null) return 0;
    if (!_isRange) return 1;
    if (_toDate == null) return 0;
    return _toDate!.difference(_fromDate!).inDays + 1;
  }

  /// Every date in the selection, expanded day-by-day.
  List<DateTime> get _selectedDates {
    if (_fromDate == null) return const [];
    if (!_isRange || _toDate == null) return [_fromDate!];
    return [
      for (var i = 0; i < _dayCount; i++)
        _fromDate!.add(Duration(days: i)),
    ];
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom
        ? (_fromDate ?? _today)
        : (_toDate ?? _fromDate ?? _today);
    final first = isFrom ? _today : (_fromDate ?? _today);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: _today.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _accent,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: _primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
        if (_toDate != null && _toDate!.isBefore(picked)) _toDate = picked;
      } else {
        _toDate = picked;
      }
    });
  }

  // TEMP: date-range selection disabled — see build(). Uncomment to restore.
  /*
  void _setMode(bool range) {
    if (range == _isRange) return;
    setState(() {
      _isRange = range;
      if (!range) _toDate = null;
    });
  }
  */

  Future<void> _submit() async {
    if (_fromDate == null) {
      _showError('Please select a leave date.');
      return;
    }
    if (_isRange && _toDate == null) {
      _showError('Please select both from and to dates.');
      return;
    }
    final dates = _selectedDates;
    if (dates.length > _maxRangeDays) {
      _showError('Please request at most $_maxRangeDays days at a time.');
      return;
    }

    final reason = _reasonController.text;
    setState(() {
      _isSubmitting = true;
      _submitTotal = dates.length;
      _submitProgress = 0;
    });

    final succeeded = <DateTime>[];
    final failures = <MapEntry<DateTime, String>>[];
    final warnings = <DateTime>[];

    for (final date in dates) {
      final result =
          await ApiService.requestLeave(leaveDate: date, reason: reason);
      if (!mounted) return;
      if (result['success'] == true) {
        succeeded.add(date);
        final warning = result['warning']?.toString();
        if (warning != null && warning.isNotEmpty) warnings.add(date);
      } else {
        failures.add(MapEntry(
            date, result['message']?.toString() ?? 'Request failed.'));
      }
      setState(() => _submitProgress++);
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (succeeded.isEmpty) {
      // Nothing went through — surface the first failure inline.
      _showError(failures.isNotEmpty
          ? failures.first.value
          : 'Could not submit request.');
      return;
    }
    _showSummary(
        succeeded: succeeded, failures: failures, warnings: warnings);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSummary({
    required List<DateTime> succeeded,
    required List<MapEntry<DateTime, String>> failures,
    required List<DateTime> warnings,
  }) {
    final allOk = failures.isEmpty;
    final headline = succeeded.length == 1 && allOk
        ? 'Leave Requested!'
        : '${succeeded.length} of ${succeeded.length + failures.length} '
            'day${succeeded.length + failures.length == 1 ? '' : 's'} requested';

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: allOk ? _greenLight : _amberLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  allOk ? Icons.check_rounded : Icons.info_outline_rounded,
                  size: 32,
                  color: allOk ? _green : _amber,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              succeeded.length == 1
                  ? 'Your request is pending approval.'
                  : 'Your requests are pending approval.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: _textSecondary, height: 1.5),
            ),
            if (warnings.isNotEmpty) ...[
              const SizedBox(height: 14),
              _noticeBox(
                color: _amber,
                bg: _amberLight,
                icon: Icons.warning_amber_rounded,
                text:
                    'You have bookings on ${_joinDates(warnings)} that an admin '
                    'will need to reassign.',
              ),
            ],
            if (failures.isNotEmpty) ...[
              const SizedBox(height: 10),
              _noticeBox(
                color: _red,
                bg: const Color(0xFFFEF2F2),
                icon: Icons.error_outline_rounded,
                text: 'Skipped: '
                    '${_joinDates(failures.map((e) => e.key).toList())}. '
                    '${failures.first.value}',
              ),
            ],
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  String _joinDates(List<DateTime> dates) {
    final fmt = DateFormat('d MMM');
    return dates.map(fmt.format).join(', ');
  }

  Widget _noticeBox({
    required Color color,
    required Color bg,
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: color, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: _primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Request Leave',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _primary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // TEMP: date-range (multi-date) selection disabled for now — only
          // single-day leave is allowed. Re-enable by uncommenting these two
          // lines plus the _setMode / _buildModeToggle / _modeTab methods below.
          // _buildModeToggle(),
          // const SizedBox(height: 16),
          _buildSectionHeader(_isRange ? 'Leave Dates' : 'Leave Date'),
          const SizedBox(height: 10),
          _buildDateCard(),
          const SizedBox(height: 16),
          _buildSectionHeader('Reason (optional)'),
          const SizedBox(height: 10),
          _buildReasonField(),
          const SizedBox(height: 24),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  // TEMP: date-range selection disabled — see build(). Uncomment to restore.
  /*
  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          _modeTab(label: 'Single Day', selected: !_isRange, onTap: () => _setMode(false)),
          _modeTab(label: 'Date Range', selected: _isRange, onTap: () => _setMode(true)),
        ],
      ),
    );
  }

  Widget _modeTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _accent : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : _textSecondary,
            ),
          ),
        ),
      ),
    );
  }
  */

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildDateCard() {
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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_isRange)
            Row(
              children: [
                Expanded(
                  child: _datePicker(
                    label: 'From',
                    date: _fromDate,
                    icon: Icons.calendar_today_rounded,
                    onTap: () => _pickDate(isFrom: true),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 18, color: _textSecondary),
                ),
                Expanded(
                  child: _datePicker(
                    label: 'To',
                    date: _toDate,
                    icon: Icons.calendar_month_rounded,
                    onTap: () => _pickDate(isFrom: false),
                  ),
                ),
              ],
            )
          else
            _datePicker(
              label: 'Date',
              date: _fromDate,
              icon: Icons.event_rounded,
              onTap: () => _pickDate(isFrom: true),
              expanded: true,
            ),
          if (_dayCount > 0) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: _accentLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 15, color: _accent),
                  const SizedBox(width: 6),
                  Text(
                    '$_dayCount ${_dayCount == 1 ? 'day' : 'days'} of leave',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _datePicker({
    required String label,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
    bool expanded = false,
  }) {
    final selected = date != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _accent.withValues(alpha: 0.3) : _border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: selected ? _accent : _textSecondary),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: selected ? _accent : _textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              selected
                  ? DateFormat(expanded ? 'EEE, d MMM yyyy' : 'dd MMM yyyy')
                      .format(date)
                  : 'Select date',
              style: TextStyle(
                fontSize: expanded ? 15 : 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? _primary : _textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonField() {
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
      child: TextField(
        controller: _reasonController,
        maxLines: 5,
        maxLength: 500,
        style: const TextStyle(fontSize: 14, color: _primary, height: 1.5),
        decoration: InputDecoration(
          hintText: 'Add a short reason for your leave…',
          hintStyle: const TextStyle(fontSize: 14, color: _textSecondary),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _accent, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final progressLabel = _submitTotal > 1
        ? 'Submitting $_submitProgress/$_submitTotal…'
        : null;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _accent.withValues(alpha: 0.6),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  if (progressLabel != null) ...[
                    const SizedBox(width: 10),
                    Text(
                      progressLabel,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Submit Request',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
