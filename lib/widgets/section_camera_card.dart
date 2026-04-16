import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class SectionCameraCard extends StatefulWidget {
  final double height;
  final BorderRadius borderRadius;
  final void Function(XFile file)? onCapture;
  final VoidCallback? onPickFromGallery;

  /// Shown above the preview so users know what this photo is for (e.g. field title).
  final String? instructionText;

  const SectionCameraCard({
    super.key,
    this.height = 220,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.onCapture,
    this.onPickFromGallery,
    this.instructionText,
  });

  @override
  State<SectionCameraCard> createState() => _SectionCameraCardState();
}

class _SectionCameraCardState extends State<SectionCameraCard>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isCapturing = false;
  int _currentCameraIndex = 0;

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
      _controller?.dispose();
      _controller = null;
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    } else if (state == AppLifecycleState.resumed && mounted) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (_isInitializing) return;
    _isInitializing = true;

    if (mounted) {
      setState(() {
        _hasError = false;
        _errorMessage = '';
        _isInitialized = false;
      });
    }

    try {
      final hasPermission = await _ensureCameraPermission();
      if (!hasPermission) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _isInitialized = false;
            _errorMessage =
                'Camera permission is required to capture inspection photos';
          });
        }
        return;
      }

      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'No cameras available';
        });
        return;
      }

      final backCameraIndex = _cameras!.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      _currentCameraIndex = backCameraIndex >= 0 ? backCameraIndex : 0;
      await _startCamera(_cameras![_currentCameraIndex]);
    } on CameraException catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.description ?? 'Camera error';
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

  Future<bool> _ensureCameraPermission() async {
    if (!(Platform.isIOS || Platform.isAndroid)) return true;

    var status = await Permission.camera.status;
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied || status.isRestricted) {
      return false;
    }

    status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<void> _startCamera(CameraDescription camera) async {
    _controller?.dispose();
    _controller = null;

    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
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
    } on CameraException catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _hasError = true;
          _errorMessage = e.description ?? 'Camera initialization failed';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _hasError = true;
          _errorMessage = 'Unable to start live camera preview';
        });
      }
    }
  }

  Future<void> _captureImage() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final XFile file = await _controller!.takePicture();
      widget.onCapture?.call(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _openFullscreenPreview() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullscreenCameraView(
          controller: _controller!,
          onCapture: (file) {
            widget.onCapture?.call(file);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
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
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () async {
                  final status = await Permission.camera.status;
                  if (status.isPermanentlyDenied || status.isRestricted) {
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
        border: Border.all(color: Colors.blue.withAlpha(100), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: CameraPreview(_controller!),
            ),
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
                    Icon(
                      Icons.photo_camera_outlined,
                      color: Colors.white.withAlpha(230),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.instructionText ??
                            'Center the subject in the frame, then tap Take photo',
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
                ),
              ),
            ),
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
                                  message: 'Pick photo from gallery',
                                  child: Semantics(
                                    button: true,
                                    label: 'Pick from gallery',
                                    child: _CameraActionButton(
                                      icon: Icons.photo_library_outlined,
                                      onTap: widget.onPickFromGallery,
                                      size: 44,
                                    ),
                                  ),
                                )
                              : const SizedBox(width: 44, height: 44),
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'Save this photo for the inspection',
                      child: Semantics(
                        button: true,
                        label: 'Take photo',
                        child: _CameraActionButton(
                          icon: Icons.camera_alt,
                          onTap: _isCapturing ? null : _captureImage,
                          size: 56,
                          isPrimary: true,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6, left: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Tooltip(
                                message: 'Open a larger view (same camera)',
                                child: Semantics(
                                  button: true,
                                  label: 'Larger preview',
                                  child: _CameraActionButton(
                                    icon: Icons.open_in_full,
                                    onTap: _openFullscreenPreview,
                                    size: 44,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isCapturing)
              Container(
                color: Colors.white.withAlpha(100),
                child: const Center(
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CameraActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final bool isPrimary;

  const _CameraActionButton({
    required this.icon,
    this.onTap,
    this.size = 32,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isPrimary
              ? Colors.white.withAlpha(230)
              : Colors.black.withAlpha(120),
          shape: BoxShape.circle,
          border: isPrimary ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Icon(
          icon,
          color: isPrimary ? Colors.black87 : Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}

class _FullscreenCameraView extends StatefulWidget {
  final CameraController controller;
  final void Function(XFile file) onCapture;

  const _FullscreenCameraView({
    required this.controller,
    required this.onCapture,
  });

  @override
  State<_FullscreenCameraView> createState() => _FullscreenCameraViewState();
}

class _FullscreenCameraViewState extends State<_FullscreenCameraView> {
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _capture() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      final file = await widget.controller.takePicture();
      widget.onCapture(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: CameraPreview(widget.controller),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Material(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.of(context).pop(),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Tap the white button below to take the photo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 8),
                      child: const SizedBox(width: 56, height: 56),
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Take photo',
                  child: Semantics(
                    button: true,
                    label: 'Take photo',
                    child: GestureDetector(
                      onTap: _isCapturing ? null : _capture,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _isCapturing ? Colors.grey : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: _isCapturing
                              ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black54,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
