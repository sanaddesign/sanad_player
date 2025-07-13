// lib/widgets/custom_video_controls.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:sanad_player/utils/theme.dart';
import 'package:screen_brightness/screen_brightness.dart';

class CustomVideoControls extends StatefulWidget {
  final VideoPlayerController videoController;
  final ChewieController chewieController;
  final String videoTitle;

  const CustomVideoControls({
    super.key,
    required this.videoController,
    required this.chewieController,
    required this.videoTitle,
  });

  @override
  State<CustomVideoControls> createState() => _CustomVideoControlsState();
}

class _CustomVideoControlsState extends State<CustomVideoControls> {
  bool _isVisible = true;
  Timer? _hideControlsTimer;

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;
  double _currentPlaybackSpeed = 1.0;

  Offset _dragStart = Offset.zero;
  double _dragDx = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    widget.videoController.addListener(_videoPlayerListener);
    if (widget.videoController.value.isInitialized) {
      _currentPosition = widget.videoController.value.position;
      _totalDuration = widget.videoController.value.duration;
      _isPlaying = widget.videoController.value.isPlaying;
    }
    _startHideControlsTimer();
  }

  @override
  void dispose() {
    widget.videoController.removeListener(_videoPlayerListener);
    _hideControlsTimer?.cancel();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  void _videoPlayerListener() {
    if (mounted) {
      setState(() {
        _currentPosition = widget.videoController.value.position;
        _totalDuration = widget.videoController.value.duration;
        _isPlaying = widget.videoController.value.isPlaying;
      });
      _resetHideControlsTimer();
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && widget.chewieController.isFullScreen == false) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _startHideControlsTimer();
    if (!_isVisible) {
      setState(() {
        _isVisible = true;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  void _togglePlayPause() {
    _resetHideControlsTimer();
    if (widget.videoController.value.isPlaying) {
      widget.videoController.pause();
    } else {
      widget.videoController.play();
    }
  }

  void _seekBackward(Duration duration) {
    _resetHideControlsTimer();
    final newPosition = widget.videoController.value.position - duration;
    widget.videoController.seekTo(newPosition.isNegative ? Duration.zero : newPosition);
  }

  void _seekForward(Duration duration) {
    _resetHideControlsTimer();
    final newPosition = widget.videoController.value.position + duration;
    final totalDuration = widget.videoController.value.duration;
    widget.videoController.seekTo(newPosition > totalDuration ? totalDuration : newPosition);
  }

  void _showSpeedDialog() {
    _resetHideControlsTimer();
    showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Playback Speed'),
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
                      widget.videoController.setPlaybackSpeed(speed);
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

  void _toggleOrientation() {
    _resetHideControlsTimer();
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  Future<void> _showBrightnessDialog() async {
    _resetHideControlsTimer();
    double currentBrightness = await ScreenBrightness().current;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Brightness'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      Slider(
                        min: 0.0,
                        max: 1.0,
                        value: currentBrightness,
                        onChanged: (value) async {
                          await ScreenBrightness().setScreenBrightness(value);
                          setState(() {
                            currentBrightness = value;
                          });
                        },
                        activeColor: AppColors.accentCyan,
                        inactiveColor: Colors.grey,
                      ),
                      Text('Current: ${(currentBrightness * 100).toStringAsFixed(0)}%'),
                    ],
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final videoValue = widget.videoController.value;
    final currentPosition = videoValue.position;
    final totalDuration = videoValue.duration;
    final isPlaying = videoValue.isPlaying;

    return Stack(
      children: [
        GestureDetector(
          onTap: _resetHideControlsTimer,
          onHorizontalDragStart: (details) {
            _dragStart = details.localPosition;
            _dragDx = 0.0;
            _isDragging = true;
            widget.videoController.pause();
            _resetHideControlsTimer();
          },
          onHorizontalDragUpdate: (details) {
            setState(() {
              _dragDx += details.delta.dx;
            });
            final newPositionMs = (currentPosition.inMilliseconds + (_dragDx * 500)).toInt();
            final newPosition = Duration(
              milliseconds: newPositionMs.clamp(0, totalDuration.inMilliseconds),
            );
            widget.videoController.seekTo(newPosition);
          },
          onHorizontalDragEnd: (details) {
            _isDragging = false;
            widget.videoController.play();
            _resetHideControlsTimer();
          },
          child: AspectRatio(
            aspectRatio: videoValue.aspectRatio,
            child: Chewie(controller: widget.chewieController),
          ),
        ),

        if (_isDragging)
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatDuration(currentPosition),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
            ),
          ),

        AnimatedOpacity(
          opacity: _isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              color: Colors.black.withOpacity(0.6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    min: 0.0,
                    max: totalDuration.inMilliseconds.toDouble(),
                    value: currentPosition.inMilliseconds.toDouble().clamp(0.0, totalDuration.inMilliseconds.toDouble()),
                    onChanged: (value) {
                      widget.videoController.seekTo(Duration(milliseconds: value.toInt()));
                      _resetHideControlsTimer();
                    },
                    activeColor: AppColors.accentCyan,
                    inactiveColor: Colors.white.withOpacity(0.3),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(currentPosition), style: TextStyle(color: Colors.white)),
                      Text(_formatDuration(totalDuration), style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.replay_10, color: Colors.white, size: 36),
                        onPressed: () => _seekBackward(const Duration(seconds: 10)),
                      ),
                      IconButton(
                        icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.white, size: 64),
                        onPressed: _togglePlayPause,
                      ),
                      IconButton(
                        icon: const Icon(Icons.forward_10, color: Colors.white, size: 36),
                        onPressed: () => _seekForward(const Duration(seconds: 10)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.volume_up, color: Colors.white),
                        onPressed: () {
                          _resetHideControlsTimer();
                          final currentVolume = widget.videoController.value.volume;
                          widget.videoController.setVolume(currentVolume > 0 ? 0.0 : 1.0);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.brightness_6, color: Colors.white),
                        onPressed: _showBrightnessDialog,
                      ),
                      IconButton(
                        icon: const Icon(Icons.speed, color: Colors.white),
                        onPressed: _showSpeedDialog,
                      ),
                      IconButton(
                        icon: const Icon(Icons.screen_rotation, color: Colors.white),
                        onPressed: _toggleOrientation,
                      ),
                      IconButton(
                        icon: Icon(
                          widget.chewieController.isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          widget.chewieController.toggleFullScreen();
                          _resetHideControlsTimer();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        AnimatedOpacity(
          opacity: _isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Align(
            alignment: Alignment.topCenter,
            child: AppBar(
              title: Text(widget.videoTitle),
              centerTitle: true,
              backgroundColor: Colors.black.withOpacity(0.6),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
