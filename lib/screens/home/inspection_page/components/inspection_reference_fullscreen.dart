import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: InteractiveViewer(
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
                    ),
                  );
                }

                if (mediaType == 'video') {
                  return _FullscreenVideoPlayer(url: url);
                }

                // Audio / link fallback
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        mediaType == 'audio'
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

// ── Video player (YouTube WebView or native Chewie) ──────────────────────────

class _FullscreenVideoPlayer extends StatelessWidget {
  final String url;
  const _FullscreenVideoPlayer({required this.url});

  static final _ytRegex = RegExp(
    r'^(?:https?://)?(?:www\.|m\.)?(?:youtube\.com/(?:watch\?.*v=|embed/|shorts/)|youtu\.be/)([\w-]{11})',
  );

  @override
  Widget build(BuildContext context) {
    final match = _ytRegex.firstMatch(url);
    final videoId = match?.group(1);
    if (videoId != null && videoId.isNotEmpty) {
      return _YouTubePlayer(videoId: videoId);
    }
    return _NativePlayer(url: url);
  }
}

// ── YouTube via WebView ──────────────────────────────────────────────────────

class _YouTubePlayer extends StatefulWidget {
  final String videoId;
  const _YouTubePlayer({required this.videoId});

  @override
  State<_YouTubePlayer> createState() => _YouTubePlayerState();
}

class _YouTubePlayerState extends State<_YouTubePlayer> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final u = request.url;
            if (u.startsWith('https://www.youtube.com/embed/') ||
                u.startsWith('https://www.youtube-nocookie.com/embed/')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadHtmlString(_html(widget.videoId));
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  String _html(String id) => '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
      html, body { margin:0; padding:0; background:#000; overflow:hidden; }
      .wrap { position:relative; width:100vw; height:100vh; }
      iframe { position:absolute; inset:0; width:100%; height:100%; border:0; }
    </style>
  </head>
  <body>
    <div class="wrap">
      <iframe
        src="https://www.youtube.com/embed/$id?autoplay=1&playsinline=1&rel=0&modestbranding=1"
        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
        allowfullscreen>
      </iframe>
    </div>
  </body>
</html>
''';

  @override
  Widget build(BuildContext context) {
    return Center(child: WebViewWidget(controller: _controller));
  }
}

// ── Native video via Chewie ──────────────────────────────────────────────────

class _NativePlayer extends StatefulWidget {
  final String url;
  const _NativePlayer({required this.url});

  @override
  State<_NativePlayer> createState() => _NativePlayerState();
}

class _NativePlayerState extends State<_NativePlayer> {
  VideoPlayerController? _vpc;
  ChewieController? _chewie;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _vpc = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _vpc!.initialize();
      _chewie = ChewieController(
        videoPlayerController: _vpc!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControlsOnInitialize: true,
      );
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = true; });
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _vpc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white70),
      );
    }
    if (_error || _chewie == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_outlined, color: Colors.white38, size: 48),
            SizedBox(height: 12),
            Text('Unable to load video',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      );
    }
    return Center(child: Chewie(controller: _chewie!));
  }
}
