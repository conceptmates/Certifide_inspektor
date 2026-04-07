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

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 140,
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.checklist_rtl,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Inspection Sections',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${sections.length} sections available',
                    style: TextStyle(
                      color: Colors.white.withAlpha(204),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: sections.length,
                  itemBuilder: (context, index) {
                    final section = sections[index];
                    final isSelected = currentSection == index;
                    final isCompleted = isSectionComplete(index);
                    final sectionTitle = section['title'] as String;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                              )
                            : null,
                        color: isSelected ? null : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : Theme.of(context).dividerColor.withAlpha(51),
                          width: 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF667eea).withAlpha(76),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.green.withAlpha(25)
                                : isSelected
                                    ? Colors.white.withAlpha(51)
                                    : Theme.of(context)
                                        .dividerColor
                                        .withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isCompleted
                                ? Icons.check_circle
                                : getSectionIcon(sectionTitle),
                            size: 20,
                            color: isCompleted
                                ? Colors.green
                                : isSelected
                                    ? Colors.white
                                    : Theme.of(context)
                                        .iconTheme
                                        .color
                                        ?.withAlpha(153),
                          ),
                        ),
                        trailing: isCompleted
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              )
                            : isSelected
                                ? const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                        title: Text(
                          sectionTitle,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        subtitle: Text(
                          '${(section['items'] as List).length} items',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white.withAlpha(204)
                                : Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withAlpha(153),
                          ),
                        ),
                        onTap: () => onSelectSection(index),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
