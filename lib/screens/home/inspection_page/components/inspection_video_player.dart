import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class InspectionVideoPlayer extends StatefulWidget {
  final String videoPath;
  final VoidCallback onReRecord;
  final VoidCallback onDiscard;

  const InspectionVideoPlayer({
    super.key,
    required this.videoPath,
    required this.onReRecord,
    required this.onDiscard,
  });

  @override
  State<InspectionVideoPlayer> createState() => _InspectionVideoPlayerState();
}

class _InspectionVideoPlayerState extends State<InspectionVideoPlayer> {
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
      _videoController = widget.videoPath.startsWith('http')
          ? VideoPlayerController.networkUrl(Uri.parse(widget.videoPath))
          : VideoPlayerController.file(File(widget.videoPath));

      await _videoController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: false,
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
    if (_error != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white54, size: 48),
              const SizedBox(height: 12),
              const Text('Could not load video',
                  style: TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.onReRecord,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Re-record'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: widget.onDiscard,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Discard'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF6B6B),
                      side: const BorderSide(color: Color(0xFFFF6B6B)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white70),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Chewie(controller: _chewieController!),
        Positioned(
          top: 12,
          right: 12,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _OverlayBadge(
                icon: Icons.delete_outline,
                label: 'Discard all',
                color: const Color(0xFFFF6B6B),
                onTap: widget.onDiscard,
              ),
              const SizedBox(width: 8),
              _OverlayBadge(
                icon: Icons.refresh,
                label: 'Re-record',
                color: Colors.white70,
                onTap: widget.onReRecord,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverlayBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OverlayBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
