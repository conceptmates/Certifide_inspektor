import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/attendance_record.dart';
import '../../models/leave_request.dart';
import '../../services/api_services.dart';

/// Admin-facing management view wired to the admin attendance/leave API:
///  • `GET  /api/admin/leaves`              — review requests
///  • `POST /api/admin/leaves/{id}/approve` — approve (+ surface conflicts)
///  • `POST /api/admin/leaves/{id}/reject`  — reject
///  • `GET  /api/admin/attendance`          — browse attendance records
class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen>
    with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFF0F172A);
  static const _accent = Color(0xFF3B82F6);
  static const _surface = Color(0xFFF8FAFC);
  static const _textSecondary = Color(0xFF64748B);

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: const Text(
          'Attendance & Leaves',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _primary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: _accent,
              unselectedLabelColor: _textSecondary,
              indicatorColor: _accent,
              indicatorWeight: 2.5,
              labelStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Leave Requests'),
                Tab(text: 'Attendance'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _LeavesTab(),
          _AttendanceTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────── Leaves tab ───────────────────────────────

class _LeavesTab extends StatefulWidget {
  const _LeavesTab();

  @override
  State<_LeavesTab> createState() => _LeavesTabState();
}

class _LeavesTabState extends State<_LeavesTab>
    with AutomaticKeepAliveClientMixin {
  static const _accent = Color(0xFF3B82F6);
  static const _textSecondary = Color(0xFF64748B);

  static const _statusFilters = ['all', 'pending', 'approved', 'rejected'];

  final _scrollController = ScrollController();
  final List<LeaveRequest> _leaves = [];

  String _status = 'pending';
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;
  final Set<int> _busyIds = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 240 &&
        !_loadingMore &&
        _hasMore &&
        !_loading) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
        _hasMore = true;
        _leaves.clear();
      });
    } else {
      if (_loadingMore) return;
      setState(() => _loadingMore = true);
    }

    final result = await ApiService.getAdminLeaves(
      page: _page,
      status: _status == 'all' ? null : _status,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final fetched = (result['leaves'] as List).cast<LeaveRequest>();
      final pagination = result['pagination'];
      final lastPage = (pagination?.lastPage as int?) ?? _page;
      setState(() {
        _leaves.addAll(fetched);
        _hasMore = _page < lastPage && fetched.isNotEmpty;
        if (_hasMore) _page++;
        _loading = false;
        _loadingMore = false;
      });
    } else {
      setState(() {
        _error = result['message']?.toString() ?? 'Something went wrong';
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _decide(LeaveRequest leave, {required bool approve}) async {
    final note = await _AdminNoteSheet.show(
      context,
      approve: approve,
      inspectorName: leave.inspectorName,
    );
    if (note == null) return; // cancelled

    setState(() => _busyIds.add(leave.id));
    final result = approve
        ? await ApiService.approveLeave(leave.id, adminNote: note)
        : await ApiService.rejectLeave(leave.id, adminNote: note);
    if (!mounted) return;
    setState(() => _busyIds.remove(leave.id));

    if (result['success'] == true) {
      final conflicts =
          (result['conflicting_bookings'] as List?)?.cast<String>() ??
              const [];
      setState(() {
        final idx = _leaves.indexWhere((l) => l.id == leave.id);
        if (idx != -1) {
          final updated = _leaves[idx].copyWith(
            status: approve ? 'approved' : 'rejected',
            adminNote: note,
            conflictingBookings: conflicts,
          );
          // Drop it from the list if the active filter no longer matches.
          if (_status != 'all' && _status != updated.status) {
            _leaves.removeAt(idx);
          } else {
            _leaves[idx] = updated;
          }
        }
      });

      if (conflicts.isNotEmpty) {
        await _showConflicts(conflicts);
      } else {
        _toast(
          result['message']?.toString() ??
              'Leave ${approve ? 'approved' : 'rejected'}.',
          color: approve ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
        );
      }
    } else {
      _toast(result['message']?.toString() ?? 'Action failed',
          color: const Color(0xFFEF4444));
    }
  }

  Future<void> _showConflicts(List<String> orders) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  size: 20, color: Color(0xFFF59E0B)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Bookings to Reassign',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A))),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Leave approved. The inspector has bookings on these dates that '
              'need reassigning:',
              style: TextStyle(
                  fontSize: 13, color: _textSecondary, height: 1.5),
            ),
            const SizedBox(height: 14),
            ...orders.map(
              (o) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        size: 16, color: _accent),
                    const SizedBox(width: 8),
                    Text(o,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A))),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        _FilterChipsBar(
          options: _statusFilters,
          selected: _status,
          labelOf: (s) => s == 'all' ? 'All' : _capitalize(s),
          onSelected: (s) {
            if (s == _status) return;
            setState(() => _status = s);
            _load(reset: true);
          },
        ),
        Expanded(
          child: RefreshIndicator(
            color: _accent,
            onRefresh: () => _load(reset: true),
            child: _buildBody(),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const _CenteredLoader();
    }
    if (_error != null && _leaves.isEmpty) {
      return _ErrorState(message: _error!, onRetry: () => _load(reset: true));
    }
    if (_leaves.isEmpty) {
      return const _EmptyState(
        icon: Icons.event_available_rounded,
        title: 'No leave requests',
        subtitle: 'Requests matching this filter will appear here.',
      );
    }
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _leaves.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        if (i >= _leaves.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            ),
          );
        }
        final leave = _leaves[i];
        return _LeaveCard(
          leave: leave,
          busy: _busyIds.contains(leave.id),
          onApprove: () => _decide(leave, approve: true),
          onReject: () => _decide(leave, approve: false),
        );
      },
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _LeaveCard extends StatelessWidget {
  const _LeaveCard({
    required this.leave,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final LeaveRequest leave;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  static const _primary = Color(0xFF0F172A);
  static const _accent = Color(0xFF3B82F6);
  static const _textSecondary = Color(0xFF64748B);
  static const _green = Color(0xFF10B981);
  static const _red = Color(0xFFEF4444);
  static const _redLight = Color(0xFFFEF2F2);

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(name: leave.inspectorName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leave.inspectorName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                    if (leave.inspectorEmail.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        leave.inspectorEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: _textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              _StatusPill(status: leave.status),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.event_rounded,
                      size: 20, color: _accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Leave date',
                        style: TextStyle(fontSize: 11, color: _textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        leave.leaveDate != null
                            ? DateFormat('EEE, d MMM yyyy')
                                .format(leave.leaveDate!)
                            : 'Date not set',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_relativeLabel(leave.leaveDate) != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _relativeLabel(leave.leaveDate)!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _accent,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (leave.reason.isNotEmpty ||
              (leave.adminNote != null && leave.adminNote!.isNotEmpty)) ...[
            const SizedBox(height: 10),
            _CollapsibleDetails(
              reason: leave.reason.isNotEmpty ? leave.reason : null,
              adminNote: (leave.adminNote != null && leave.adminNote!.isNotEmpty)
                  ? leave.adminNote
                  : null,
            ),
          ],
          if (leave.conflictingBookings.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _redLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_busy_rounded, size: 14, color: _red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${leave.conflictingBookings.length} booking(s) to '
                      'reassign: ${leave.conflictingBookings.join(', ')}',
                      style: const TextStyle(fontSize: 12, color: _red),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (leave.isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Reject',
                    icon: Icons.close_rounded,
                    color: _red,
                    bg: _redLight,
                    busy: busy,
                    onTap: onReject,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'Approve',
                    icon: Icons.check_rounded,
                    color: Colors.white,
                    bg: _green,
                    filled: true,
                    busy: busy,
                    onTap: onApprove,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// A short, human-friendly hint of how far away the leave date is.
  String? _relativeLabel(DateTime? date) {
    if (date == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 1) return 'In $diff days';
    return '${-diff} days ago';
  }
}

/// Compact, single collapsible row holding both the reason and the admin note.
/// Collapsed it shows one inline preview line; expanded it reveals the full
/// reason and, beneath it, the admin note.
class _CollapsibleDetails extends StatefulWidget {
  const _CollapsibleDetails({this.reason, this.adminNote});

  final String? reason;
  final String? adminNote;

  @override
  State<_CollapsibleDetails> createState() => _CollapsibleDetailsState();
}

class _CollapsibleDetailsState extends State<_CollapsibleDetails> {
  static const _primary = Color(0xFF0F172A);
  static const _surface = Color(0xFFF8FAFC);
  static const _textSecondary = Color(0xFF64748B);
  static const _amber = Color(0xFFF59E0B);
  static const _amberLight = Color(0xFFFFFBEB);

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hasReason = widget.reason != null;
    final hasNote = widget.adminNote != null;
    // The collapsed preview prefers the reason, falling back to the note.
    final previewLabel = hasReason ? 'Reason' : 'Admin note';
    final previewText = hasReason ? widget.reason! : widget.adminNote!;
    final previewColor = hasReason ? _textSecondary : _amber;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      behavior: HitTestBehavior.opaque,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(hasReason ? Icons.notes_rounded : Icons.sticky_note_2_outlined,
                      size: 13, color: previewColor),
                  const SizedBox(width: 5),
                  Text(
                    '$previewLabel:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: previewColor,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      // When expanded the reason flows in full below, so the
                      // inline preview is only meaningful while collapsed.
                      previewText,
                      maxLines: 1,
                      overflow:
                          _expanded ? TextOverflow.clip : TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: _expanded ? Colors.transparent : _primary,
                        height: 1.3,
                      ),
                    ),
                  ),
                  // A tiny hint that there's also an admin note tucked away.
                  if (!_expanded && hasReason && hasNote) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _amberLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'note',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _amber,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 2),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: previewColor),
                  ),
                ],
              ),
              if (_expanded) ...[
                if (hasReason)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      widget.reason!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: _primary,
                        height: 1.4,
                      ),
                    ),
                  ),
                if (hasNote) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 7),
                    decoration: BoxDecoration(
                      color: _amberLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.sticky_note_2_outlined,
                            size: 13, color: _amber),
                        const SizedBox(width: 5),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Admin note: ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _amber,
                                  ),
                                ),
                                TextSpan(
                                  text: widget.adminNote!,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: _amber,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── Attendance tab ─────────────────────────────

class _AttendanceTab extends StatefulWidget {
  const _AttendanceTab();

  @override
  State<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<_AttendanceTab>
    with AutomaticKeepAliveClientMixin {
  static const _primary = Color(0xFF0F172A);
  static const _accent = Color(0xFF3B82F6);

  static const _typeFilters = ['all', 'available', 'working'];

  final _scrollController = ScrollController();
  final List<AttendanceRecord> _records = [];

  String _type = 'all';
  DateTime? _date;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 240 &&
        !_loadingMore &&
        _hasMore &&
        !_loading) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
        _hasMore = true;
        _records.clear();
      });
    } else {
      if (_loadingMore) return;
      setState(() => _loadingMore = true);
    }

    final result = await ApiService.getAdminAttendance(
      page: _page,
      type: _type == 'all' ? null : _type,
      date: _date,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final fetched = (result['records'] as List).cast<AttendanceRecord>();
      final pagination = result['pagination'];
      final lastPage = (pagination?.lastPage as int?) ?? _page;
      setState(() {
        _records.addAll(fetched);
        _hasMore = _page < lastPage && fetched.isNotEmpty;
        if (_hasMore) _page++;
        _loading = false;
        _loadingMore = false;
      });
    } else {
      setState(() {
        _error = result['message']?.toString() ?? 'Something went wrong';
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
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
    setState(() => _date = picked);
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: _FilterChipsBar(
                  padding: EdgeInsets.zero,
                  options: _typeFilters,
                  selected: _type,
                  labelOf: (s) => s == 'all' ? 'All' : _capitalize(s),
                  onSelected: (s) {
                    if (s == _type) return;
                    setState(() => _type = s);
                    _load(reset: true);
                  },
                ),
              ),
              const SizedBox(width: 8),
              _DateFilterButton(
                date: _date,
                onPick: _pickDate,
                onClear: _date == null
                    ? null
                    : () {
                        setState(() => _date = null);
                        _load(reset: true);
                      },
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: _accent,
            onRefresh: () => _load(reset: true),
            child: _buildBody(),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) return const _CenteredLoader();
    if (_error != null && _records.isEmpty) {
      return _ErrorState(message: _error!, onRetry: () => _load(reset: true));
    }
    if (_records.isEmpty) {
      return const _EmptyState(
        icon: Icons.fact_check_outlined,
        title: 'No attendance records',
        subtitle: 'Records matching these filters will appear here.',
      );
    }
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _records.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i >= _records.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            ),
          );
        }
        return _AttendanceCard(record: _records[i]);
      },
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.record});

  final AttendanceRecord record;

  static const _primary = Color(0xFF0F172A);
  static const _accent = Color(0xFF3B82F6);
  static const _surface = Color(0xFFF8FAFC);
  static const _textSecondary = Color(0xFF64748B);
  static const _green = Color(0xFF10B981);
  static const _greenLight = Color(0xFFECFDF5);
  static const _amber = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final working = record.isWorking;
    final typeColor = working ? _accent : _green;
    final typeBg = working ? const Color(0xFFEFF6FF) : _greenLight;

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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(name: record.inspectorName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.inspectorName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.date != null
                          ? DateFormat('EEE, d MMM yyyy').format(record.date!)
                          : 'Date unknown',
                      style:
                          const TextStyle(fontSize: 12, color: _textSecondary),
                    ),
                  ],
                ),
              ),
              _Tag(
                label: working ? 'Working' : 'Available',
                color: typeColor,
                bg: typeBg,
                icon: working
                    ? Icons.work_outline_rounded
                    : Icons.event_available_rounded,
              ),
            ],
          ),
          if (working || record.checkIn != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _MetricCell(
                      icon: Icons.login_rounded,
                      color: _green,
                      label: 'Check In',
                      value: _time(record.checkIn),
                    ),
                  ),
                  _divider(),
                  Expanded(
                    child: _MetricCell(
                      icon: Icons.logout_rounded,
                      color: const Color(0xFFEF4444),
                      label: 'Check Out',
                      value: _time(record.checkOut),
                    ),
                  ),
                  _divider(),
                  Expanded(
                    child: _MetricCell(
                      icon: Icons.timer_outlined,
                      color: _accent,
                      label: 'Duration',
                      value: _durationText(record.duration),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (record.hasLocation) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 14, color: _amber),
                const SizedBox(width: 6),
                Text(
                  '${record.latitude!.toStringAsFixed(5)}, '
                  '${record.longitude!.toStringAsFixed(5)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _amber,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 30,
        color: const Color(0xFFE2E8F0),
        margin: const EdgeInsets.symmetric(horizontal: 8),
      );

  String _time(DateTime? dt) =>
      dt == null ? '--:--' : DateFormat('hh:mm a').format(dt);

  String _durationText(Duration? d) =>
      d == null ? '--' : '${d.inHours}h ${d.inMinutes.remainder(60)}m';
}

