// lib/screens/music_player_screen.dart

// Import Flutter material design components for UI.
import 'package:flutter/material.dart';
// Import the just_audio package for audio playback functionality.
import 'package:just_audio/just_audio.dart';
// Import our MediaFile model to get audio details.
import 'package:sanad_player/models/media_file.dart';
// Import theme utilities for consistent styling.
import 'package:sanad_player/utils/theme.dart';
// Import path package for path manipulation (for displaying base name of file).
import 'package:path/path.dart' as p;

// MusicPlayerScreen is a StatefulWidget because it manages the state of the audio player,
// such as its controller, playback status, and position.
class MusicPlayerScreen extends StatefulWidget {
  // The MediaFile object representing the audio to be played.
  final MediaFile audioFile;

  // Constructor for MusicPlayerScreen, requires a MediaFile object.
  const MusicPlayerScreen({super.key, required this.audioFile});

  @override
  // createState creates the mutable state for this widget.
  _MusicPlayerScreenState createState() => _MusicPlayerScreenState();
}

// The State class for MusicPlayerScreen.
class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  // AudioPlayer instance to control the audio playback.
  late AudioPlayer _audioPlayer;
  // Stream subscription for player state changes.
  Stream<PlayerState> get _playerStateStream => _audioPlayer.playerStateStream;
  // Stream subscription for position changes.
  Stream<Duration> get _positionStream => _audioPlayer.positionStream;
  // Stream subscription for total duration changes.
  Stream<Duration?> get _durationStream => _audioPlayer.durationStream;

  @override
  // initState is called once when the widget is inserted into the widget tree.
  // This is where we initialize the audio player.
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer(); // Initialize the audio player.
    _initAudioPlayer(); // Call a method to set up and load the audio.
  }

  // Asynchronous method to set up and load the audio file.
  Future<void> _initAudioPlayer() async {
    try {
      // Set the audio source using the file path.
      await _audioPlayer.setFilePath(widget.audioFile.filePath);
      // Start playing the audio automatically.
      _audioPlayer.play();
    } catch (e) {
      // Handle any errors during audio initialization (e.g., file not found).
      print("Error loading audio: ${widget.audioFile.fileName} - $e");
      if (mounted) { // Check if the widget is still in the tree before showing SnackBar.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: ${e.toString()}')),
        );
      }
    }
  }

  @override
  // dispose is called when the widget is removed from the widget tree permanently.
  // It's crucial to dispose of the AudioPlayer to release resources.
  void dispose() {
    _audioPlayer.dispose(); // Release audio player resources.
    super.dispose();
  }

  // Helper method to format Duration into a human-readable string (e.g., "01:23").
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  // The build method describes the user interface of the music player screen.
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.audioFile.fileName), // Display the audio file name in app bar.
        centerTitle: true, // Center the title for player screen.
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0), // Increased padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space out content top to bottom
            children: [
              // Top section: Album Art/Music Icon
              Expanded(
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.7, // 70% of screen width
                    height: MediaQuery.of(context).size.width * 0.7, // Square aspect ratio
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface, // Background for album art
                      borderRadius: BorderRadius.circular(16.0), // Rounded corners
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.music_note,
                      size: 100, // Slightly smaller icon
                      color: Theme.of(context).colorScheme.secondary, // Use accent color
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40), // Spacing between album art and text

              // Middle Section: Song Title
              Column(
                children: [
                  Text(
                    p.basenameWithoutExtension(widget.audioFile.fileName), // Display file name without extension
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unknown Artist / Unknown Album', // Placeholder for artist/album
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40), // Spacing before controls

              // Bottom Section: Playback Controls and Slider
              Column(
                children: [
                  // Playback progress slider and time display.
                  StreamBuilder<Duration?>(
                    stream: _durationStream, // Stream for total duration
                    builder: (context, durationSnapshot) {
                      final totalDuration = durationSnapshot.data ?? Duration.zero; // Get total duration
                      return StreamBuilder<Duration>(
                        stream: _positionStream, // Stream for current playback position
                        builder: (context, positionSnapshot) {
                          final currentPosition = positionSnapshot.data ?? Duration.zero; // Get current position

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0.0), // No horizontal padding here as it's outside
                            child: Column(
                              children: [
                                Slider(
                                  min: 0.0,
                                  max: totalDuration.inMilliseconds.toDouble(),
                                  value: currentPosition.inMilliseconds.toDouble().clamp(0.0, totalDuration.inMilliseconds.toDouble()),
                                  onChanged: (value) {
                                    _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                                  },
                                  activeColor: Theme.of(context).colorScheme.secondary,
                                  inactiveColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(currentPosition),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    Text(
                                      _formatDuration(totalDuration),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20), // Spacing for controls

                  // Main Playback Controls: Previous, Play/Pause, Next
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Evenly distribute buttons
                    children: [
                      IconButton(
                        iconSize: 48.0,
                        icon: const Icon(Icons.skip_previous), // Previous track icon
                        onPressed: () {
                          // TODO: Implement skip to previous track logic
                          print('Previous track tapped');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Previous track not implemented yet!')),
                          );
                        },
                      ),
                      // Play/Pause button (updates based on player state stream).
                      StreamBuilder<PlayerState>(
                        stream: _playerStateStream,
                        builder: (context, snapshot) {
                          final playerState = snapshot.data;
                          final processingState = playerState?.processingState;
                          final playing = playerState?.playing;

                          if (processingState == ProcessingState.loading ||
                              processingState == ProcessingState.buffering) {
                            return Container(
                              margin: const EdgeInsets.all(8.0),
                              width: 64.0,
                              height: 64.0,
                              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                            );
                          } else if (playing != true) {
                            return IconButton(
                              iconSize: 64.0,
                              icon: const Icon(Icons.play_circle_filled),
                              onPressed: _audioPlayer.play,
                              color: Theme.of(context).colorScheme.primary,
                            );
                          } else if (processingState != ProcessingState.completed) {
                            return IconButton(
                              iconSize: 64.0,
                              icon: const Icon(Icons.pause_circle_filled),
                              onPressed: _audioPlayer.pause,
                              color: Theme.of(context).colorScheme.primary,
                            );
                          } else {
                            return IconButton(
                              iconSize: 64.0,
                              icon: const Icon(Icons.replay),
                              onPressed: () => _audioPlayer.seek(Duration.zero),
                              color: Theme.of(context).colorScheme.primary,
                            );
                          }
                        },
                      ),
                      IconButton(
                        iconSize: 48.0,
                        icon: const Icon(Icons.skip_next), // Next track icon
                        onPressed: () {
                          // TODO: Implement skip to next track logic
                          print('Next track tapped');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Next track not implemented yet!')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16), // Spacing after controls

                  // Optional: Shuffle/Repeat buttons or other bottom controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shuffle),
                        onPressed: () {
                          print('Shuffle tapped');
                          // TODO: Implement shuffle functionality
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.repeat),
                        onPressed: () {
                          print('Repeat tapped');
                          // TODO: Implement repeat functionality
                        },
                      ),
                      // Add more controls here as per mockup or desire
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}