// clean_youtube_webview.dart
import 'package:flutter/material.dart';
import 'package:webinar/common/common.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..loadRequest(Uri.parse(_getCleanEmbedUrl(widget.videoUrl)))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            // تشغيل JavaScript لإزالة العناصر غير المرغوب فيها
            _removeYouTubeElements();
          },
          onNavigationRequest: (NavigationRequest request) {
            // منع جميع روابط المشاركة والتنقل الخارجي
            if (request.url.contains('share') ||
                request.url.contains('youtube.com/watch') ||
                request.url.contains('m.youtube.com') ||
                request.url.contains('youtube.com/channel') ||
                request.url.contains('youtube.com/user')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  String _getCleanEmbedUrl(String url) {
    final uri = Uri.parse(url);
    final videoId =
        uri.queryParameters['v'] ?? url.split('/').last.split('?').first;

    // إعدادات لإخفاء جميع عناصر المشاركة والتحكم
    return 'https://www.youtube.com/embed/$videoId?'
        'autoplay=1&' // تشغيل تلقائي
        'modestbranding=1&' // إخفاء شعار اليوتيوب
        'showinfo=0&' // إخفاء معلومات الفيديو
        'rel=0&' // إخفاء الفيديوهات المقترحة
        'controls=1&' // إظهار عناصر التحكم
        'disablekb=1&' // تعطيل التحكم بالكيبورد
        'fs=0&' // تعطيل وضع الشاشة الكاملة
        'playsinline=1&' // التشغيل داخل التطبيق
        'enablejsapi=1&' // تمكين JavaScript API
        'widget_referrer=1&' // إخفاء المعلومات المرجعية
        'iv_load_policy=3'; // إخفاء التعليقات التوضيحية
  }

  void _removeYouTubeElements() {
    // JavaScript لإزالة جميع عناصر الشير والشعار
    const jsCode = """
      // إزالة زر المشاركة
      function removeShareButton() {
        var shareButtons = document.querySelectorAll('button[aria-label*="share"], button[aria-label*="Share"], .ytp-share-button, .ytp-share-button-visible');
        shareButtons.forEach(function(btn) {
          btn.style.display = 'none';
          btn.remove();
        });
      }
      
      // إزالة شعار اليوتيوب
      function removeYouTubeLogo() {
        var logos = document.querySelectorAll('.ytp-watermark, .ytp-title-channel-logo, .ytp-chrome-top-buttons');
        logos.forEach(function(logo) {
          logo.style.display = 'none';
          logo.remove();
        });
      }
      
      // إزالة قائمة النقاط الثلاث
      function removeMoreButton() {
        var moreButtons = document.querySelectorAll('button[aria-label*="More"], .ytp-button[aria-haspopup], .ytp-settings-button, .ytp-popup');
        moreButtons.forEach(function(btn) {
          btn.style.display = 'none';
          btn.remove();
        });
      }
      
      // إزالة عنوان القناة
      function removeChannelTitle() {
        var titles = document.querySelectorAll('.ytp-title-channel, .ytp-title-text, .ytp-title-link');
        titles.forEach(function(title) {
          title.style.display = 'none';
          title.remove();
        });
      }
      
      // إزالة الإعلانات
      function removeAds() {
        var ads = document.querySelectorAll('.ytp-ad-module, .ytp-ad-overlay-container, .ad-container, .video-ads');
        ads.forEach(function(ad) {
          ad.style.display = 'none';
          ad.remove();
        });
      }
      
      // منع فتح نافذة المشاركة
      document.addEventListener('click', function(e) {
        if (e.target.closest('button[aria-label*="share"]') || 
            e.target.closest('button[aria-label*="Share"]') ||
            e.target.closest('.ytp-share-button')) {
          e.preventDefault();
          e.stopPropagation();
          return false;
        }
      });
      
      // تنفيذ الإزالة بشكل متكرر
      function removeAllUnwantedElements() {
        removeShareButton();
        removeYouTubeLogo();
        removeMoreButton();
        removeChannelTitle();
        removeAds();
      }
      
      // تشغيل الإزالة كل 500 مللي ثانية
      setInterval(removeAllUnwantedElements, 500);
      
      // التشغيل الأولي
      removeAllUnwantedElements();
    """;

    _controller.runJavaScript(jsCode);
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
              top: 55,
              right: 5,
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
                right: 0,
                child: Container(
                  color: Colors.black,
                  width: MediaQuery.of(context).size.width,
                  height: 50,
                )),
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
}