// ─────────────────────────── Shared sub-widgets ───────────────────────────

class _FilterChipsBar extends StatelessWidget {
  const _FilterChipsBar({
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 4),
  });

  final List<String> options;
  final String selected;
  final String Function(String) labelOf;
  final ValueChanged<String> onSelected;
  final EdgeInsets padding;

  static const _accent = Color(0xFF3B82F6);
  static const _primary = Color(0xFF0F172A);
  static const _surface = Color(0xFFF8FAFC);
  static const _border = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: options.map((o) {
          final isSel = o == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(o),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSel ? _accent : _surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSel ? _accent : _border),
                ),
                child: Text(
                  labelOf(o),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSel ? Colors.white : _primary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DateFilterButton extends StatelessWidget {
  const _DateFilterButton({
    required this.date,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? date;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  static const _accent = Color(0xFF3B82F6);
  static const _accentLight = Color(0xFFEFF6FF);
  static const _surface = Color(0xFFF8FAFC);
  static const _border = Color(0xFFE2E8F0);
  static const _textSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final active = date != null;
    return GestureDetector(
      onTap: active ? onClear : onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _accentLight : _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? _accent : _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(active ? Icons.close_rounded : Icons.calendar_today_rounded,
                size: 14, color: active ? _accent : _textSecondary),
            const SizedBox(width: 6),
            Text(
              active ? DateFormat('d MMM').format(date!) : 'Date',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? _accent : _textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    final color = _colorFor(name);
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  static Color _colorFor(String name) {
    const palette = [
      Color(0xFF3B82F6),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFF06B6D4),
    ];
    if (name.isEmpty) return palette.first;
    return palette[name.codeUnitAt(0) % palette.length];
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    late Color color;
    late Color bg;
    late IconData icon;
    switch (s) {
      case 'approved':
        color = const Color(0xFF10B981);
        bg = const Color(0xFFECFDF5);
        icon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        color = const Color(0xFFEF4444);
        bg = const Color(0xFFFEF2F2);
        icon = Icons.cancel_rounded;
        break;
      default:
        color = const Color(0xFFF59E0B);
        bg = const Color(0xFFFFFBEB);
        icon = Icons.hourglass_top_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            s.isEmpty ? 'Pending' : '${s[0].toUpperCase()}${s.substring(1)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.color,
    required this.bg,
    required this.icon,
  });

  final String label;
  final Color color;
  final Color bg;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  static const _primary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _primary,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: _textSecondary),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
    this.filled = false,
    this.busy = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  final bool filled;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: busy
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      filled ? Colors.white : color,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  static const _primary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.18),
        Icon(icon, size: 56, color: const Color(0xFFCBD5E1)),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _primary,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, color: _textSecondary, height: 1.5),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  static const _accent = Color(0xFF3B82F6);
  static const _primary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.16),
        const Icon(Icons.cloud_off_rounded, size: 56, color: Color(0xFFCBD5E1)),
        const SizedBox(height: 16),
        const Text(
          'Couldn\'t load data',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _primary,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, color: _textSecondary, height: 1.5),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _accent,
              side: const BorderSide(color: _accent),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet that confirms an approve/reject and collects an optional
/// `admin_note`. Returns the note string (possibly empty) on confirm, or
/// `null` if the admin cancelled.
class _AdminNoteSheet extends StatefulWidget {
  const _AdminNoteSheet({required this.approve, required this.inspectorName});

  final bool approve;
  final String inspectorName;

  static Future<String?> show(
    BuildContext context, {
    required bool approve,
    required String inspectorName,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _AdminNoteSheet(approve: approve, inspectorName: inspectorName),
    );
  }

  @override
  State<_AdminNoteSheet> createState() => _AdminNoteSheetState();
}

class _AdminNoteSheetState extends State<_AdminNoteSheet> {
  static const _primary = Color(0xFF0F172A);
  static const _surface = Color(0xFFF8FAFC);
  static const _textSecondary = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);
  static const _green = Color(0xFF10B981);
  static const _red = Color(0xFFEF4444);

  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final approve = widget.approve;
    final accent = approve ? _green : _red;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    approve ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        approve ? 'Approve Leave' : 'Reject Leave',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'For ${widget.inspectorName}',
                        style: const TextStyle(
                            fontSize: 13, color: _textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Note (optional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 3,
              maxLength: 250,
              style: const TextStyle(fontSize: 14, color: _primary),
              decoration: InputDecoration(
                hintText: approve
                    ? 'Add a note for the inspector…'
                    : 'Reason for rejection…',
                hintStyle:
                    const TextStyle(fontSize: 14, color: _textSecondary),
                filled: true,
                fillColor: _surface,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: _textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(context, _controller.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      approve ? 'Approve' : 'Reject',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
