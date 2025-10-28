import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webinar/app/widgets/main_widget/home_widget/single_course_widget/youTube_web_view.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class PodVideoPlayerDev extends StatefulWidget {
  final String type;
  final String url;
  final String name;
  final RouteObserver<ModalRoute<void>> routeObserver;

  const PodVideoPlayerDev(
    this.url,
    this.type,
    this.routeObserver, {
    super.key,
    required this.name,
  });

  /// Clear saved position for a specific video
  static Future<void> clearSavedPosition(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? videoId = _extractVideoId(url);
      if (videoId != null) {
        await prefs.remove('video_position_$videoId');
        log('Cleared saved position for video: $videoId');
      }
    } catch (e) {
      log('Error clearing saved position: $e');
    }
  }

  /// Clear all saved video positions
  static Future<void> clearAllSavedPositions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final videoPositionKeys =
          keys.where((key) => key.startsWith('video_position_'));

      for (final key in videoPositionKeys) {
        await prefs.remove(key);
      }

      log('Cleared all saved video positions');
    } catch (e) {
      log('Error clearing all saved positions: $e');
    }
  }

  /// Get saved position for a specific video
  static Future<Duration?> getSavedPosition(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? videoId = _extractVideoId(url);
      if (videoId != null) {
        final int? savedSeconds = prefs.getInt('video_position_$videoId');
        if (savedSeconds != null) {
          return Duration(seconds: savedSeconds);
        }
      }
      return null;
    } catch (e) {
      log('Error getting saved position: $e');
      return null;
    }
  }

  /// Extract video ID from YouTube URL
  static String? _extractVideoId(String url) {
    try {
      // Try different URL formats
      String? videoId = YoutubePlayerController.convertUrlToId(url);

      // If the standard method fails, try manual extraction
      if (videoId == null || videoId.isEmpty) {
        final uri = Uri.parse(url);
        if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
          if (uri.host.contains('youtu.be')) {
            videoId =
                uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
          } else {
            videoId = uri.queryParameters['v'];
          }
        }
      }

      log('Extracted video ID: $videoId from URL: $url');
      return videoId;
    } catch (e) {
      log('Error extracting video ID: $e');
      return null;
    }
  }

  @override
  State<PodVideoPlayerDev> createState() => _PodVideoPlayerDevState();
}

class _PodVideoPlayerDevState extends State<PodVideoPlayerDev> {
  bool _isFullScreen = false;
  final double _watermarkPositionX = 0.0;
  final double _watermarkPositionY = 0.0;
  Timer? _timer;
  YoutubePlayerController? _controller;
  bool _disposed = false;
  bool _isLoading = true;
  bool _isInitialized = false;
  Duration _savedPosition = Duration.zero;
  Timer? _positionSaveTimer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    // Load saved position first
    _loadSavedPosition().then((_) {
      _initializeVideoPlayer();
    });

