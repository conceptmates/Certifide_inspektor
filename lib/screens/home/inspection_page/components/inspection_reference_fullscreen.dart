import 'package:flutter/material.dart';

class InspectionReferenceFullscreen extends StatefulWidget {
  final List<Map<String, dynamic>> mediaList;
  final int initialIndex;

  const InspectionReferenceFullscreen({
    super.key,
    required this.mediaList,
    this.initialIndex = 0,
  });

  @override
  State<InspectionReferenceFullscreen> createState() =>
      _InspectionReferenceFullscreenState();
}

class _InspectionReferenceFullscreenState
    extends State<InspectionReferenceFullscreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.mediaList.length;

    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Swipable media pages
            PageView.builder(
              controller: _pageController,
              itemCount: total,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (_, index) {
                final media = widget.mediaList[index];
                final mediaType =
                    (media['mediaType'] as String? ?? '').toLowerCase();
                final url = media['url'] as String? ?? '';

                if (url.isEmpty) {
                  return const Center(
                    child: Icon(Icons.broken_image,
                        size: 56, color: Colors.white30),
                  );
                }

                if (mediaType == 'image') {
                  return InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                                color: Colors.white70),
                          );
                        },
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image,
                              size: 56, color: Colors.white54),
                        ),
                      ),
                    ),
                  );
                }

                // Non-image media: show icon + link hint
                return Center(
                  child: Column(
                    
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        mediaType == 'video'
                            ? Icons.videocam_outlined
                            : mediaType == 'audio'
                                ? Icons.audiotrack_outlined
                                : Icons.link,
                        color: Colors.white54,
                        size: 56,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        mediaType.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                            letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        url,
                        style:
                            const TextStyle(color: Colors.white30, fontSize: 11),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),

            // Top bar: label + counter + close
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Text(
                        'REFERENCE',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Spacer(),
                      if (total > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_currentIndex + 1} / $total',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Swipe arrow hints (only when multiple)
            if (total > 1 && _currentIndex > 0)
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.chevron_left,
                        color: Colors.white70, size: 24),
                  ),
                ),
              ),
            if (total > 1 && _currentIndex < total - 1)
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.chevron_right,
                        color: Colors.white70, size: 24),
                  ),
                ),
              ),

            // Dot indicators at bottom
            if (total > 1)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(total, (i) {
                        final isActive = i == _currentIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF4D9EFF)
                                : Colors.white30,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
