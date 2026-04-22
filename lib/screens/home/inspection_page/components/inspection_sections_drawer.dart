import 'package:flutter/material.dart';

class InspectionSectionsDrawer extends StatelessWidget {
  const InspectionSectionsDrawer({
    super.key,
    required this.sections,
    required this.currentSection,
    required this.isSectionComplete,
    required this.getSectionIcon,
    required this.onSelectSection,
  });

  final List<Map<String, dynamic>> sections;
  final int currentSection;
  final bool Function(int index) isSectionComplete;
  final IconData Function(String title) getSectionIcon;
  final ValueChanged<int> onSelectSection;

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
                  const Icon(
                    Icons.layers_outlined,
                    color: _accent,
                    size: 20,
                  ),
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
                    '${sections.length} total',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            const Divider(color: _border, height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  final section = sections[index];
                  final isActive = currentSection == index;
                  final isCompleted = isSectionComplete(index);
                  final sectionTitle = section['title'] as String;
                  final itemCount = (section['items'] as List).length;

                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
                            : getSectionIcon(sectionTitle),
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
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    selected: isActive,
                    selectedTileColor: _accentFill,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onTap: () => onSelectSection(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
