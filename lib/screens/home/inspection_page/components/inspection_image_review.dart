import 'dart:io';
import 'package:flutter/material.dart';

class InspectionImageReview extends StatelessWidget {
  final String capturedImagePath;
  final String fieldTitle;
  final List<Map<String, dynamic>> referenceMedia;
  final VoidCallback onRetake;
  final VoidCallback onUsePhoto;

  const InspectionImageReview({
    super.key,
    required this.capturedImagePath,
    required this.fieldTitle,
    required this.referenceMedia,
    required this.onRetake,
    required this.onUsePhoto,
  });

  Widget _buildImage() {
    if (capturedImagePath.startsWith('http')) {
      return Image.network(capturedImagePath,
          fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }
    return Image.file(File(capturedImagePath),
        fit: BoxFit.cover, width: double.infinity, height: double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    final refUrl = referenceMedia.isNotEmpty
        ? (referenceMedia.first['url'] as String? ?? '')
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
            height: 180,
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
        // "Does this look right?" header
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
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
        // Reference thumbnail (top-left, below header)
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
                child: Image.network(
                  refUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.grey[800]),
                ),
              ),
            ),
          ),
        // Retake / Use Photo buttons
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Row(
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
                  onPressed: onRetake,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retake',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
                  onPressed: onUsePhoto,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Use Photo',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
