import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class InspectionVideoReview extends StatefulWidget {
  final String capturedMediaPath;
  final String fieldTitle;
  final String mediaLabel;
  final VoidCallback onRetake;
  final VoidCallback onUseMedia;

  const InspectionVideoReview({
    super.key,
    required this.capturedMediaPath,
    required this.fieldTitle,
    required this.onRetake,
    required this.onUseMedia,
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

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _videoController = VideoPlayerController.file(File(widget.capturedMediaPath));
      await _videoController.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController.value.aspectRatio,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF4D9EFF),
          handleColor: const Color(0xFF4D9EFF),
          bufferedColor: Colors.white30,
          backgroundColor: Colors.white12,
        ),
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: Colors.black),
        if (_error != null)
          Center(
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
          )
        else if (!_isInitialized)
          const Center(child: CircularProgressIndicator(color: Colors.white70))
        else
          Chewie(controller: _chewieController!),
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
            height: 180,
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
          child: const Column(
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
        // Retake / Use buttons
        Positioned(
          bottom: 16, left: 16, right: 16,
          child: Row(
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
                  onPressed: widget.onUseMedia,
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(
                    'Use ${widget.mediaLabel}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
