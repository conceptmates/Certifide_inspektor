import 'package:flutter/material.dart';

class InspectionBottomActions extends StatelessWidget {
  const InspectionBottomActions({
    super.key,
    required this.showPreviousSection,
    required this.isSubmitting,
    required this.isLastSection,
    required this.onPreviousSection,
    required this.onNextSection,
    required this.itemNavigationBar,
  });

  final bool showPreviousSection;
  final bool isSubmitting;
  final bool isLastSection;
  final VoidCallback onPreviousSection;
  final VoidCallback onNextSection;
  final Widget itemNavigationBar;

  @override
  Widget build(BuildContext context) {
    final buttonGradient = isLastSection
        ? const LinearGradient(colors: [Color(0xFF11998e), Color(0xFF38ef7d)])
        : const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]);

    final buttonShadowColor =
        (isLastSection ? const Color(0xFF11998e) : const Color(0xFF667eea))
            .withAlpha(102);

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          itemNavigationBar,
          if (showPreviousSection)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: isSubmitting ? null : onPreviousSection,
                  icon: const Icon(Icons.arrow_back, size: 20),
                  label: const Text('Previous section'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : const Color(0xFF667eea),
                    side: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white24
                          : const Color(0xFF667eea).withAlpha(128),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  gradient: buttonGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: buttonShadowColor,
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: isSubmitting ? null : onNextSection,
                  child: isSubmitting && isLastSection
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLastSection
                                  ? 'FINISH INSPECTION'
                                  : 'NEXT SECTION',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isLastSection
                                  ? Icons.check_circle_outline
                                  : Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
