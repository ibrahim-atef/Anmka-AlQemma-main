import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pod_player/pod_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static Future<void> clearSavedPosition(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _storageKey(url);
      await prefs.remove(key);
      log('Cleared saved position for video key: $key');
    } catch (e) {
      log('Error clearing saved position: $e');
    }
  }

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

  static Future<Duration?> getSavedPosition(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _storageKey(url);
      final int? savedSeconds = prefs.getInt(key);
      if (savedSeconds != null) {
        return Duration(seconds: savedSeconds);
      }
      return null;
    } catch (e) {
      log('Error getting saved position: $e');
      return null;
    }
  }

  static String _storageKey(String url) {
    final videoId = _extractVideoId(url);
    final safeId = (videoId == null || videoId.isEmpty)
        ? Uri.encodeComponent(url)
        : videoId;
    return 'video_position_$safeId';
  }

  static String? _extractVideoId(String url) {
    try {
      final uri = Uri.parse(url);

      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      }

      if (uri.host.contains('youtube.com')) {
        if (uri.queryParameters.containsKey('v')) {
          final videoId = uri.queryParameters['v'];
          if (videoId != null && videoId.isNotEmpty) {
            log('Extracted video ID: $videoId from URL: $url');
            return videoId;
          }
        }

        if (uri.pathSegments.contains('embed') && uri.pathSegments.isNotEmpty) {
          final videoId = uri.pathSegments.last;
          log('Extracted embedded video ID: $videoId from URL: $url');
          return videoId;
        }

        if (uri.pathSegments.isNotEmpty) {
          final videoId = uri.pathSegments.last;
          if (videoId.isNotEmpty) {
            log('Extracted video ID from path: $videoId from URL: $url');
            return videoId;
          }
        }
      }

      final lastSegment =
          uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
      if (lastSegment != null && lastSegment.isNotEmpty) {
        log('Using last path segment as video key: $lastSegment');
        return lastSegment;
      }

      if (url.isNotEmpty) {
        log('Falling back to full URL as key');
        return url;
      }
    } catch (e) {
      log('Error extracting video ID: $e');
    }

    return null;
  }

  @override
  State<PodVideoPlayerDev> createState() => _PodVideoPlayerDevState();
}

class _PodVideoPlayerDevState extends State<PodVideoPlayerDev> {
  PodPlayerController? _controller;
  bool _disposed = false;
  bool _isLoading = true;
  bool _isInitialized = false;
  bool _hasInitializationError = false;
  Duration _savedPosition = Duration.zero;
  Timer? _positionSaveTimer;
  Timer? _watermarkTimer;
  Alignment _watermarkAlignment = const Alignment(-0.9, -0.9);
  int _watermarkAlignmentIndex = 0;

  static const List<Alignment> _watermarkPositions = [
    Alignment(-0.9, -0.9),
    Alignment(0.0, -0.6),
    Alignment(0.9, -0.9),
    Alignment(0.9, 0.0),
    Alignment(0.6, 0.9),
    Alignment(-0.2, 0.9),
    Alignment(-0.9, 0.2),
  ];

  @override
  void initState() {
    super.initState();
    _setPortraitOrientation();

    _loadSavedPosition().then((_) {
      if (!_mountedSafe) return;
      _initializeVideoPlayer();
    });
    _startWatermarkAnimation();
  }

  Future<void> _loadSavedPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = PodVideoPlayerDev._storageKey(widget.url);
      final int? savedSeconds = prefs.getInt(key);
      if (savedSeconds != null) {
        _savedPosition = Duration(seconds: savedSeconds);
        log('Loaded saved position: $_savedPosition for key: $key');
      }
    } catch (e) {
      log('Error loading saved position: $e');
    }
  }

  Future<void> _saveCurrentPosition() async {
    final controller = _controller;
    if (controller == null || !controller.isInitialised) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = PodVideoPlayerDev._storageKey(widget.url);
      final currentSeconds = controller.currentVideoPosition.inSeconds;
      await prefs.setInt(key, currentSeconds);
      log('Saved position $currentSeconds seconds for key: $key');
    } catch (e) {
      log('Error saving position: $e');
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if (!_mountedSafe) return;

    setState(() {
      _isLoading = true;
      _isInitialized = false;
      _hasInitializationError = false;
    });

    final playSource = _buildPlaySource();

    if (playSource == null) {
      if (!_mountedSafe) return;
      setState(() {
        _isLoading = false;
        _hasInitializationError = true;
      });
      return;
    }

    final controller = PodPlayerController(
      playVideoFrom: playSource,
      podPlayerConfig: const PodPlayerConfig(
        autoPlay: false,
        isLooping: false,
        wakelockEnabled: true,
      ),
    );

    try {
      await controller.initialise();
      if (!_mountedSafe) {
        controller.dispose();
        return;
      }

      if (_savedPosition > Duration.zero) {
        await controller.videoSeekTo(_savedPosition);
      }

      _controller?.dispose();
      _controller = controller;

      _positionSaveTimer?.cancel();
      _positionSaveTimer = Timer.periodic(
        const Duration(seconds: 10),
        (timer) async => _saveCurrentPosition(),
      );

      if (!_mountedSafe) return;
      setState(() {
        _isLoading = false;
        _isInitialized = true;
      });

      log('Pod player initialized successfully for video: ${widget.url}');
    } catch (e) {
      controller.dispose();
      if (!_mountedSafe) return;
      log('Error initializing Pod player: $e');
      setState(() {
        _isLoading = false;
        _isInitialized = false;
        _hasInitializationError = true;
      });
    }
  }

  PlayVideoFrom? _buildPlaySource() {
    final type = widget.type.toLowerCase().trim();

    if (type == 'youtube' ||
        widget.url.contains('youtube.com') ||
        widget.url.contains('youtu.be')) {
      return PlayVideoFrom.youtube(widget.url);
    }

    if (type == 'network' ||
        type == 'mp4' ||
        type == 'video' ||
        widget.url.startsWith('http')) {
      return PlayVideoFrom.network(widget.url);
    }

    return PlayVideoFrom.network(widget.url);
  }

  void _setPortraitOrientation() {
    try {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } catch (e) {
      log('Error setting device orientation: $e');
    }
  }

  void _startWatermarkAnimation() {
    _watermarkTimer?.cancel();
    _watermarkTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_mountedSafe) return;
      setState(() {
        _watermarkAlignmentIndex =
            (_watermarkAlignmentIndex + 1) % _watermarkPositions.length;
        _watermarkAlignment = _watermarkPositions[_watermarkAlignmentIndex];
      });
    });
  }

  bool get _mountedSafe => mounted && !_disposed;

  @override
  void dispose() {
    _disposed = true;
    _positionSaveTimer?.cancel();
    _positionSaveTimer = null;
    _watermarkTimer?.cancel();
    _watermarkTimer = null;

    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

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
            child: _buildPlayerBody(context),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerBody(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState(context);
    }

    if (!_isInitialized || _controller == null || _hasInitializationError) {
      return _buildErrorState(context);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: Colors.black,
          child: PodVideoPlayer(
            controller: _controller!,
            podProgressBarConfig: const PodProgressBarConfig(
              padding: EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
        if (widget.name.isNotEmpty)
          AnimatedAlign(
            alignment: _watermarkAlignment,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              // decoration: BoxDecoration(
              //   color: Colors.black.withOpacity(0.6),
              //   borderRadius: BorderRadius.circular(12),
              // ),
              child: Text(
                widget.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
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
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
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
              'Error: Video may be private, restricted, or not available.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _initializeVideoPlayer(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