    // Force portrait orientation
    _setPortraitOrientation();
  }

  /// Load saved video position from SharedPreferences
  Future<void> _loadSavedPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? videoId = PodVideoPlayerDev._extractVideoId(widget.url);
      if (videoId != null) {
        final int? savedSeconds = prefs.getInt('video_position_$videoId');
        if (savedSeconds != null) {
          _savedPosition = Duration(seconds: savedSeconds);
          log('Loaded saved position: $_savedPosition for video: $videoId');
        }
      }
    } catch (e) {
      log('Error loading saved position: $e');
    }
  }

  /// Save current video position to SharedPreferences
  Future<void> _saveCurrentPosition() async {
    if (_controller == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? videoId = PodVideoPlayerDev._extractVideoId(widget.url);
      if (videoId != null) {
        // For youtube_player_iframe, we'll save a timestamp when the video starts playing
        final int currentSeconds =
            DateTime.now().millisecondsSinceEpoch ~/ 1000;
        await prefs.setInt('video_position_$videoId', currentSeconds);
        log('Saved position timestamp for video: $videoId');
      }
    } catch (e) {
      log('Error saving position: $e');
    }
  }

  /// Initialize video player with youtube_player_iframe
  void _initializeVideoPlayer() {
    final String? videoId = PodVideoPlayerDev._extractVideoId(widget.url);
    log("Video URL: ${widget.url}");
    log("Extracted Video ID: $videoId");

    if (videoId == null || videoId.isEmpty) {
      log("Warning: Invalid or no video ID found in URL: ${widget.url}");
      setState(() {
        _isLoading = false;
        _isInitialized = false;
      });
      return;
    }

    try {
      // Initialize YouTube player controller
      _controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          mute: false,
          showControls: false, // Hide native controls (we render our own)
          enableCaption: true,
          loop: false,
          enableJavaScript: true,
          playsInline: true,
          origin:
              'https://www.youtube-nocookie.com', // This helps with Error 15
        ),
      );

      // Set up position saving timer (save every 10 seconds)
      _positionSaveTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (_mountedSafe && _controller != null) {
          _saveCurrentPosition();
        }
      });

      // Listen to player state changes
      _controller!.listen((event) {
        setState(() {
          _isPlaying = event.playerState == PlayerState.playing;
        });

        // Handle YouTube errors - check for error states
        if (event.playerState == PlayerState.unknown) {
          log('YouTube Player Error: Player state is unknown');
          log('This might indicate:');
          log('1. Video is private or unlisted');
          log('2. Video has embedding disabled');
          log('3. Video is restricted in your region');
          log('4. Video is age-restricted');
          log('5. Network connectivity issues');
        }
      });

      // Seek to saved position if available
      if (_savedPosition.inSeconds > 0) {
        Future.delayed(const Duration(seconds: 2), () {
          if (_mountedSafe && _controller != null) {
            _controller!.seekTo(seconds: _savedPosition.inSeconds.toDouble());
          }
        });
      }

      setState(() {
        _isLoading = false;
        _isInitialized = true;
      });

      log('YouTube player initialized successfully for video: $videoId');
    } catch (e) {
      log('Error initializing YouTube player: $e');
      setState(() {
        _isLoading = false;
        _isInitialized = false;
      });
    }
  }

  /// Ensures the device is fixed to portrait orientation.
  void _setPortraitOrientation() {
    try {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } catch (e) {
      log("Error setting device orientation: $e");
    }
  }

  void _toggleFullScreen() {
    if (_controller == null) return;
    if (!_mountedSafe) return;

    setState(() {
      _isFullScreen = true;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YouTubeWebView(videoUrl: widget.url),
      ),
    ).then((_) {
      if (!_mountedSafe) return;
      setState(() {
        _isFullScreen = false;
      });
      _setPortraitOrientation();
    });
  }

  // void _toggleFullScreen() {
  //   if (_controller == null) return;
  //   if (!_mountedSafe) return;

  //   setState(() {
  //     _isFullScreen = true;
  //   });

  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => CleanYouTubeWebView(videoUrl: widget.url),
  //       //  FullScreenVideoPage(
  //       //   url: widget.url,
  //       //   name: widget.name,
  //       //   controller: _controller!,
  //       //   initialPosition: _savedPosition,
  //       //   shouldAutoPlay: _isPlaying,
  //       // ),
  //     ),
  //   ).then((_) {
  //     if (!_mountedSafe) return;
  //     setState(() {
  //       _isFullScreen = false;
  //     });
  //     _setPortraitOrientation();
  //   });
  // }

  void _togglePlayPause() {
    if (_controller == null) return;

    try {
      if (_isPlaying) {
        _controller!.pauseVideo();
      } else {
        _controller!.playVideo();
      }
    } catch (e) {
      log('Error toggling play/pause: $e');
    }
  }

  void _seekForward() {
    if (_controller == null) return;
    try {
      // For youtube_player_iframe, we'll use a simple approach
      // Since we can't get current position easily, we'll just seek forward by 10 seconds
      _controller!.seekTo(seconds: 10.0, allowSeekAhead: true);
    } catch (e) {
      log('Error seeking forward: $e');
    }
  }

  void _seekBackward() {
    if (_controller == null) return;
    try {
      // For youtube_player_iframe, we'll use a simple approach
      // Since we can't get current position easily, we'll just seek backward by 10 seconds
      _controller!.seekTo(seconds: -10.0, allowSeekAhead: true);
    } catch (e) {
      log('Error seeking backward: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _positionSaveTimer?.cancel();
    _positionSaveTimer = null;

    _controller?.close();
    _controller = null;
    super.dispose();
  }

  bool get _mountedSafe => mounted && !_disposed;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 250,
            width: MediaQuery.of(context).size.width,
            child: Stack(
              children: [
                // Video Player or Loading
                if (_isLoading)
                  Container(
                    height: 250,
                    width: MediaQuery.of(context).size.width,
                    color: Colors.black87,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading video...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (!_isInitialized || _controller == null)
                  Container(
                    height: 250,
                    width: MediaQuery.of(context).size.width,
                    color: Colors.black87,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Failed to load video',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Error 15: Video may be private, restricted, or not available for embedding',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Try to reload the video
                              _initializeVideoPlayer();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Stack(
                    children: [
                      SizedBox(
                        height: 250,
                        width: MediaQuery.of(context).size.width,
                        child: YoutubePlayer(
                          controller: _controller!,
                          aspectRatio: 16 / 9,
                        ),
                      ),
                      // White overlay to hide YouTube channel name and UI
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                // Bottom Controls Bar (only show when video is ready)
                if (_isInitialized && _controller != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: Colors.black.withOpacity(0.2),
                      child: Row(
                        children: [
                          // Play/Pause Button
                          IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: _togglePlayPause,
                          ),
                          // Seek Backward Button
                          IconButton(
                            icon: const Icon(
                              Icons.replay_10,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: _seekBackward,
                          ),
                          // Seek Forward Button
                          IconButton(
                            icon: const Icon(
                              Icons.forward_10,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: _seekForward,
                          ),
                          const Spacer(),
                          // Fullscreen button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.fullscreen,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: _toggleFullScreen,
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
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
