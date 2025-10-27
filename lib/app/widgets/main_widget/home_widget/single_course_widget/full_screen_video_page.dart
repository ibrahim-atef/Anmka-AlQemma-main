import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FullScreenVideoPage extends StatefulWidget {
  final String url;
  final String name;
  final YoutubePlayerController controller;
  final Duration initialPosition;
  final bool shouldAutoPlay;

  const FullScreenVideoPage({
    Key? key,
    required this.url,
    required this.name,
    required this.controller,
    required this.initialPosition,
    required this.shouldAutoPlay,
  }) : super(key: key);

  @override
  State<FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<FullScreenVideoPage> {
  bool _disposed = false;
  Timer? _positionSaveTimer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    // Force landscape orientation + immersive mode for fullscreen
    _setLandscapeOrientation();

    // Set up position saving timer (save every 10 seconds)
    _positionSaveTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_mountedSafe) {
        _saveCurrentPosition();
      }
    });

    // Listen to player state changes
    widget.controller.listen((event) {
      if (event is YoutubePlayerValue) {
        setState(() {
          _isPlaying = event.playerState == PlayerState.playing;
        });
      }
    });

    // Use a post-frame callback to ensure the widget's build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_mountedSafe) return;
      
      // Auto-play if it was playing before
      if (widget.shouldAutoPlay) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_mountedSafe) {
            _playVideo();
          }
        });
      }
      
      // Seek to initial position if available
      if (widget.initialPosition.inSeconds > 0) {
        Future.delayed(const Duration(seconds: 1), () {
          if (_mountedSafe) {
            widget.controller.seekTo(seconds: widget.initialPosition.inSeconds.toDouble());
          }
        });
      }
    });
  }

  bool get _mountedSafe => mounted && !_disposed;

  /// Play the video
  void _playVideo() {
    try {
      widget.controller.playVideo();
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      log('Error playing video: $e');
    }
  }

  /// Pause the video
  void _pauseVideo() {
    try {
      widget.controller.pauseVideo();
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      log('Error pausing video: $e');
    }
  }

  /// Save current video position to SharedPreferences
  Future<void> _saveCurrentPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? videoId = _extractVideoId(widget.url);
      if (videoId != null) {
        // For youtube_player_iframe, we'll save a timestamp when the video starts playing
        final int currentSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        await prefs.setInt('video_position_$videoId', currentSeconds);
        log('Fullscreen: Saved position timestamp for video: $videoId');
      }
    } catch (e) {
      log('Fullscreen: Error saving position: $e');
    }
  }

  /// Extract video ID from YouTube URL
  String? _extractVideoId(String url) {
    try {
      return YoutubePlayerController.convertUrlToId(url);
    } catch (e) {
      log('Error extracting video ID: $e');
      return null;
    }
  }

  /// Ensures the device is set to landscape orientation and immersive mode.
  void _setLandscapeOrientation() {
    try {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } catch (e) {
      log('Error setting landscape orientation: $e');
    }
  }

  /// Resets UI mode and orientation when leaving.
  void _resetOrientation() {
    try {
      // Save position before leaving
      _saveCurrentPosition();
      
      // Restore standard UI mode and portrait orientation
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } catch (e) {
      log('Error resetting orientation: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _positionSaveTimer?.cancel();
    _positionSaveTimer = null;
    
    // Save final position before disposing
    _saveCurrentPosition();
    
    // Do NOT close the controller here; it is passed from PodVideoPlayerDev
    // Also do not force portrait orientation here; let the page popping handle it
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _resetOrientation();
        return true; // proceed with the pop
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // Video Player with overlay
              Center(
                child: Stack(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      child: YoutubePlayer(
                        controller: widget.controller,
                        aspectRatio: 16 / 9,
                      ),
                    ),
                    // White overlay to hide YouTube channel name and UI
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Back button
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      _resetOrientation();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
              // Play/Pause button
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (_isPlaying) {
                        _pauseVideo();
                      } else {
                        _playVideo();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}