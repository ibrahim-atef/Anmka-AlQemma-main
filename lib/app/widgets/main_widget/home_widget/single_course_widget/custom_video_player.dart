import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webinar/app/models/content_model.dart';
import 'package:webinar/app/models/note_model.dart';
import 'package:webinar/app/models/single_content_model.dart';
import 'package:webinar/app/pages/main_page/home_page/single_course_page/single_content_page/pdf_viewer_page.dart';
import 'package:webinar/app/pages/main_page/home_page/single_course_page/single_content_page/web_view_page.dart';
import 'package:webinar/app/services/guest_service/course_service.dart';
import 'package:webinar/app/services/user_service/personal_note_service.dart';
import 'package:webinar/common/common.dart';
import 'package:webinar/common/components.dart';
import 'package:webinar/common/data/api_public_data.dart';
import 'package:webinar/common/data/app_data.dart';
import 'package:webinar/common/data/app_language.dart';
import 'package:webinar/common/enums/error_enum.dart';
import 'package:webinar/common/utils/app_text.dart';
import 'package:webinar/common/utils/constants.dart';
import 'package:webinar/config/colors.dart';
import 'package:webinar/config/styles.dart';
import 'package:html/parser.dart';
import 'package:webinar/locator.dart';

import '../../../../../../common/utils/date_formater.dart';
import '../../../../../../config/assets.dart';

import '../../../../widgets/main_widget/home_widget/single_course_widget/course_video_player.dart';

import 'full_screen_video_page.dart';

class PodVideoPlayerDev extends StatefulWidget {
  final String type;
  final String url;
  final String name;
  final RouteObserver<ModalRoute<void>> routeObserver;

  const PodVideoPlayerDev(
      this.url,
      this.type,
      this.routeObserver, {
        Key? key,
        required this.name,
      }) : super(key: key);

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
      final videoPositionKeys = keys.where((key) => key.startsWith('video_position_'));
      
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

  @override
  State<PodVideoPlayerDev> createState() => _PodVideoPlayerDevState();
}

