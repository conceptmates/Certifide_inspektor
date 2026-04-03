import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../constants/inspection_field_explanations.dart';

class InspectionFieldInfoSheet {
  static void show({
    required BuildContext context,
    required String fieldId,
    String? customTitle,
    String? customExplanation,
    List<Map<String, dynamic>> referenceMedia = const [],
  }) {
    final explanation = InspectionFieldExplanations.getExplanation(fieldId);
    final title = customTitle ?? explanation?['title'] ?? fieldId;
    final explanationText = customExplanation ??
        explanation?['explanation'] ??
        'No explanation available for this field.';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(51),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Field Information',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor.withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                color: Theme.of(context).dividerColor.withAlpha(128),
                thickness: 1,
                height: 1,
              ),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (referenceMedia.isNotEmpty) ...[
                        ReferenceMediaSection(mediaList: referenceMedia),
                        const SizedBox(height: 24),
                      ],

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[850]?.withAlpha(102)
                              : const Color(0xFF667eea).withAlpha(25),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF667eea).withAlpha(76),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.search_outlined,
                                  color: Color(0xFF667eea),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'What to inspect',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF667eea),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              explanationText,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.orange.withAlpha(25)
                              : Colors.orange.withAlpha(25),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orange.withAlpha(76),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Where to find this',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _getLocationGuide(fieldId),
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _getLocationGuide(String fieldId) {
    switch (fieldId.toLowerCase()) {
      case 'location':
        return 'Record the complete address where the inspection is taking place - building name/number, street, area, city, and pincode.';
      case 'frontview':
        return 'Stand 3-4 feet in front of the vehicle, center yourself with the front grille, and capture the entire front including bumper to hood.';
      case 'rearview':
        return 'Position yourself 3-4 feet behind the vehicle, center with the rear license plate, and capture from bumper to roof line.';
      case 'leftview':
        return 'Stand on the driver\'s side, about 6-8 feet away, and capture the full profile from front wheel to rear wheel.';
      case 'rightview':
        return 'Stand on the passenger side, about 6-8 feet away, and capture the complete side profile of the vehicle.';
      case 'rc':
        return 'Physical document - usually kept in the vehicle\'s document holder or with the owner. Check the front and back pages.';
      case 'regno':
        return 'Front and rear number plates of the vehicle. Also printed on the RC document and insurance papers.';
      case 'odoreading':
        return 'Digital display on the instrument cluster behind the steering wheel. Turn on ignition to see the reading.';
      case 'hood/bonnet':
        return 'The front panel that opens upward to access the engine. Check from outside and also open to inspect hinges.';
      case 'roof':
        return 'Top panel of the vehicle. Best viewed from slightly elevated position or by walking around the vehicle.';
      case 'rhsfender':
        return 'Body panel between the front wheel and door on the right side (passenger side) of the vehicle.';
      case 'lhsfender':
        return 'Body panel between the front wheel and door on the left side (driver\'s side) of the vehicle.';
      case 'rhsfrontdoor':
        return 'Right side (passenger) front door. Check both exterior panel and interior door frame.';
      case 'lhsfrontdoor':
        return 'Left side (driver) front door. Inspect exterior panel, edges, and door frame alignment.';
      case 'rhsreardoor':
        return 'Right side (passenger) rear door. Available only on 4-door vehicles and SUVs.';
      case 'lhsreardoor':
        return 'Left side (driver) rear door. Check for dents, scratches, and proper closing alignment.';
      case 'tailgate/dicky':
        return 'Rear opening panel - trunk lid on sedans, tailgate on hatchbacks/SUVs. Check opening mechanism and seals.';
      case 'batteryslnumber':
        return 'Open the hood/bonnet. Battery is usually a rectangular black box with terminals on top, typically on one side of engine bay.';
      case 'batterycondition':
        return 'Same location as battery - check the plastic casing, terminals (metal connectors), and mounting bracket.';
      case 'alternator':
        return 'Engine bay - circular component with pulley, usually on the right side of engine, connected to drive belt.';
      case 'starter':
        return 'Engine bay - cylindrical component mounted on the engine block, typically near the transmission bellhousing.';
      case 'airfilter':
        return 'Engine bay - inside a rectangular or round plastic housing, usually on top or side of engine.';
      case 'fuseboxes':
        return 'Engine bay - rectangular black boxes with removable covers, usually near the battery or on firewall.';
      case 'chassisno':
        return 'Vehicle identification number stamped on chassis - typically on firewall in engine bay or under driver seat area.';
      case 'engine number':
        return 'Stamped on engine block - usually on the side or front of engine, may require torch light to see clearly.';
      case 'frontrhbrake':
        return 'Right front wheel - visible through wheel spokes. Look at brake disc (shiny metal disc) and brake pads.';
      case 'frontlhbrake':
        return 'Left front wheel - brake components visible through wheel openings when wheel is turned or removed.';
      case 'rearrhbrake':
        return 'Right rear wheel - brake disc or drum visible through wheel spokes. May be disc or drum type.';
      case 'rearlhbrake':
        return 'Left rear wheel - inspect brake components through wheel openings or when wheel is removed.';
      case 'frontrh':
        return 'Right front wheel tire - check tread depth on inner, center, and outer edges of tire surface.';
      case 'frontlh':
        return 'Left front wheel tire - inspect all areas of tire tread and sidewall for wear and damage.';
      case 'rearrh':
        return 'Right rear wheel tire - examine tread pattern and depth across entire tire width.';
      case 'rearlh':
        return 'Left rear wheel tire - check for even wear and adequate tread depth across tire surface.';
      case 'stepny':
        return 'Spare tire - usually located in boot/trunk area, under cargo floor, or mounted under vehicle rear.';
      case 'headlamps':
        return 'Front of vehicle - main lighting units on either side of grille. Test both high and low beam functions.';
      case 'brakelamps':
        return 'Rear of vehicle - red lights that illuminate when brake pedal is pressed. Usually 2-3 on each side.';
      case 'directionindicators':
        return 'Orange/amber lights on all four corners of vehicle - front, rear, and sometimes on side mirrors.';
      case 'foglamps':
        return 'Lower front bumper area - additional lights below headlamps, and sometimes rear fog lamps.';
      case 'dashboard':
        return 'Inside cabin - the panel in front of driver containing gauges, controls, and instrument cluster.';
      case 'seats':
        return 'Inside cabin - all passenger seating including front seats, rear bench/individual seats.';
      case 'doorpads':
        return 'Interior door panels - fabric/plastic panels on inside of all doors with window controls and handles.';
      case 'roofliner':
        return 'Interior ceiling - fabric covering on inside roof, check for sagging or water stains.';
      case 'frontglassno':
        return 'Front windshield - large glass panel in front of driver, check both inside and outside surfaces.';
      case 'rhsfrontdoorglassno':
        return 'Right front door window - roll window up and down to check entire glass surface.';
      case 'lhsfrontglassno':
        return 'Left front door window - driver side window, check for chips, cracks, or damage.';
      case ' tailgateglassno':
        return 'Rear windshield - back glass of vehicle, may have defogger lines and wiper.';
      case 'coolant':
        return 'Engine bay - coolant reservoir (translucent plastic tank) or radiator cap when engine is cold.';
      case 'brakefluidcondition':
        return 'Engine bay - brake fluid reservoir near firewall, usually has a transparent or semi-transparent container.';
      case 'engineoil':
        return 'Engine bay - check oil dipstick (yellow/orange handle) or oil filler cap on top of engine.';
      case 'horn':
        return 'Test by pressing horn button on steering wheel. Horn units located behind front grille or bumper.';
      case 'powerwindow':
        return 'Test all window switches inside cabin - each door should have up/down controls.';
      case 'infotainmentsystem':
        return 'Center dashboard - touchscreen or display unit between driver and passenger seats.';
      default:
        return 'Refer to the vehicle manual or ask the inspection supervisor for the exact location of this component.';
    }
  }
}

