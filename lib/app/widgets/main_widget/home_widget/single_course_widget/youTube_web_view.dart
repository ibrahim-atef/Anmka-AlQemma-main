// clean_youtube_webview.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:auto_orientation/auto_orientation.dart';
import 'package:flutter/services.dart';

class YouTubeWebView extends StatefulWidget {
  final String videoUrl;

  const YouTubeWebView({super.key, required this.videoUrl});

  @override
  State<YouTubeWebView> createState() => _YouTubeWebViewState();
}

class _YouTubeWebViewState extends State<YouTubeWebView> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    AutoOrientation.landscapeAutoMode(forceSensor: true);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _removeYouTubeElements();
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            if (url.startsWith('about:blank') || url.startsWith('data:')) {
              return NavigationDecision.navigate;
            }
            if (url.contains('share') ||
                url.contains('redirect') ||
                url.startsWith('intent:') ||
                url.startsWith('vnd.youtube') ||
                url.contains('m.youtube.com') ||
                url.contains('youtube.com/watch') ||
                url.contains('youtube.com/shorts') ||
                url.contains('youtube.com/channel') ||
                url.contains('youtube.com/user') ||
                url.contains('youtu.be/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            print('Error loading video: ${error.description}');
          },
        ),
      )
      ..loadHtmlString(_buildHtmlPlayer(widget.videoUrl));
  }

  String _extractVideoId(String url) {
    final uri = Uri.parse(url);
    String videoId = '';

    if (uri.host.contains('youtu.be')) {
      videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
    } else if (uri.queryParameters.containsKey('v')) {
      videoId = uri.queryParameters['v']!;
    } else if (uri.pathSegments.contains('embed')) {
      videoId = uri.pathSegments.last;
    } else {
      final parts = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      videoId = parts.split('?').first;
    }

    // تنظيف أي معاملات إضافية
    videoId = videoId.split('&').first.split('?').first;

    return videoId;
  }

  String _buildHtmlPlayer(String url) {
    final videoId = _extractVideoId(url);

    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            body {
                background-color: #000;
                overflow: hidden;
            }
            #player-container {
                position: fixed;
                top: 0;
                left: 0;
                width: 100vw;
                height: 100vh;
            }
            #player {
                width: 100%;
                height: 100%;
                border: none;
            }
            /* أقنعة لإخفاء أزرار CC والإعدادات والشير */
            .controls-mask-right {
                position: absolute;
                right: 0;
                bottom: 0;
                width: 220px; /* يغطي CC وSettings وأي أزرار مجاورة */
                height: 90px; /* يزيد الارتفاع لتغيّر موضع الشريط */
                background: rgba(0,0,0,0.95);
                z-index: 9999;
                pointer-events: auto; /* منع الضغط على الأزرار المخفية */
            }
            .controls-mask-top-right {
                position: absolute;
                right: 0;
                top: 0;
                width: 220px; /* يغطي زر الشير أو قوائم أعلى يمين */
                height: 80px;
                background: rgba(0,0,0,0.95);
                z-index: 9999;
                pointer-events: auto;
            }
            /* إخفاء عناصر يوتيوب */
            .ytp-settings-button,
            .ytp-subtitles-button,
            .ytp-fullscreen-button,
            .ytp-share-button,
            .ytp-watermark,
            .ytp-title-channel-logo,
            .ytp-title-channel,
            .ytp-title-text,
            .ytp-cards-teaser,
            .ytp-ce-element {
                display: none !important;
            }
        </style>
    </head>
    <body>
        <div id="player-container">
            <div id="player"></div>
        </div>
        
        <script>
            // منع الضغط الطويل وقائمة السياق
            document.addEventListener('contextmenu', e => e.preventDefault());
            
            // منع الخروج من التطبيق عند النقر على روابط يوتيوب (أفضل ما يمكن من الجانب الخارجي)
            (function(){
              const blockNav = (e) => {
                try {
                  const t = e.target;
                  if (t && t.closest && t.closest('a')) {
                    e.preventDefault();
                    e.stopPropagation();
                  }
                } catch(_) {}
              };
              document.addEventListener('click', blockNav, true);
              document.addEventListener('auxclick', blockNav, true);
            })();

            // تحميل YouTube Iframe API وإنشاء المشغّل بدون أي عناصر تحكم
            var tag = document.createElement('script');
            tag.src = "https://www.youtube.com/iframe_api";
            var firstScriptTag = document.getElementsByTagName('script')[0];
            firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

            var player;
            window.onYouTubeIframeAPIReady = function() {
              player = new YT.Player('player', {
                videoId: '$videoId',
                playerVars: {
                  autoplay: 1,
                  controls: 0,      // إخفاء كل عناصر التحكم (لا CC ولا إعدادات)
                  fs: 0,
                  rel: 0,
                  modestbranding: 1,
                  iv_load_policy: 3,
                  playsinline: 1,
                  disablekb: 1,
                  cc_load_policy: 0
                },
                events: {
                  'onReady': function(e) {
                    try { e.target.playVideo(); } catch(_) {}
                  }
                }
              });
            };

            // دوال يُمكن استدعاؤها من Flutter
            window.playerSeekBy = function(seconds){
              try {
                if (!player) return;
                var cur = player.getCurrentTime ? player.getCurrentTime() : 0;
                var target = cur + Number(seconds || 0);
                if (target < 0) target = 0;
                player.seekTo(target, true);
              } catch(_) {}
            };

            window.playerTogglePlay = function(){
              try {
                if (!player) return;
                var state = player.getPlayerState ? player.getPlayerState() : -1;
                if (state === 1) { player.pauseVideo(); } else { player.playVideo(); }
              } catch(_) {}
            };
        </script>
    </body>
    </html>
    ''';
  }

  void _removeYouTubeElements() {
    const jsCode = """
      setTimeout(function(){
        try {
          var style = document.createElement('style');
          style.textContent = `
            .ytp-settings-button,
            .ytp-subtitles-button,
            .ytp-fullscreen-button,
            .ytp-share-button,
            .ytp-watermark,
            .ytp-chrome-top-buttons,
            .ytp-title-channel,
            .ytp-cards-teaser {
              display: none !important;
              visibility: hidden !important;
            }
          `;
          document.head.appendChild(style);
        } catch(e) {
          console.log('Error hiding elements:', e);
        }
      }, 1500);
    """;
    _controller.runJavaScript(jsCode);
  }

  void _seekBy(int seconds) {
    final js = """
      try { window.playerSeekBy($seconds); } catch(e) { console.log('Seek error', e); }
    """;
    _controller.runJavaScript(js);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            Positioned(
              bottom: 20,
              left: 10,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.black,
                ),
              ),
            ),
            Positioned(
              top: 15,
              right: 10,
              child: IconButton(
                icon: const Icon(
                  Icons.keyboard_arrow_right,
                  color: Colors.white,
                  size: 40,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              top: 70,
              right: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Material(
                      color: Colors.black.withOpacity(0.35),
                      child: InkWell(
                        onTap: () => _seekBy(-10),
                        child: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Icon(
                            Icons.replay_10,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Material(
                      color: Colors.black.withOpacity(0.35),
                      child: InkWell(
                        onTap: () => _seekBy(10),
                        child: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Icon(
                            Icons.forward_10,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    AutoOrientation.portraitAutoMode(forceSensor: true);
    super.dispose();
  }
}
