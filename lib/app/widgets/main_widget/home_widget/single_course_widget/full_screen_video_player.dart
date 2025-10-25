import 'dart:async';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:webinar/common/common.dart';

class FullScreenVideoPlayer extends StatefulWidget {
  final String name;
  final VideoPlayerController videoPlayerController;

  const FullScreenVideoPlayer(this.videoPlayerController,
      {super.key, required this.name});

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late ChewieController chewieController;

  // متغيرات لتحديد مكان النص
  double _watermarkPositionX = 0.0;
  double _watermarkPositionY = 0.0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    // إعداد ChewieController
    chewieController = ChewieController(
      videoPlayerController: widget.videoPlayerController,


      // overlay: Align(
      //   alignment: Alignment.center,
      //   child: Text(widget.name,style: TextStyle(
      //     fontSize: 50,  // زيادة حجم الخط
      //     color: Colors.white.withOpacity(0.1),  // تقليل الشفافية لجعل النص أكثر وضوحاً
      //     fontWeight: FontWeight.bold,
      //     backgroundColor: Colors.black.withOpacity(0.1), // خلفية مظللة لتوضيح النص
      //   ),),
      // ),
    );

    // إعداد الـ Timer لتحريك النص
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      setState(() {
        if (_watermarkPositionX == 0.0 && _watermarkPositionY == 0.0) {
          // تحريك النص نحو المنتصف
          _watermarkPositionX = 0.5; // المنتصف أفقياً
          _watermarkPositionY = 0.5; // المنتصف رأسياً
        } else {
          // العودة إلى الزاوية العلوية اليسرى
          _watermarkPositionX = 0.0;
          _watermarkPositionY = 0.0;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // إيقاف الـ Timer عند التخلص من الشاشة
    chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: true,
        top: true,
        child: Stack(
          children: [
            // عرض الفيديو باستخدام Chewie
            Chewie(
              controller: chewieController,
            ),
            AnimatedPositioned(
              duration: Duration(seconds: 1),
              // مدة الحركة
              // الحساب لتحديد مكان العلامة المائية أفقيًا ورأسيًا في وسط الفيديو
              right: _watermarkPositionX == 0.0
                  ? 20 // الزاوية العلوية اليسرى
                  : (MediaQuery.of(context).size.width / 2) - 100,
              // المنتصف أفقياً (للسهولة، قمنا بطرح 100 لأن عرض النص سيكون 200 تقريبًا)
              top: _watermarkPositionY ==
                      (MediaQuery.of(context).size.height / 2)
                  ? 20 // الزاوية العلوية اليسرى
                  : (MediaQuery.of(context).size.height / 2) - 50,
              // المنتصف رأسياً (حيث أن ارتفاع الشاشة هو 250، نقوم بتحديد المنتصف عن طريق الحساب)
              child: Container(
                padding: EdgeInsets.all(8),
                color: Colors.transparent,
                child: Text(
                  widget.name,
                  style: TextStyle(
                    fontSize: 10, // حجم الخط
                    color: Colors.black.withOpacity(0.5), // شفافية النص
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // أزرار التقديم والتأخير
            Positioned(
              bottom: 50,
              left: 20,
              right: 20,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // زر التأخير
                    GestureDetector(
                      onTap: () {
                        final currentPosition =
                            widget.videoPlayerController.value.position;
                        final rewindPosition =
                            currentPosition - Duration(seconds: 10);
                        widget.videoPlayerController.seekTo(
                          rewindPosition > Duration.zero
                              ? rewindPosition
                              : Duration.zero,
                        );
                      },
                      child: Container(
                        width: 25,
                        height: 25,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // color: Colors.black.withOpacity(0.5),
                        ),
                        child: Icon(
                          Icons.replay_10,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    // زر التقديم
                    GestureDetector(
                      onTap: () {
                        final currentPosition =
                            widget.videoPlayerController.value.position;
                        final maxDuration =
                            widget.videoPlayerController.value.duration;
                        final forwardPosition =
                            currentPosition + Duration(seconds: 10);
                        widget.videoPlayerController.seekTo(
                          forwardPosition < maxDuration
                              ? forwardPosition
                              : maxDuration,
                        );
                      },
                      child: Container(
                        width: 25,
                        height: 25,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // color: Colors.black.withOpacity(0.5),
                        ),
                        child: Icon(
                          Icons.forward_10,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ]),
            ),
          ],
        ),
      ),
    );
  }
}
