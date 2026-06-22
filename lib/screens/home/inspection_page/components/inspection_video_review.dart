import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../widgets/inspection_field_info/components/reference_media_section.dart';

class InspectionVideoReview extends StatefulWidget {
  final String capturedMediaPath;
  final String fieldTitle;
  final String mediaLabel;
  final List<Map<String, dynamic>> referenceMedia;
  final VoidCallback onRetake;
  final void Function(int quarterTurns) onUseMedia;

  const InspectionVideoReview({
    super.key,
    required this.capturedMediaPath,
    required this.fieldTitle,
    required this.onRetake,
    required this.onUseMedia,
    this.referenceMedia = const [],
    this.mediaLabel = 'Video',
  });

  @override
  State<InspectionVideoReview> createState() => _InspectionVideoReviewState();
}

class _InspectionVideoReviewState extends State<InspectionVideoReview> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  String? _error;
  int _quarterTurns = 0;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(InspectionVideoReview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.capturedMediaPath != widget.capturedMediaPath) {
      _chewieController?.dispose();
      _videoController.dispose();
      setState(() {
        _quarterTurns = 0;
        _isInitialized = false;
        _error = null;
      });
      _initPlayer();
    }
  }

  Future<void> _initPlayer() async {
    try {
      _videoController = VideoPlayerController.file(File(widget.capturedMediaPath));
      await _videoController.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: true,
        aspectRatio: _videoController.value.aspectRatio,
        showControls: false,
      );
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  Widget _buildPlayer() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            Text(
              'Could not load ${widget.mediaLabel.toLowerCase()}',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white70));
    }
    return RotatedBox(
      quarterTurns: _quarterTurns,
      child: Chewie(controller: _chewieController!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final refUrl = widget.referenceMedia.isNotEmpty
        ? (widget.referenceMedia.first['url'] as String? ?? '')
        : '';
    final refMediaType = widget.referenceMedia.isNotEmpty
        ? (widget.referenceMedia.first['mediaType'] as String? ?? 'image')
            .toLowerCase()
        : 'image';

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: Colors.black),
        _buildPlayer(),
        // Top gradient
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.65), Colors.transparent],
              ),
            ),
          ),
        ),
        // Bottom gradient
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
              ),
            ),
          ),
        ),
        // Header
        Positioned(
          top: 16, left: 16, right: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review',
                      style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Does this look right?',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
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
        // Reference thumbnail — cache-aware so the guide shows from disk offline.
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
                child: refMediaType == 'video'
                    ? Container(
                        color: Colors.black87,
                        child: const Center(
                          child: Icon(Icons.play_circle_filled,
                              color: Colors.white70, size: 28),
                        ),
                      )
                    : CachedReferenceImage(
                        url: refUrl,
                        fit: BoxFit.cover,
                        // 80×60 dp container; 2× for retina.
                        cacheWidth: 160,
                        cacheHeight: 120,
                      ),
              ),
            ),
          ),
        // Rotate button + Retake / Use buttons
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
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: widget.onRetake,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retake', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => widget.onUseMedia(_quarterTurns),
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(
                        'Use ${widget.mediaLabel}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
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
