import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class SectionVideoCameraCard extends StatefulWidget {
  final double height;
  final BorderRadius borderRadius;
  final void Function(XFile file)? onCapture;
  final VoidCallback? onPickFromGallery;
  final String? instructionText;

  const SectionVideoCameraCard({
    super.key,
    this.height = 220,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.onCapture,
    this.onPickFromGallery,
    this.instructionText,
  });

  @override
  State<SectionVideoCameraCard> createState() => _SectionVideoCameraCardState();
}

class _SectionVideoCameraCardState extends State<SectionVideoCameraCard>
    with WidgetsBindingObserver {
  // Shared across all instances so the next card always waits for the
  // previous controller's async disposal to complete before initialising.
  static Future<void>? _pendingDisposal;

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentCameraIndex = 0;

  bool _isRecording = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

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

    try {
      // Flutter calls initState() on the NEW widget BEFORE dispose() on the
      // widget it replaced.  Yielding one event-loop tick lets Flutter finish
      // reconciliation – including the old card's dispose() that sets
      // _pendingDisposal – before we touch the camera hardware.
      await Future.delayed(Duration.zero);
      if (!mounted) return;

      // Wait for the previous card's camera controller to fully release.
      final disposal = _pendingDisposal;
      if (disposal != null) {
        _pendingDisposal = null;
        await disposal.timeout(
          const Duration(seconds: 2),
          onTimeout: () {},
        );
      }
      if (!mounted) return;

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
      if (!hasCamPerm) return;

      final hasMicPerm = await _ensurePermission(
        Permission.microphone,
        'Microphone permission is required to record inspection videos',
      );
      if (!hasMicPerm) return;

      _cameras = await availableCameras();
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

      // Try up to 3 times.  Hardware may need extra time to release even after
      // the disposal future completes, especially on Android.
      for (int attempt = 0; attempt < 3; attempt++) {
        if (!mounted) return;

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
          if (!mounted) return;
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
      _isInitializing = false;
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
      ResolutionPreset.medium,
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
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      await _controller!.startVideoRecording();
      _elapsed = Duration.zero;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
      });
      if (mounted) setState(() => _isRecording = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      _timer?.cancel();
      _timer = null;
      final file = await _controller!.stopVideoRecording();
      if (mounted) setState(() => _isRecording = false);
      widget.onCapture?.call(file);
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
    if (_isRecording) {
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
          color: Colors.grey[900],
          borderRadius: widget.borderRadius,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off, color: Colors.white54, size: 36),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () async {
                  final camStatus = await Permission.camera.status;
                  final micStatus = await Permission.microphone.status;
                  if (camStatus.isPermanentlyDenied ||
                      micStatus.isPermanentlyDenied) {
                    await openAppSettings();
                    return;
                  }
                  _initCamera();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Grant permission'),
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
              ),
            ],
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
        border: Border.all(
          color: _isRecording
              ? Colors.red.withAlpha(200)
              : Colors.deepPurple.withAlpha(100),
          width: _isRecording ? 2 : 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(child: CameraPreview(_controller!)),
            // Top bar
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
            // Bottom bar
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
                    // Gallery picker (left)
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
                    // Record / Stop button (center)
                    Tooltip(
                      message: _isRecording ? 'Stop recording' : 'Start recording',
                      child: _VideoActionButton(
                        icon: _isRecording ? Icons.stop : Icons.fiber_manual_record,
                        onTap: _toggleRecording,
                        size: 56,
                        isPrimary: true,
                        isRecording: _isRecording,
                      ),
                    ),
                    // Spacer (right — symmetry)
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),
            ),
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
