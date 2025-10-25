import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FullScreenVideoPage extends StatefulWidget {
  final String url;
  final String name;
  final WebViewController controller;
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
      
      // YouTube interactions are now allowed
    });
  }

  bool get _mountedSafe => mounted && !_disposed;

  /// Play the video
  void _playVideo() {
    try {
      widget.controller.runJavaScript('''
        function tryPlayVideo() {
          var videoElement = document.querySelector("video");
          if (videoElement) {
            console.log('Fullscreen video element found, readyState:', videoElement.readyState);
            
            if (videoElement.readyState >= 2) {
              var playPromise = videoElement.play();
              if (playPromise !== undefined) {
                playPromise.then(function() {
                  console.log('Fullscreen video started playing');
                }).catch(function(error) {
                  console.log('Fullscreen play failed:', error.name, error.message);
                  // Try muted play as fallback
                  videoElement.muted = true;
                  videoElement.play().then(function() {
                    videoElement.muted = false;
                    console.log('Fullscreen video started playing (muted first)');
                  }).catch(function(err) {
                    console.log('Fullscreen play failed even with mute:', err.name, err.message);
                  });
                });
              }
            } else {
              console.log('Fullscreen video not ready, readyState:', videoElement.readyState);
              // Wait for video to be ready
              videoElement.addEventListener('canplay', function() {
                console.log('Fullscreen video can now play, readyState:', videoElement.readyState);
                var playPromise = videoElement.play();
                if (playPromise !== undefined) {
                  playPromise.then(function() {
                    console.log('Fullscreen video started playing after canplay event');
                  }).catch(function(error) {
                    console.log('Fullscreen play failed after canplay:', error.name, error.message);
                    // Try muted play as fallback
                    videoElement.muted = true;
                    videoElement.play().then(function() {
                      videoElement.muted = false;
                      console.log('Fullscreen video started playing (muted first) after canplay');
                    }).catch(function(err) {
                      console.log('Fullscreen play failed even with mute after canplay:', err.name, err.message);
                    });
                  });
                }
              }, { once: true });
            }
          } else {
            console.log('Fullscreen video element not found');
          }
        }
        
        setTimeout(tryPlayVideo, 500);
      ''');
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
      widget.controller.runJavaScript('''
        var videoElement = document.querySelector("video");
        if (videoElement) {
          videoElement.pause();
        }
      ''');
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
        final int currentSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        await prefs.setInt('video_position_$videoId', currentSeconds);
        log('Fullscreen: Saved position timestamp for video: $videoId');
      }
    } catch (e) {
      log('Fullscreen: Error saving position: $e');
    }
  }

  /// Disable YouTube interactions to prevent navigation
  void _disableYouTubeInteractions() {
    try {
      widget.controller.runJavaScript('''
        // Disable all clickable elements
        document.addEventListener('click', function(e) {
          e.preventDefault();
          e.stopPropagation();
          return false;
        }, true);
        
        // Disable right-click context menu
        document.addEventListener('contextmenu', function(e) {
          e.preventDefault();
          return false;
        });
        
        // Disable all links and buttons
        var links = document.querySelectorAll('a, button, [onclick]');
        links.forEach(function(link) {
          link.style.pointerEvents = 'none';
          link.onclick = function(e) {
            e.preventDefault();
            return false;
          };
        });
        
        // Disable YouTube logo and channel name clicks
        var logo = document.querySelector('#logo');
        if (logo) {
          logo.style.pointerEvents = 'none';
          logo.onclick = function(e) {
            e.preventDefault();
            return false;
          };
        }
        
        // Disable channel name clicks
        var channelName = document.querySelector('#channel-name');
        if (channelName) {
          channelName.style.pointerEvents = 'none';
          channelName.onclick = function(e) {
            e.preventDefault();
            return false;
          };
        }
        
        // Disable subscribe button
        var subscribeButton = document.querySelector('#subscribe-button');
        if (subscribeButton) {
          subscribeButton.style.pointerEvents = 'none';
          subscribeButton.onclick = function(e) {
            e.preventDefault();
            return false;
          };
        }
        
        // Disable all YouTube UI elements
        var youtubeElements = document.querySelectorAll('[id*="youtube"], [class*="yt"], [href*="youtube"]');
        youtubeElements.forEach(function(element) {
          element.style.pointerEvents = 'none';
          element.onclick = function(e) {
            e.preventDefault();
            return false;
          };
        });
      ''');
    } catch (e) {
      log('Error disabling YouTube interactions: $e');
    }
  }

  /// Extract video ID from YouTube URL
  String? _extractVideoId(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
        if (uri.host.contains('youtu.be')) {
          return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
        } else {
          return uri.queryParameters['v'];
        }
      }
      return null;
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
    
    // Do NOT dispose the controller here; it is passed from PodVideoPlayerDev
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
                      child: WebViewWidget(controller: widget.controller),
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