/// Reusable widget to display reference media (images, video, audio, links).
/// Used inline on inspection item cards and in the field info bottom sheet.
class ReferenceMediaSection extends StatelessWidget {
  final List<Map<String, dynamic>> mediaList;

  const ReferenceMediaSection({super.key, required this.mediaList});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Row(
            children: [
              Icon(
                Icons.perm_media_outlined,
                color: Color(0xFFFF6B6B),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Reference Media',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF6B6B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...mediaList.map((media) {
            final mediaType =
                (media['mediaType'] as String? ?? '').toLowerCase();
            final url = media['url'] as String? ?? '';
            final description = media['description'] as String?;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                    Image.network(
                      url,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return SizedBox(
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(
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
                          height: 100,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.broken_image,
                                size: 40, color: Colors.grey),
                          ),
                        );
                      },
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
                  if (description != null && description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      12,
                      description != null && description.isNotEmpty ? 0 : 8,
                      12,
                      8,
                    ),
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
}

// ---------------------------------------------------------------------------
// Inline Video Player — routes YouTube URLs to a WebView player,
// all other video URLs to the native Chewie player.
// ---------------------------------------------------------------------------
class _InlineVideoPlayer extends StatelessWidget {
  final String url;
  const _InlineVideoPlayer({required this.url});

  static final _ytRegex = RegExp(
    r'^(?:https?://)?(?:www\.|m\.)?(?:youtube\.com/(?:watch\?.*v=|embed/|shorts/)|youtu\.be/)([\w-]{11})',
  );

  @override
  Widget build(BuildContext context) {
    final match = _ytRegex.firstMatch(url);
    if (match != null) {
      return _YouTubeWebViewPlayer(videoId: match.group(1)!, originalUrl: url);
    }
    return _NativeVideoPlayer(url: url);
  }
}

// ---------------------------------------------------------------------------
// YouTube player — loads the actual YouTube mobile watch page in a WebView
// to avoid embed error 150/153.
// ---------------------------------------------------------------------------
class _YouTubeWebViewPlayer extends StatefulWidget {
  final String videoId;
  final String originalUrl;
  const _YouTubeWebViewPlayer({required this.videoId, required this.originalUrl});

  @override
  State<_YouTubeWebViewPlayer> createState() => _YouTubeWebViewPlayerState();
}

class _YouTubeWebViewPlayerState extends State<_YouTubeWebViewPlayer> {
  late final WebViewController _controller;
  bool _isLoading = true;

  String get _watchUrl =>
      'https://m.youtube.com/watch?v=${widget.videoId}';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            final uri = Uri.parse(request.url);
            final host = uri.host;
            if (host.contains('youtube.com') ||
                host.contains('youtu.be') ||
                host.contains('googlevideo.com') ||
                host.contains('google.com') ||
                host.contains('gstatic.com') ||
                host.contains('ytimg.com') ||
                host.contains('ggpht.com')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(_watchUrl));
  }

  void _openFullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullscreenYouTubePlayer(videoId: widget.videoId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: _openFullscreen,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.fullscreen, color: Colors.white, size: 20),
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

// ---------------------------------------------------------------------------
// Fullscreen YouTube page — loads mobile YouTube watch page in landscape
// ---------------------------------------------------------------------------
class _FullscreenYouTubePlayer extends StatefulWidget {
  final String videoId;
  const _FullscreenYouTubePlayer({required this.videoId});

  @override
  State<_FullscreenYouTubePlayer> createState() =>
      _FullscreenYouTubePlayerState();
}

class _FullscreenYouTubePlayerState extends State<_FullscreenYouTubePlayer> {
  late final WebViewController _controller;

  String get _watchUrl =>
      'https://m.youtube.com/watch?v=${widget.videoId}';

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final host = Uri.parse(request.url).host;
            if (host.contains('youtube.com') ||
                host.contains('youtu.be') ||
                host.contains('googlevideo.com') ||
                host.contains('google.com') ||
                host.contains('gstatic.com') ||
                host.contains('ytimg.com') ||
                host.contains('ggpht.com')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(_watchUrl));
  }

  void _exit() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: Material(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _exit,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.fullscreen_exit, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Native video player (non-YouTube) with fullscreen via Chewie
// ---------------------------------------------------------------------------
class _NativeVideoPlayer extends StatefulWidget {
  final String url;
  const _NativeVideoPlayer({required this.url});

  @override
  State<_NativeVideoPlayer> createState() => _NativeVideoPlayerState();
}

class _NativeVideoPlayerState extends State<_NativeVideoPlayer> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _hasError = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoController =
        VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await _videoController.initialize();
      if (!mounted) return;
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: false,
        looping: false,
        showControls: true,
        allowFullScreen: true,
        allowMuting: true,
        aspectRatio: _videoController.value.aspectRatio,
        placeholder: Container(color: Colors.black),
        errorBuilder: (context, errorMessage) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Could not load video',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          );
        },
      );
      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitializing = false;
        });
      }
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
    if (_isInitializing) {
      return Container(
        height: 200,
        color: Colors.black87,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 12),
              Text(
                'Loading video...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return InkWell(
        onTap: () async {
          final uri = Uri.parse(widget.url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Container(
          height: 160,
          color: Colors.black87,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 40, color: Colors.white54),
                SizedBox(height: 8),
                Text(
                  'Could not load video. Tap to open externally.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: _videoController.value.aspectRatio.clamp(0.5, 3.0),
        child: Chewie(controller: _chewieController!),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Inline Audio Player with play/pause, seek bar, and duration display
// ---------------------------------------------------------------------------
class _InlineAudioPlayer extends StatefulWidget {
  final String url;
  const _InlineAudioPlayer({required this.url});

  @override
  State<_InlineAudioPlayer> createState() => _InlineAudioPlayerState();
}

class _InlineAudioPlayerState extends State<_InlineAudioPlayer> {
  late ja.AudioPlayer _audioPlayer;
  bool _hasError = false;
  bool _isLoading = true;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = ja.AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      final duration = await _audioPlayer.setUrl(widget.url);
      if (mounted) {
        setState(() {
          _totalDuration = duration ?? Duration.zero;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 80,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Loading audio...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return InkWell(
        onTap: () async {
          final uri = Uri.parse(widget.url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Container(
          height: 80,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 24, color: Colors.white54),
                SizedBox(width: 12),
                Text(
                  'Could not load audio. Tap to open externally.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              StreamBuilder<ja.PlayerState>(
                stream: _audioPlayer.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final playing = playerState?.playing ?? false;
                  final processingState = playerState?.processingState;

                  if (processingState == ja.ProcessingState.loading ||
                      processingState == ja.ProcessingState.buffering) {
                    return Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),
                    );
                  }

                  return GestureDetector(
                    onTap: () {
                      if (processingState == ja.ProcessingState.completed) {
                        _audioPlayer.seek(Duration.zero);
                        _audioPlayer.play();
                      } else if (playing) {
                        _audioPlayer.pause();
                      } else {
                        _audioPlayer.play();
                      }
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        processingState == ja.ProcessingState.completed
                            ? Icons.replay
                            : playing
                                ? Icons.pause
                                : Icons.play_arrow,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StreamBuilder<Duration>(
                      stream: _audioPlayer.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        return SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14),
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white.withAlpha(76),
                            thumbColor: Colors.white,
                            overlayColor: Colors.white.withAlpha(51),
                          ),
                          child: Slider(
                            min: 0,
                            max: _totalDuration.inMilliseconds.toDouble().clamp(1, double.infinity),
                            value: position.inMilliseconds
                                .toDouble()
                                .clamp(0, _totalDuration.inMilliseconds.toDouble().clamp(1, double.infinity)),
                            onChanged: (value) {
                              _audioPlayer.seek(
                                  Duration(milliseconds: value.round()));
                            },
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: StreamBuilder<Duration>(
                        stream: _audioPlayer.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          return Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatDuration(_totalDuration),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InspectionInfoButton extends StatelessWidget {
  final String fieldId;
  final String? customTitle;
  final String? customExplanation;
  final List<Map<String, dynamic>> referenceMedia;
  final double size;
  final Color? color;

  const InspectionInfoButton({
    super.key,
    required this.fieldId,
    this.customTitle,
    this.customExplanation,
    this.referenceMedia = const [],
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4FC3F7),
            Color(0xFF29B6F6),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF29B6F6).withAlpha(76),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            InspectionFieldInfoSheet.show(
              context: context,
              fieldId: fieldId,
              customTitle: customTitle,
              customExplanation: customExplanation,
              referenceMedia: referenceMedia,
            );
          },
          child: const Center(
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
