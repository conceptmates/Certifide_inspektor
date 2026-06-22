import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'section_video_camera_card_controller.dart';

class SectionVideoCameraCard extends ConsumerStatefulWidget {
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

  /// Called once the camera is ready, passing a function that pauses/resumes
  /// the active recording. Only useful when [showControls] is false.
  final void Function(VoidCallback togglePause)? onPauseResumeReady;

  /// Fired whenever the paused state of an active recording changes
  /// (true = paused).
  final void Function(bool isPaused)? onRecordingPausedChanged;

  /// Called once the camera is ready, passing a function that toggles the
  /// torch flash. Only useful when [showControls] is false.
  final void Function(VoidCallback toggleFlash)? onFlashToggleReady;

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
    this.onPauseResumeReady,
    this.onRecordingPausedChanged,
    this.onFlashToggleReady,
  });

  @override
  ConsumerState<SectionVideoCameraCard> createState() =>
      _SectionVideoCameraCardState();
}

class _SectionVideoCameraCardState
    extends ConsumerState<SectionVideoCameraCard> {
  // Stable per-card id so each on-screen card gets its own autoDisposed
  // controller instance. The camera lifecycle + recording state now live in
  // [VideoCardController]; this widget only renders and forwards callbacks.
  late final String _cardId;

  @override
  void initState() {
    super.initState();
    _cardId = UniqueKey().toString();
  }

  VideoCardControllerProvider get _provider =>
      videoCardControllerProvider(_cardId);

  void _showNotice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(_provider.notifier);
    // Refresh the sinks the controller forwards through (captures, notices,
    // and the trigger functions handed back to the parent UI).
    notifier.attach(
      onCapture: widget.onCapture,
      onRecordingChanged: widget.onRecordingChanged,
      onRecordingPausedChanged: widget.onRecordingPausedChanged,
      onRecordingToggleReady: widget.onRecordingToggleReady,
      onPauseResumeReady: widget.onPauseResumeReady,
      onFlashToggleReady: widget.onFlashToggleReady,
      onNotice: _showNotice,
    );
    final state = ref.watch(_provider);
    final controller = notifier.controller;

    if (state.hasError) {
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
                  state.errorMessage,
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
                      notifier.initCamera();
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

    if (!state.isInitialized || controller == null) {
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
                color: state.isRecording
                    ? Colors.red.withAlpha(200)
                    : Colors.deepPurple.withAlpha(100),
                width: state.isRecording ? 2 : 1.5,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(child: CameraPreview(controller)),
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
                      if (state.isRecording) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: state.isPaused ? Colors.amber : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${state.isPaused ? 'PAUSED ' : ''}'
                          '${_formatDuration(state.elapsed)}',
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: widget.onPickFromGallery != null
                                ? Tooltip(
                                    message: 'Pick video from gallery',
                                    child: _VideoActionButton(
                                      icon: Icons.video_library_outlined,
                                      onTap: widget.onPickFromGallery,
                                      size: 40,
                                    ),
                                  )
                                : const SizedBox(width: 40, height: 40),
                          ),
                        ),
                      ),
                      // Pause / resume (only while recording)
                      if (state.isRecording) ...[
                        Tooltip(
                          message: state.isPaused
                              ? 'Resume recording'
                              : 'Pause recording',
                          child: _VideoActionButton(
                            icon: state.isPaused
                                ? Icons.play_arrow
                                : Icons.pause,
                            onTap: notifier.togglePauseRecording,
                            size: 40,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ] else ...[
                        Tooltip(
                          message:
                              state.flashOn ? 'Turn flash off' : 'Turn flash on',
                          child: _VideoActionButton(
                            icon: state.flashOn
                                ? Icons.flash_on
                                : Icons.flash_off,
                            onTap: notifier.toggleFlash,
                            size: 40,
                            isActive: state.flashOn,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Tooltip(
                        message: state.isRecording
                            ? 'Stop recording'
                            : 'Start recording',
                        child: _VideoActionButton(
                          icon: state.isRecording
                              ? Icons.stop
                              : Icons.fiber_manual_record,
                          onTap: notifier.toggleRecording,
                          size: 56,
                          isPrimary: true,
                          isRecording: state.isRecording,
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
  final bool isActive;

  const _VideoActionButton({
    required this.icon,
    this.onTap,
    this.size = 32,
    this.isPrimary = false,
    this.isRecording = false,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color iconColor;
    if (isPrimary) {
      bgColor = isRecording ? Colors.red : Colors.white.withAlpha(230);
      iconColor = isRecording ? Colors.white : Colors.black87;
    } else if (isActive) {
      bgColor = const Color(0xFFFFC107);
      iconColor = Colors.black87;
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
