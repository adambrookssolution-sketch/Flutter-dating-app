import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

import 'package:app/data/datasource/verification_datasource.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/presentation/pages/verification/verification_pending_screen.dart';

/// Video recorder for couple identity verification.
///
/// Lifecycle:
///   1. Request camera + mic permissions (returns to intro on denial).
///   2. Initialise the front camera + audio.
///   3. User taps record → max 30s timer → tap again to stop (min 10s).
///   4. Preview the captured video (looped) → user retakes or submits.
///   5. On submit: upload to Storage and update Firestore via
///      [VerificationDatasource.submitVerificationVideo], then navigate to
///      [VerificationPendingScreen].
///
/// Resource handling: the camera + video controllers are explicitly disposed
/// in `dispose()` AND in every navigation transition so the camera light
/// doesn't stay on if the user backgrounds the app mid-flow.
class VideoRecordScreen extends StatefulWidget {
  final int attemptNumber;

  const VideoRecordScreen({super.key, this.attemptNumber = 1});

  @override
  State<VideoRecordScreen> createState() => _VideoRecordScreenState();
}

class _VideoRecordScreenState extends State<VideoRecordScreen> {
  // Client spec (2026-04-21): short 3–5 second verification clip. Users
  // look forward, then turn head to the right, then to the left — enough
  // to prove they're a real person, short enough that uploads stay tiny
  // and the flow stays friction-free.
  // Client feedback 2026-05-15 #8: raise the recording window from 5s
  // to 8s so users have enough time to actually rotate their head
  // through the three beats. Minimum bumped to 5s so half-recorded
  // clips still cover at least the "look at the camera" + first turn.
  static const int _minSeconds = 5;
  static const int _maxSeconds = 8;

  /// Cue text shown over the live camera view based on how far into the
  /// 8-second recording the user is. Split into three beats so the
  /// head-turn gesture stays in sync with the prompt.
  String _headTurnPrompt(int elapsed) {
    if (elapsed < 3) return 'Look at the camera';
    if (elapsed < 5) return 'Turn your head to the right';
    return 'Turn your head to the left';
  }

  CameraController? _camera;
  VideoPlayerController? _player;
  XFile? _captured;
  bool _isInitialising = true;
  bool _permissionDenied = false;
  bool _isRecording = false;
  bool _isUploading = false;
  int _elapsed = 0;
  Timer? _timer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _camera?.dispose();
    _player?.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final cam = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    if (!cam.isGranted || !mic.isGranted) {
      if (!mounted) return;
      setState(() {
        _isInitialising = false;
        _permissionDenied = true;
      });
      return;
    }

    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: true,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _isInitialising = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitialising = false;
        _errorMessage = 'Could not start camera: $e';
      });
    }
  }

  Future<void> _toggleRecording() async {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) return;
    if (_isRecording) {
      await _stop();
    } else {
      await _start();
    }
  }

  Future<void> _start() async {
    final cam = _camera!;
    try {
      await cam.startVideoRecording();
      setState(() {
        _isRecording = true;
        _elapsed = 0;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
        if (!mounted) return;
        setState(() => _elapsed++);
        if (_elapsed >= _maxSeconds) {
          await _stop();
        }
      });
    } catch (e) {
      setState(() => _errorMessage = 'Could not start recording: $e');
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    final cam = _camera!;
    try {
      final file = await cam.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _captured = file;
      });
      // Free the camera before showing the preview so the indicator light
      // turns off while the user reviews.
      await cam.dispose();
      _camera = null;

      final player = VideoPlayerController.file(File(file.path));
      await player.initialize();
      await player.setLooping(true);
      await player.play();
      if (!mounted) return;
      setState(() => _player = player);
    } catch (e) {
      setState(() {
        _isRecording = false;
        _errorMessage = 'Could not save recording: $e';
      });
    }
  }

  Future<void> _retake() async {
    setState(() {
      _captured = null;
      _player?.dispose();
      _player = null;
      _isInitialising = true;
      _errorMessage = null;
    });
    await _bootstrap();
  }

  Future<void> _submit() async {
    if (_captured == null) return;
    if (_elapsed < _minSeconds) {
      setState(() => _errorMessage =
          'Recording too short — needs at least $_minSeconds seconds.');
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _errorMessage = 'You are signed out. Please sign in again.');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      await VerificationDatasource.submitVerificationVideo(
        coupleId: uid,
        videoFile: File(_captured!.path),
        attemptNumber: widget.attemptNumber,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const VerificationPendingScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _errorMessage = 'Upload failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialising) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (_permissionDenied) {
      return _PermissionDeniedView(onRetry: () async {
        await openAppSettings();
      });
    }
    if (_player != null && _captured != null) {
      return _buildPreview();
    }
    return _buildRecorder();
  }

  Widget _buildRecorder() {
    final cam = _camera;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (cam != null && cam.value.isInitialized)
              Center(child: CameraPreview(cam))
            else
              const Center(
                child:
                    CircularProgressIndicator(color: Colors.white),
              ),
            Positioned(
              top: 12,
              left: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: _isRecording ? null : () => Navigator.pop(context),
              ),
            ),
            if (_isRecording)
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fiber_manual_record,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          '${_elapsed.toString().padLeft(2, '0')} / ${_maxSeconds}s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Head-turn prompt overlay, timed against _elapsed while
            // recording. Drives the "front → right → left" proof-of-life
            // gesture required by the moderation flow.
            if (_isRecording)
              Positioned(
                top: 72,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      _headTurnPrompt(_elapsed),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            if (_errorMessage != null)
              Positioned(
                bottom: 130,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _toggleRecording,
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: Container(
                        width: _isRecording ? 28 : 60,
                        height: _isRecording ? 28 : 60,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(
                              _isRecording ? 6 : 30),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Center(
                    child: Text(
                      _isRecording
                          ? 'Tap stop when finished (min ${_minSeconds}s)'
                          : 'Tap to record',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final player = _player!;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: player.value.aspectRatio,
                child: VideoPlayer(player),
              ),
            ),
            if (_errorMessage != null)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(250),
                        ),
                      ),
                      onPressed: _isUploading ? null : _retake,
                      child: Text(AppLocalizations.of(context)!.retake,
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB01030),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(250),
                        ),
                      ),
                      onPressed: _isUploading ? null : _submit,
                      child: Text(_isUploading ? 'Uploading…' : 'Submit'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  final VoidCallback onRetry;

  const _PermissionDeniedView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off,
                  size: 64, color: Color(0xFFB01030)),
              const SizedBox(height: 24),
              const Text(
                'Camera and microphone access required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Verification needs to record a short video of both partners. '
                'Open Settings to grant camera and microphone permissions, '
                'then come back.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF555555)),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB01030),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(250),
                    ),
                  ),
                  onPressed: onRetry,
                  child: Text(AppLocalizations.of(context)!.openSettings),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(250),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)!.goBack),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
