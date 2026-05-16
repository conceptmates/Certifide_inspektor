import 'package:flutter/material.dart';

class InspectionFlagIssuesSheet extends StatefulWidget {
  final String sectionTitle;
  final List<String> selectedIssues;
  final String notes;
  final List<String> availableIssues;
  // Optional color map: issue label → color from API colorCode
  final Map<String, Color>? issueColors;
  final void Function(List<String> issues, String notes, bool markedNoIssues)
      onConfirm;

  const InspectionFlagIssuesSheet({
    super.key,
    required this.sectionTitle,
    required this.selectedIssues,
    required this.notes,
    required this.availableIssues,
    this.issueColors,
    required this.onConfirm,
  });

  @override
  State<InspectionFlagIssuesSheet> createState() =>
      _InspectionFlagIssuesSheetState();
}

class _InspectionFlagIssuesSheetState extends State<InspectionFlagIssuesSheet> {
  List<String> get _issues => widget.availableIssues;

  late List<String> _selected;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedIssues);
    _notesController = TextEditingController(text: widget.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _toggle(String issue) {
    setState(() {
      if (_selected.contains(issue)) {
        _selected.remove(issue);
      } else {
        _selected.add(issue);
      }
    });
  }

  Color _chipColor(String issue) {
    return widget.issueColors?[issue] ?? const Color(0xFF4D9EFF);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.sectionTitle.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF4D9EFF),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Flag any issues',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              if (_issues.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Text(
                    'TAP TO ADD',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _issues.map((issue) {
                      final isSelected = _selected.contains(issue);
                      final color = _chipColor(issue);
                      return GestureDetector(
                        onTap: () => _toggle(issue),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.18)
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : Colors.white24,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                Icon(Icons.check,
                                    color: color, size: 13),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                issue,
                                style: TextStyle(
                                  color: isSelected
                                      ? color
                                      : Colors.white70,
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'NOTES (OPTIONAL)',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _notesController,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          maxLines: 3,
                          minLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'Add a note about what you noticed...',
                            hintStyle:
                                TextStyle(color: Colors.white38, fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.fromLTRB(14, 12, 8, 12),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 10, bottom: 10),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF4D9EFF).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.mic_outlined,
                              color: Color(0xFF4D9EFF), size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4D9EFF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onConfirm([], _notesController.text, true);
                    },
                    child: const Text(
                      'Mark as no issues',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              if (_selected.isNotEmpty) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onConfirm(
                            _selected, _notesController.text, false);
                      },
                      child: Text(
                        'Flag ${_selected.length} issue${_selected.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
