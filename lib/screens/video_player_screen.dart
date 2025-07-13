// lib/screens/video_player_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:sanad_player/models/media_file.dart';
import 'package:sanad_player/utils/theme.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:sanad_player/services/database_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final MediaFile videoFile;
  const VideoPlayerScreen({super.key, required this.videoFile});
  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;
  double _currentPlaybackSpeed = 1.0;

  bool _areControlsVisible = true;
  Timer? _hideControlsTimer;

  Offset _dragStart = Offset.zero;
  double _dragDx = 0.0;
  bool _isDragging = false;

  final DatabaseService _databaseService = DatabaseService.instance;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoController = VideoPlayerController.file(File(widget.videoFile.filePath));
      await _videoController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: false,
        showControlsOnInitialize: false,
        aspectRatio: _videoController.value.aspectRatio,
        placeholder: const Center(child: CircularProgressIndicator()),
        autoInitialize: true,
        playbackSpeeds: const [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0],
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text('خطأ: $errorMessage', style: TextStyle(color: Colors.white)),
          );
        },
      );

      _videoController.addListener(() {
        if (mounted) {
          setState(() {
            _currentPosition = _videoController.value.position;
            _totalDuration = _videoController.value.duration;
            _isPlaying = _videoController.value.isPlaying;
          });
          _resetHideControlsTimer();
        }
      });

      _videoController.play();
      if (mounted) {
        setState(() => _isPlaying = true);
        _databaseService.updateMediaLastPlayed(widget.videoFile.id, DateTime.now().millisecondsSinceEpoch);
      }

      _startHideControlsTimer();
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    _hideControlsTimer?.cancel();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _areControlsVisible = false);
    });
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _startHideControlsTimer();
    if (!_areControlsVisible) {
      setState(() => _areControlsVisible = true);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final h = twoDigits(duration.inHours);
    final m = twoDigits(duration.inMinutes.remainder(60));
    final s = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? "$h:$m:$s" : "$m:$s";
  }

  void _togglePlayPause() {
    _resetHideControlsTimer();
    _videoController.value.isPlaying ? _videoController.pause() : _videoController.play();
  }

  void _seekBackward(Duration d) {
    _resetHideControlsTimer();
    final p = _videoController.value.position - d;
    _videoController.seekTo(p < Duration.zero ? Duration.zero : p);
  }

  void _seekForward(Duration d) {
    _resetHideControlsTimer();
    final p = _videoController.value.position + d;
    _videoController.seekTo(p > _videoController.value.duration ? _videoController.value.duration : p);
  }

  void _showSpeedDialog() {
    _resetHideControlsTimer();
    showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('سرعة التشغيل'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (double speed in const [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0])
                ListTile(
                  title: Text('${speed}x'),
                  selected: _currentPlaybackSpeed == speed,
                  onTap: () {
                    setState(() {
                      _currentPlaybackSpeed = speed;
                      _videoController.setPlaybackSpeed(speed);
                    });
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showBrightnessDialog() async {
    _resetHideControlsTimer();
    double current = await ScreenBrightness().current;
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('السطوع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                min: 0.0,
                max: 1.0,
                value: current,
                onChanged: (value) async {
                  await ScreenBrightness().setScreenBrightness(value);
                  setState(() => current = value);
                },
              ),
              Text('الحالي: ${(current * 100).toStringAsFixed(0)}%'),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = _chewieController != null && _videoController.value.isInitialized;

    return Scaffold(
      appBar: PreferredSize(preferredSize: Size.zero, child: Container()),
      extendBodyBehindAppBar: true,
      body: ready
          ? Stack(
        children: [
          GestureDetector(
            onTap: _resetHideControlsTimer,
            onHorizontalDragStart: (d) {
              _dragStart = d.localPosition;
              _dragDx = 0;
              _isDragging = true;
              _videoController.pause();
            },
            onHorizontalDragUpdate: (d) {
              _dragDx += d.delta.dx;
              final newMs = (_videoController.value.position.inMilliseconds + (_dragDx * 500)).toInt();
              final newPos = Duration(milliseconds: newMs.clamp(0, _totalDuration.inMilliseconds));
              _videoController.seekTo(newPos);
            },
            onHorizontalDragEnd: (d) {
              _isDragging = false;
              _videoController.play();
            },
            child: Positioned.fill(
              child: AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: Chewie(controller: _chewieController!),
              ),
            ),
          ),
          if (_isDragging)
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                child: Text(_formatDuration(_videoController.value.position),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
              ),
            ),
          AnimatedOpacity(
            opacity: _areControlsVisible ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Slider(
                      min: 0,
                      max: _totalDuration.inMilliseconds.toDouble(),
                      value: _currentPosition.inMilliseconds.clamp(0, _totalDuration.inMilliseconds).toDouble(),
                      onChanged: (value) {
                        _videoController.seekTo(Duration(milliseconds: value.toInt()));
                        _resetHideControlsTimer();
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(_currentPosition), style: TextStyle(color: Colors.white)),
                        Text(_formatDuration(_totalDuration), style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(icon: Icon(Icons.replay_10, color: Colors.white), onPressed: () => _seekBackward(Duration(seconds: 10))),
                        IconButton(icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 36), onPressed: _togglePlayPause),
                        IconButton(icon: Icon(Icons.forward_10, color: Colors.white), onPressed: () => _seekForward(Duration(seconds: 10))),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(icon: Icon(Icons.brightness_6, color: Colors.white), onPressed: _showBrightnessDialog),
                        IconButton(icon: Icon(Icons.speed, color: Colors.white), onPressed: _showSpeedDialog),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
