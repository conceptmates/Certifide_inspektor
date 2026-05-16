import 'package:flutter/material.dart';

class InspectionSectionsDrawer extends StatefulWidget {
  const InspectionSectionsDrawer({
    super.key,
    required this.sections,
    required this.currentSection,
    required this.isSectionComplete,
    required this.getSectionIcon,
    required this.onSelectSection,
    required this.onSelectField,
  });

  final List<Map<String, dynamic>> sections;
  final int currentSection;
  final bool Function(int index) isSectionComplete;
  final IconData Function(String title) getSectionIcon;
  final ValueChanged<int> onSelectSection;
  final void Function(int sectionIndex, int fieldIndex) onSelectField;

  @override
  State<InspectionSectionsDrawer> createState() =>
      _InspectionSectionsDrawerState();
}

class _InspectionSectionsDrawerState extends State<InspectionSectionsDrawer> {
  final Set<int> _expandedSections = {};

  static const _accent = Color(0xFF448AFF);
  static const _accentFill = Color(0x1A448AFF);
  static const _textPrimary = Color(0xFF111827);
  static const _border = Color(0xFFE4E7EB);
  static const _surfaceHigh = Color(0xFFF0F2F5);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.layers_outlined, color: _accent, size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    'Sections',
                    style: TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.sections.length} total',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            const Divider(color: _border, height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: widget.sections.length,
                itemBuilder: (context, index) {
                  final section = widget.sections[index];
                  final isActive = widget.currentSection == index;
                  final isCompleted = widget.isSectionComplete(index);
                  final sectionTitle = section['title'] as String;
                  final items = section['items'] as List;
                  final itemCount = items.length;
                  final isExpanded = _expandedSections.contains(index);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.only(
                          left: 12,
                          right: 4,
                          top: 2,
                          bottom: 2,
                        ),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.green.withValues(alpha: 0.12)
                                : isActive
                                    ? _accent.withValues(alpha: 0.12)
                                    : _surfaceHigh,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            isCompleted
                                ? Icons.check_circle_outline
                                : widget.getSectionIcon(sectionTitle),
                            color: isCompleted
                                ? Colors.green
                                : isActive
                                    ? _accent
                                    : Colors.grey[500],
                            size: 18,
                          ),
                        ),
                        title: Text(
                          sectionTitle,
                          style: TextStyle(
                            color: isActive ? _accent : _textPrimary,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '$itemCount field${itemCount == 1 ? '' : 's'}',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.expand_more_rounded,
                              color: isActive ? _accent : Colors.grey[500],
                              size: 20,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedSections.remove(index);
                              } else {
                                _expandedSections.add(index);
                              }
                            });
                          },
                          splashRadius: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                        selected: isActive,
                        selectedTileColor: _accentFill,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        onTap: () => widget.onSelectSection(index),
                      ),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: _buildFieldList(
                            index, items, isActive, isCompleted),
                        crossFadeState: isExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 200),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldList(
    int sectionIndex,
    List items,
    bool isSectionActive,
    bool isSectionComplete,
  ) {
    return Container(
      margin: const EdgeInsets.only(left: 48, right: 8, bottom: 4),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isSectionComplete
                ? Colors.green.withValues(alpha: 0.4)
                : isSectionActive
                    ? _accent.withValues(alpha: 0.4)
                    : _border,
            width: 2,
          ),
        ),
      ),
      child: Column(
        children: List.generate(items.length, (fieldIndex) {
          final item = items[fieldIndex] as Map<String, dynamic>;
          final title = item['title'] as String? ?? 'Field ${fieldIndex + 1}';

          return InkWell(
            onTap: () => widget.onSelectField(sectionIndex, fieldIndex),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _surfaceHigh,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                      child: Text(
                        '${fieldIndex + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
