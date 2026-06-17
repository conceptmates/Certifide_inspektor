import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../utils/media_url.dart';

class ReferenceMediaSectionView extends StatelessWidget {
  final List<Map<String, dynamic>> mediaList;
  final double imageHeight;

  /// When set, only this many items are shown inline. Remaining are in the sheet.
  final int? maxItems;

  /// Optional widget placed at the far right of the "Reference Media" header row.
  final Widget? trailing;

  const ReferenceMediaSectionView({
    super.key,
    required this.mediaList,
    this.imageHeight = 340,
    this.maxItems,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final visibleItems = maxItems != null
        ? mediaList.take(maxItems!).toList()
        : mediaList;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.red.withAlpha(20)
            : const Color(0xFFFF6B6B).withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withAlpha(76),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.perm_media_outlined,
                color: Color(0xFFFF6B6B),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Reference Media',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF6B6B),
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          ...visibleItems.map((media) {
            final mediaType =
                (media['mediaType'] as String? ?? '').toLowerCase();
            final url = media['url'] as String? ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withAlpha(51),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (mediaType == 'image' && url.isNotEmpty)
                    InkWell(
                      onTap: () => _showFullscreenImage(context, url),
                      child: Image.network(
                        url,
                        width: double.infinity,
                        height: imageHeight,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return SizedBox(
                            height: imageHeight,
                            child: Center(
                              child: CircularProgressIndicator.adaptive(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.broken_image,
                                  size: 40, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                  if (mediaType == 'video' && url.isNotEmpty)
                    _InlineVideoPlayer(url: url),
                  if (mediaType == 'audio' && url.isNotEmpty)
                    _InlineAudioPlayer(url: url),
                  if (mediaType == 'link' && url.isNotEmpty)
                    InkWell(
                      onTap: () async {
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.link,
                                color: Colors.blue, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                url,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.open_in_new,
                                color: Colors.blue, size: 18),
                          ],
                        ),
                      ),
                    ),
                  _DescriptionBox(description: media['description'] as String?),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Row(
                      children: [
                        Icon(
                          mediaType == 'image'
                              ? Icons.image
                              : mediaType == 'video'
                                  ? Icons.videocam
                                  : mediaType == 'audio'
                                      ? Icons.audiotrack
                                      : Icons.link,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          mediaType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Tap the media expand',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showFullscreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog.fullscreen(
          child: Stack(
            children: [
              Container(
                color: Colors.black,
                width: double.infinity,
                height: double.infinity,
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 56,
                            color: Colors.white70,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: SafeArea(
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InlineVideoPlayer extends StatelessWidget {
  final String url;
  const _InlineVideoPlayer({required this.url});

  static final _ytRegex = RegExp(
    r'^(?:https?://)?(?:www\.|m\.)?(?:youtube\.com/(?:watch\?.*v=|embed/|shorts/)|youtu\.be/)([\w-]{11})',
  );

  @override
  Widget build(BuildContext context) {
    final match = _ytRegex.firstMatch(url);
    final videoId = match?.group(1);
    if (videoId != null && videoId.isNotEmpty) {
      return _YouTubeWebViewPlayer(videoId: videoId);
    }
    return _NativeVideoPlayer(url: url);
  }
}

class _YouTubeWebViewPlayer extends StatefulWidget {
  final String videoId;
  const _YouTubeWebViewPlayer({required this.videoId});

  @override
  State<_YouTubeWebViewPlayer> createState() => _YouTubeWebViewPlayerState();
}

class _YouTubeWebViewPlayerState extends State<_YouTubeWebViewPlayer> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;
            if (url.startsWith('https://www.youtube.com/embed/') ||
                url.startsWith('https://www.youtube-nocookie.com/embed/')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadHtmlString(_youtubeHtml(widget.videoId));
  }

  String _youtubeHtml(String videoId) => '''
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
        src="https://www.youtube.com/embed/$videoId?playsinline=1&rel=0&modestbranding=1"
        title="YouTube video player"
        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
        allowfullscreen>
      </iframe>
    </div>
  </body>
</html>
''';

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          WebViewWidget(controller: _controller),
          Positioned(
            right: 8,
            top: 8,
            child: Material(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          _FullscreenYouTubePlayer(videoId: widget.videoId),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.fullscreen, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullscreenYouTubePlayer extends StatefulWidget {
  final String videoId;
  const _FullscreenYouTubePlayer({required this.videoId});

  @override
  State<_FullscreenYouTubePlayer> createState() =>
      _FullscreenYouTubePlayerState();
}

class _FullscreenYouTubePlayerState extends State<_FullscreenYouTubePlayer> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..loadRequest(Uri.parse(
          'https://www.youtube.com/embed/${widget.videoId}?autoplay=1&playsinline=1&rel=0&modestbranding=1'));
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(child: WebViewWidget(controller: _controller)),
            Positioned(
              top: 12,
              left: 12,
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NativeVideoPlayer extends StatefulWidget {
  final String url;
  const _NativeVideoPlayer({required this.url});

  @override
  State<_NativeVideoPlayer> createState() => _NativeVideoPlayerState();
}

class _NativeVideoPlayerState extends State<_NativeVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    // Normalise the URL so spaces / special characters in admin-uploaded
    // filenames don't make the native player reject the source. See mediaUri().
    final controller = VideoPlayerController.networkUrl(mediaUri(widget.url));
    _videoController = controller;
    try {
      // Guard against the player hanging forever on an unreachable / malformed
      // source — otherwise the user is stuck on an endless spinner.
      await controller.initialize().timeout(const Duration(seconds: 30));
      // On iOS initialize() can complete even when the asset failed to load,
      // so check the controller's own error state too.
      if (controller.value.hasError) {
        throw Exception(
            controller.value.errorDescription ?? 'Video failed to load');
      }
      // Surface errors that only appear after playback starts (e.g. an
      // unsupported codec) instead of silently freezing.
      controller.addListener(_onControllerUpdate);
      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControlsOnInitialize: true,
      );
      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Unable to load video';
        });
      }
    }
  }

  void _onControllerUpdate() {
    final controller = _videoController;
    if (controller != null &&
        controller.value.hasError &&
        _error == null &&
        mounted) {
      setState(() => _error = 'Unable to load video');
    }
  }

  Future<void> _retry() async {
    _videoController?.removeListener(_onControllerUpdate);
    _chewieController?.dispose();
    await _videoController?.dispose();
    _chewieController = null;
    _videoController = null;
    await _init();
  }

  @override
  void dispose() {
    _videoController?.removeListener(_onControllerUpdate);
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _chewieController == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black12,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_off_outlined,
                    size: 40, color: Colors.grey),
                const SizedBox(height: 8),
                const Text('Unable to load video',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Chewie(controller: _chewieController!),
    );
  }
}

class _DescriptionBox extends StatelessWidget {
  final String? description;
  const _DescriptionBox({this.description});

  static final _urlRegex = RegExp(
    r'https?://[^\s]+',
    caseSensitive: false,
  );

  bool get _isUrl =>
      description != null && _urlRegex.hasMatch(description!.trim());

  String get _firstUrl {
    final match = _urlRegex.firstMatch(description!.trim());
    return match?.group(0) ?? description!.trim();
  }

  @override
  Widget build(BuildContext context) {
    if (description == null || description!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final isUrl = _isUrl;

    Future<void> launch() async {
      final uri = Uri.parse(_firstUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: isUrl
            ? Colors.blue.withAlpha(15)
            : Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUrl
              ? Colors.blue.withAlpha(60)
              : Theme.of(context).dividerColor.withAlpha(40),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              description!.trim(),
              style: TextStyle(
                fontSize: 13,
                color: isUrl ? Colors.blue : Theme.of(context).textTheme.bodyMedium?.color,
                decoration: isUrl ? TextDecoration.underline : null,
                decorationColor: Colors.blue,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isUrl)
            IconButton(
              onPressed: launch,
              icon: const Icon(Icons.open_in_new, size: 18, color: Colors.blue),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(8),
              tooltip: 'Open link',
            ),
        ],
      ),
    );
  }
}

class _InlineAudioPlayer extends StatefulWidget {
  final String url;
  const _InlineAudioPlayer({required this.url});

  @override
  State<_InlineAudioPlayer> createState() => _InlineAudioPlayerState();
}

class _InlineAudioPlayerState extends State<_InlineAudioPlayer> {
  final ja.AudioPlayer _player = ja.AudioPlayer();
  bool _loading = true;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _player.setUrl(widget.url);
      _duration = _player.duration ?? Duration.zero;
      _player.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _player.playerStateStream.listen((state) {
        if (!mounted) return;
        setState(() {
          _playing = state.playing;
        });
      });
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to load audio';
        });
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Unable to load audio'),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () async {
                            if (_playing) {
                              await _player.pause();
                            } else {
                              await _player.play();
                            }
                          },
                          icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                        ),
                        Expanded(
                          child: Slider(
                            min: 0,
                            max: (_duration.inMilliseconds > 0
                                    ? _duration.inMilliseconds
                                    : 1)
                                .toDouble(),
                            value: _position.inMilliseconds
                                .clamp(
                                    0,
                                    _duration.inMilliseconds > 0
                                        ? _duration.inMilliseconds
                                        : 1)
                                .toDouble(),
                            onChanged: (v) =>
                                _player.seek(Duration(milliseconds: v.toInt())),
                          ),
                        ),
                      ],
                    ),
                    Text('${_fmt(_position)} / ${_fmt(_duration)}'),
                  ],
                ),
    );
  }
}