class _PodVideoPlayerDevState extends State<PodVideoPlayerDev> {
  bool _isFullScreen = false;
  double _watermarkPositionX = 0.0;
  double _watermarkPositionY = 0.0;
  Timer? _timer;
  WebViewController? _controller;
  WebViewController? _fullscreenController;
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
        // For WebView, we'll save a timestamp when the video starts playing
        final int currentSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        await prefs.setInt('video_position_$videoId', currentSeconds);
        log('Saved position timestamp for video: $videoId');
      }
    } catch (e) {
      log('Error saving position: $e');
    }
  }

  /// Initialize video player with WebView
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
      // Create YouTube embed URL with autoplay and controls
      final String embedUrl = 'https://www.youtube.com/embed/$videoId?enablejsapi=1&origin=https://alqemma.anmka.com&autoplay=1&controls=1&rel=0&modestbranding=1&playsinline=1&allowfullscreen=1';
      
      // Initialize WebView controllers
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent('Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36')
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              log('WebView page finished loading: $url');
              setState(() {
                _isLoading = false;
                _isInitialized = true;
              });
              // Wait for video to be ready and set up event listeners
              _setupVideoEventListeners();
            },
            onWebResourceError: (WebResourceError error) {
              log('WebView error: ${error.description}');
              setState(() {
                _isLoading = false;
                _isInitialized = false;
              });
            },
            onNavigationRequest: (NavigationRequest request) {
              // Allow navigation within YouTube domain
              if (request.url.contains('youtube.com') || request.url.contains('youtu.be')) {
                log('Allowing YouTube navigation to: ${request.url}');
                return NavigationDecision.navigate;
              }
              log('Blocked non-YouTube navigation to: ${request.url}');
              return NavigationDecision.prevent;
            },
          ),
        )
        ..loadRequest(Uri.parse(embedUrl));

      _fullscreenController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent('Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36')
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              log('Fullscreen WebView page finished loading: $url');
            },
            onWebResourceError: (WebResourceError error) {
              log('Fullscreen WebView error: ${error.description}');
            },
            onNavigationRequest: (NavigationRequest request) {
              // Allow navigation within YouTube domain
              if (request.url.contains('youtube.com') || request.url.contains('youtu.be')) {
                log('Allowing fullscreen YouTube navigation to: ${request.url}');
                return NavigationDecision.navigate;
              }
              log('Blocked non-YouTube fullscreen navigation to: ${request.url}');
              return NavigationDecision.prevent;
            },
          ),
        )
        ..loadRequest(Uri.parse(embedUrl));

      // Set up position saving timer (save every 10 seconds)
      _positionSaveTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (_mountedSafe && _controller != null) {
          _saveCurrentPosition();
        }
      });

      // Set up video readiness check timer
      _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (_mountedSafe && _controller != null) {
          _checkVideoReadiness();
        }
      });

      setState(() {
        _isLoading = false;
        _isInitialized = true;
      });

      log('WebView video player initialized successfully for video: $videoId');
    } catch (e) {
      log('Error initializing WebView video player: $e');
      setState(() {
        _isLoading = false;
        _isInitialized = false;
      });
    }
  }

  /// Disable YouTube interactions to prevent navigation
  void _disableYouTubeInteractions() {
    if (_controller == null) return;
    
    try {
      _controller!.runJavaScript('''
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

  /// Disable YouTube interactions for fullscreen
  void _disableYouTubeInteractionsFullscreen() {
    if (_fullscreenController == null) return;
    
    try {
      _fullscreenController!.runJavaScript('''
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
      log('Error disabling YouTube interactions in fullscreen: $e');
    }
  }

  /// Set up video event listeners to track play state
  void _setupVideoEventListeners() {
    if (_controller == null) return;
    
    try {
      _controller!.runJavaScript('''
        // Wait for video element to be available and ready
        function waitForVideo() {
          var videoElement = document.querySelector("video");
          if (videoElement) {
            console.log('Video element found, readyState:', videoElement.readyState);
            
            // Set up event listeners
            videoElement.addEventListener('loadstart', function() {
              console.log('Video load started');
            });
            
            videoElement.addEventListener('loadedmetadata', function() {
              console.log('Video metadata loaded');
            });
            
            videoElement.addEventListener('loadeddata', function() {
              console.log('Video data loaded, readyState:', videoElement.readyState);
            });
            
            videoElement.addEventListener('canplay', function() {
              console.log('Video can start playing, readyState:', videoElement.readyState);
              // Try to play the video when it's ready
              if (videoElement.paused) {
                videoElement.play().catch(function(error) {
                  console.log('Auto-play failed:', error);
                });
              }
            });
            
            videoElement.addEventListener('canplaythrough', function() {
              console.log('Video can play through, readyState:', videoElement.readyState);
            });
            
            videoElement.addEventListener('play', function() {
              console.log('Video started playing');
            });
            
            videoElement.addEventListener('pause', function() {
              console.log('Video paused');
            });
            
            // If video is already ready, try to play it
            if (videoElement.readyState >= 2) {
              console.log('Video already ready, readyState:', videoElement.readyState);
              if (videoElement.paused) {
                videoElement.play().catch(function(error) {
                  console.log('Auto-play failed on ready video:', error);
                });
              }
            }
            
            return true;
          }
          return false;
        }
        
        // Try to set up listeners immediately
        if (!waitForVideo()) {
          // If video not ready, try again with increasing delays
          var attempts = 0;
          var maxAttempts = 15;
          
          function retryWaitForVideo() {
            attempts++;
            console.log('Attempt', attempts, 'to find video element');
            
            if (waitForVideo()) {
              console.log('Video element found on attempt', attempts);
            } else if (attempts < maxAttempts) {
              setTimeout(retryWaitForVideo, 1000 * attempts); // Increasing delay
            } else {
              console.log('Max attempts reached, video element not found');
            }
          }
          
          setTimeout(retryWaitForVideo, 1000);
        }
      ''');
    } catch (e) {
      log('Error setting up video event listeners: $e');
    }
  }

  /// Check if video is ready and update UI accordingly
  void _checkVideoReadiness() {
    if (_controller == null) return;
    
    try {
      _controller!.runJavaScript('''
        var videoElement = document.querySelector("video");
        if (videoElement) {
          console.log('Video readiness check - readyState:', videoElement.readyState, 'paused:', videoElement.paused);
          
          // If video is ready and we can control it
          if (videoElement.readyState >= 2) {
            console.log('Video is ready for control');
          }
        }
      ''');
    } catch (e) {
      log('Error checking video readiness: $e');
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
    if (_controller == null || _fullscreenController == null) return;
    if (!_mountedSafe) return;

    setState(() {
      _isFullScreen = true;
    });

      Navigator.push(
        context,
        MaterialPageRoute(
        builder: (context) => FullScreenVideoPage(
          url: widget.url,
          name: widget.name,
          controller: _fullscreenController!,
          initialPosition: _savedPosition,
          shouldAutoPlay: _isPlaying,
        ),
        ),
      ).then((_) {
      if (!_mountedSafe) return;
      setState(() {
        _isFullScreen = false;
      });
      _setPortraitOrientation();
    });
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    
    try {
      if (_isPlaying) {
        _controller!.runJavaScript('''
          setTimeout(function() {
            var videoElement = document.querySelector("video");
            if (videoElement && !videoElement.paused) {
              videoElement.pause();
            }
          }, 200);
        ''');
        setState(() {
          _isPlaying = false;
        });
      } else {
        _controller!.runJavaScript('''
          function tryPlayVideo() {
            var videoElement = document.querySelector("video");
            if (videoElement) {
              console.log('Attempting to play video, readyState:', videoElement.readyState);
              
              if (videoElement.readyState >= 2) {
                // Video is ready, try to play
                var playPromise = videoElement.play();
                if (playPromise !== undefined) {
                  playPromise.then(function() {
                    console.log('Video started playing successfully');
                  }).catch(function(error) {
                    console.log('Play failed:', error.name, error.message);
                    // Try muted play as fallback
                    videoElement.muted = true;
                    videoElement.play().then(function() {
                      videoElement.muted = false;
                      console.log('Video started playing (muted first)');
                    }).catch(function(err) {
                      console.log('Play failed even with mute:', err.name, err.message);
                    });
                  });
                }
              } else {
                console.log('Video not ready yet, readyState:', videoElement.readyState);
                // Wait for video to be ready
                videoElement.addEventListener('canplay', function() {
                  console.log('Video can now play, readyState:', videoElement.readyState);
                  var playPromise = videoElement.play();
                  if (playPromise !== undefined) {
                    playPromise.then(function() {
                      console.log('Video started playing after canplay event');
                    }).catch(function(error) {
                      console.log('Play failed after canplay:', error.name, error.message);
                    });
                  }
                }, { once: true });
              }
            } else {
              console.log('Video element not found');
            }
          }
          
          setTimeout(tryPlayVideo, 500);
        ''');
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      log('Error toggling play/pause: $e');
    }
  }

  void _seekForward() {
    if (_controller == null) return;
    try {
      _controller!.runJavaScript('''
        var videoElement = document.querySelector("video");
        if (videoElement) {
          videoElement.currentTime += 10;
        }
      ''');
    } catch (e) {
      log('Error seeking forward: $e');
    }
  }

  void _seekBackward() {
    if (_controller == null) return;
    try {
      _controller!.runJavaScript('''
        var videoElement = document.querySelector("video");
        if (videoElement) {
          videoElement.currentTime -= 10;
        }
      ''');
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

    _controller = null;
    _fullscreenController = null;
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Failed to load video',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
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
                        child: WebViewWidget(controller: _controller!),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
