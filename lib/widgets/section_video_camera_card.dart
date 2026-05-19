import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'section_camera_card.dart' show cameraCardPendingDisposal;

class SectionVideoCameraCard extends StatefulWidget {
  final double height;
  final BorderRadius borderRadius;
  final void Function(XFile file)? onCapture;
  final VoidCallback? onPickFromGallery;
  final String? instructionText;

  /// When false the card is a pure viewfinder with only a minimal recording
  /// indicator. All controls live in the parent UI.
  final bool showControls;

  /// Called once the camera is ready, passing a toggle function.
  final void Function(VoidCallback toggleRecording)? onRecordingToggleReady;

  /// Fired whenever the recording state changes (true = recording started).
  final void Function(bool isRecording)? onRecordingChanged;

  const SectionVideoCameraCard({
    super.key,
    this.height = 220,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.onCapture,
    this.onPickFromGallery,
    this.instructionText,
    this.showControls = true,
    this.onRecordingToggleReady,
    this.onRecordingChanged,
  });

  @override
  State<SectionVideoCameraCard> createState() => _SectionVideoCameraCardState();
}

class _SectionVideoCameraCardState extends State<SectionVideoCameraCard>
    with WidgetsBindingObserver {
  // Uses the library-level [cameraCardPendingDisposal] shared with
  // SectionCameraCard so mode switches don't conflict on hardware.
  static Future<void>? get _pendingDisposal => cameraCardPendingDisposal;
  static set _pendingDisposal(Future<void>? v) => cameraCardPendingDisposal = v;

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentCameraIndex = 0;

  bool _isRecording = false;
  bool _isToggling = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  // Incremented on every inactive/paused transition to cancel in-flight inits.
  int _initGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // Cancel any in-flight init (e.g. waiting for iOS permission dialog).
      _initGeneration++;
      _isInitializing = false;
      _stopRecordingIfActive();
      _disposeController();
      if (mounted) setState(() => _isInitialized = false);
    } else if (state == AppLifecycleState.resumed && mounted) {
      _initCamera();
    }
  }

  void _disposeController() {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      _pendingDisposal = controller.dispose();
    }
  }

  Future<void> _initCamera() async {
    if (_isInitializing) return;
    _isInitializing = true;
    final myGen = ++_initGeneration;

    try {
      // Yield one tick so Flutter finishes reconciliation before touching hardware.
      await Future.delayed(Duration.zero);
      if (!mounted || _initGeneration != myGen) return;

      // Wait for the previous card's camera controller to fully release.
      final disposal = _pendingDisposal;
      if (disposal != null) {
        _pendingDisposal = null;
        await disposal.timeout(
          const Duration(seconds: 2),
          onTimeout: () {},
        );
      }
      if (!mounted || _initGeneration != myGen) return;

      if (mounted) {
        setState(() {
          _hasError = false;
          _errorMessage = '';
          _isInitialized = false;
        });
      }

      final hasCamPerm = await _ensurePermission(
        Permission.camera,
        'Camera permission is required to record inspection videos',
      );
      // On iOS the permission dialog causes a brief inactive→resumed cycle.
      // Re-wait for any disposal that occurred during the dialog.
      if (!mounted || _initGeneration != myGen) return;
      final postCamDisposal = _pendingDisposal;
      if (postCamDisposal != null) {
        _pendingDisposal = null;
        await postCamDisposal.timeout(
          const Duration(seconds: 2),
          onTimeout: () {},
        );
      }
      if (!mounted || _initGeneration != myGen) return;
      if (!hasCamPerm) return;

      final hasMicPerm = await _ensurePermission(
        Permission.microphone,
        'Microphone permission is required to record inspection videos',
      );
      if (!mounted || _initGeneration != myGen) return;
      final postMicDisposal = _pendingDisposal;
      if (postMicDisposal != null) {
        _pendingDisposal = null;
        await postMicDisposal.timeout(
          const Duration(seconds: 2),
          onTimeout: () {},
        );
      }
      if (!mounted || _initGeneration != myGen) return;
      if (!hasMicPerm) return;

      _cameras = await availableCameras();
      if (!mounted || _initGeneration != myGen) return;
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'No cameras available';
          });
        }
        return;
      }

      final backIdx = _cameras!
          .indexWhere((c) => c.lensDirection == CameraLensDirection.back);
      _currentCameraIndex = backIdx >= 0 ? backIdx : 0;

      for (int attempt = 0; attempt < 3; attempt++) {
        if (!mounted || _initGeneration != myGen) return;

        if (attempt > 0) {
          final prev = _pendingDisposal;
          _pendingDisposal = null;
          if (prev != null) {
            await prev.timeout(
              const Duration(seconds: 1),
              onTimeout: () {},
            );
          } else {
            await Future.delayed(const Duration(milliseconds: 600));
          }
          if (!mounted || _initGeneration != myGen) return;
        }

        final ok = await _tryStartCamera(_cameras![_currentCameraIndex]);
        if (ok) return;
      }

      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Camera unavailable. Tap to retry.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to initialize camera';
        });
      }
    } finally {
      if (_initGeneration == myGen) _isInitializing = false;
    }
  }

  Future<bool> _tryStartCamera(CameraDescription camera) async {
    final old = _controller;
    _controller = null;
    if (old != null) {
      final f = old.dispose();
      _pendingDisposal = f;
      await f.timeout(const Duration(seconds: 1), onTimeout: () {});
      _pendingDisposal = null;
    }

    if (!mounted) return false;

    final controller = CameraController(
      camera,
      ResolutionPreset.max,
      enableAudio: true,
    );
    _controller = controller;

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
        widget.onRecordingToggleReady?.call(_toggleRecording);
      }
      return true;
    } on CameraException {
      _pendingDisposal = _controller?.dispose();
      _controller = null;
      return false;
    } catch (_) {
      _pendingDisposal = _controller?.dispose();
      _controller = null;
      return false;
    }
  }

  Future<bool> _ensurePermission(Permission perm, String errorMsg) async {
    if (!(Platform.isIOS || Platform.isAndroid)) return true;
    var status = await perm.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied || status.isRestricted) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = errorMsg;
        });
      }
      return false;
    }
    status = await perm.request();
    if (!status.isGranted && mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = errorMsg;
      });
    }
    return status.isGranted;
  }

  Future<void> _toggleRecording() async {
    if (_isToggling || _controller == null || !_controller!.value.isInitialized) return;
    _isToggling = true;
    try {
      if (_isRecording) {
        await _stopRecording();
      } else {
        await _startRecording();
      }
    } finally {
      _isToggling = false;
    }
  }

  Future<void> _startRecording() async {
    // Guard against the camera already recording at the native level.
    if (_controller!.value.isRecordingVideo) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording already started')),
        );
      }
      return;
    }
    try {
      await _controller!.startVideoRecording();
      _elapsed = Duration.zero;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
      });
      if (mounted) {
        setState(() => _isRecording = true);
        widget.onRecordingChanged?.call(true);
      }
    } on CameraException catch (e) {
      if (mounted) {
        final msg = e.description?.toLowerCase() ?? '';
        final friendly = msg.contains('already')
            ? 'Recording already started'
            : 'Failed to start recording';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendly)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _timer = null;

    // Guard against the native layer not actually recording.
    if (!(_controller?.value.isRecordingVideo ?? false)) {
      if (mounted) setState(() => _isRecording = false);
      return;
    }

    try {
      final file = await _controller!.stopVideoRecording();
      if (mounted) {
        setState(() => _isRecording = false);
        widget.onRecordingChanged?.call(false);
      }
      widget.onCapture?.call(file);
    } on CameraException catch (e) {
      if (mounted) {
        setState(() => _isRecording = false);
        widget.onRecordingChanged?.call(false);
        final msg = e.description?.toLowerCase() ?? '';
        final friendly = msg.contains('assertwriter') || msg.contains('assetwriter')
            ? 'Recording was too short. Please try again.'
            : 'Failed to save recording';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendly)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRecording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecordingIfActive() async {
    if (_isRecording || (_controller?.value.isRecordingVideo ?? false)) {
      _timer?.cancel();
      _timer = null;
      try {
        await _controller?.stopVideoRecording();
      } catch (_) {}
      if (mounted) setState(() => _isRecording = false);
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: widget.borderRadius,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.videocam_off_outlined,
                    color: Colors.redAccent,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (Platform.isIOS) {
                        await openAppSettings();
                        return;
                      }
                      final camStatus = await Permission.camera.status;
                      final micStatus = await Permission.microphone.status;
                      if (camStatus.isPermanentlyDenied ||
                          micStatus.isPermanentlyDenied) {
                        await openAppSettings();
                        return;
                      }
                      _initCamera();
                    },
                    icon: const Icon(Icons.videocam_outlined, size: 18),
                    label: const Text('Allow Camera & Microphone'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: widget.borderRadius,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white70, strokeWidth: 2),
              SizedBox(height: 12),
              Text(
                'Starting camera...',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: widget.borderRadius,
        border: widget.showControls
            ? Border.all(
                color: _isRecording
                    ? Colors.red.withAlpha(200)
                    : Colors.deepPurple.withAlpha(100),
                width: _isRecording ? 2 : 1.5,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(child: CameraPreview(_controller!)),
            if (widget.showControls) ...[
              // Top bar (full controls mode)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(200),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_isRecording) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDuration(_elapsed),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else ...[
                        Icon(
                          Icons.videocam_outlined,
                          color: Colors.white.withAlpha(230),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.instructionText ??
                                'Tap the button below to start recording',
                            style: TextStyle(
                              color: Colors.white.withAlpha(242),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Bottom bar (full controls mode)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withAlpha(200),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 6, right: 6),
                            child: widget.onPickFromGallery != null
                                ? Tooltip(
                                    message: 'Pick video from gallery',
                                    child: _VideoActionButton(
                                      icon: Icons.video_library_outlined,
                                      onTap: widget.onPickFromGallery,
                                      size: 44,
                                    ),
                                  )
                                : const SizedBox(width: 44, height: 44),
                          ),
                        ),
                      ),
                      Tooltip(
                        message:
                            _isRecording ? 'Stop recording' : 'Start recording',
                        child: _VideoActionButton(
                          icon: _isRecording
                              ? Icons.stop
                              : Icons.fiber_manual_record,
                          onTap: _toggleRecording,
                          size: 56,
                          isPrimary: true,
                          isRecording: _isRecording,
                        ),
                      ),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VideoActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final bool isPrimary;
  final bool isRecording;

  const _VideoActionButton({
    required this.icon,
    this.onTap,
    this.size = 32,
    this.isPrimary = false,
    this.isRecording = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color iconColor;
    if (isPrimary) {
      bgColor = isRecording ? Colors.red : Colors.white.withAlpha(230);
      iconColor = isRecording ? Colors.white : Colors.black87;
    } else {
      bgColor = Colors.black.withAlpha(120);
      iconColor = Colors.white;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: isPrimary ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Icon(icon, color: iconColor, size: size * 0.5),
      ),
    );
  }
}
