import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../widgets/inspection_field_info/components/reference_media_section.dart';

class InspectionImageReview extends StatefulWidget {
  final String capturedImagePath;
  final String fieldTitle;
  final List<Map<String, dynamic>> referenceMedia;
  final VoidCallback onRetake;
  final void Function(int quarterTurns) onUsePhoto;

  const InspectionImageReview({
    super.key,
    required this.capturedImagePath,
    required this.fieldTitle,
    required this.referenceMedia,
    required this.onRetake,
    required this.onUsePhoto,
  });

  @override
  State<InspectionImageReview> createState() => _InspectionImageReviewState();
}

class _InspectionImageReviewState extends State<InspectionImageReview> {
  int _quarterTurns = 0;

  @override
  void didUpdateWidget(InspectionImageReview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.capturedImagePath != widget.capturedImagePath) {
      _quarterTurns = 0;
    }
  }

  Widget _buildImage() {
    final image = widget.capturedImagePath.startsWith('http')
        ? Image.network(widget.capturedImagePath,
            fit: BoxFit.contain, width: double.infinity, height: double.infinity)
        : Image.file(File(widget.capturedImagePath),
            fit: BoxFit.contain, width: double.infinity, height: double.infinity);

    return RotatedBox(quarterTurns: _quarterTurns, child: image);
  }

  @override
  Widget build(BuildContext context) {
    final refUrl = widget.referenceMedia.isNotEmpty
        ? (widget.referenceMedia.first['url'] as String? ?? '')
        : '';

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildImage(),
        // Dark gradient top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.65),
                  Colors.transparent
                ],
              ),
            ),
          ),
        ),
        // Dark gradient bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.85),
                  Colors.transparent
                ],
              ),
            ),
          ),
        ),
        // Header
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Does this look right?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: widget.onRetake,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
        // Reference thumbnail
        if (refUrl.isNotEmpty)
          Positioned(
            top: 80,
            left: 16,
            child: Container(
              width: 80,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.8),
                    width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                // Cache-aware so the guide thumbnail shows from disk offline.
                child: CachedReferenceImage(
                  url: refUrl,
                  fit: BoxFit.cover,
                  // 80×60 dp container; 2× for retina.
                  cacheWidth: 160,
                  cacheHeight: 120,
                ),
              ),
            ),
          ),
        // Rotate button + Retake / Use Photo buttons
        Positioned(
          bottom: 16 + MediaQuery.of(context).padding.bottom,
          left: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rotate button
              GestureDetector(
                onTap: () => setState(() => _quarterTurns = (_quarterTurns + 1) % 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.rotate_right, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Rotate',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Retake / Use Photo
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: widget.onRetake,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retake',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4D9EFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => widget.onUsePhoto(_quarterTurns),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Use Photo',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
