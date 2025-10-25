// import 'package:flutter/services.dart';
// import 'package:modern_player/modern_player.dart';
// // import 'package:pod_player/pod_player.dart';
// import 'package:flutter/material.dart';
// import 'package:webinar/common/common.dart';
//
// import '../../../../../test.dart';
//
// class PodVideoPlayerDev extends StatefulWidget {
//   final String type;
//   final String url;
//   final String name;
//   final RouteObserver<ModalRoute<void>> routeObserver;
//
//   const PodVideoPlayerDev(this.url,this.type, this.routeObserver, {super.key, required this.name});
//
//   @override
//   State<PodVideoPlayerDev> createState() => _VimeoVideoPlayerState();
// }
//
// class _VimeoVideoPlayerState extends State<PodVideoPlayerDev> with RouteAware {
//   // late final PodPlayerController controller;
//
//   @override
//   void initState() {
//
//     // if(widget.type == 'vimeo'){
//     //   controller = PodPlayerController(
//     //     playVideoFrom: PlayVideoFrom.vimeo(
//     //       widget.url,
//     //       videoPlayerOptions: VideoPlayerOptions(
//     //         allowBackgroundPlayback: true,
//     //       ),
//     //     ),
//     //     podPlayerConfig: const PodPlayerConfig(
//     //       autoPlay: true,
//     //       isLooping: false,
//     //       wakelockEnabled: true,
//     //       videoQualityPriority: [720, 360],
//     //     ),
//     //   );
//     //
//     //   controller.initialise();
//     //
//     // }else{
//     //   // widget.type == 'vimeo'
//     //   //     ? PlayVideoFrom.vimeo(widget.url.split('/').last)
//     //   //     :
//     //   controller = PodPlayerController(
//     //     playVideoFrom: widget.type == 'youtube'
//     //         ? PlayVideoFrom.youtube(widget.url)
//     //         : PlayVideoFrom.network(widget.url),
//     //
//     //   )..initialise().then((value){
//     //     setState(() {});
//     //   },onError: (e){});
//     // }
//
//
//     super.initState();
//   }
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     widget.routeObserver.subscribe(this, ModalRoute.of(context)!);
//   }
//
//
//   // @override
//   // void dispose() {
//   //   widget.routeObserver.unsubscribe(this);
//   //   controller.dispose();
//   //   super.dispose();
//   // }
//
//   // @override
//   // void didPush() {}
//   //
//   // @override
//   // void didPushNext() {
//   //   // final route = ModalRoute.of(context)?.settings.name;
//   //   controller.pause();
//   // }
//   //
//   // @override
//   // void didPopNext() {
//   //   controller.play();
//   // }
//
//
//   // متغير لحالة ملء الشاشة
//   bool _isFullScreen = false;
//
//   // Theme option for modern_player
//   var themeOptions = ModernPlayerThemeOptions(
//     backgroundColor: Colors.black,
//     menuBackgroundColor: Colors.black,
//     loadingColor: Colors.blue,
//     menuIcon: const Icon(
//       Icons.settings,
//       color: Colors.white,
//     ),
//     volumeSlidertheme: ModernPlayerToastSliderThemeOption(
//         sliderColor: Colors.blue,
//         iconColor: Colors.white
//     ),
//     progressSliderTheme: ModernPlayerProgressSliderTheme(
//       activeSliderColor: Colors.blue,
//       inactiveSliderColor: Colors.white70,
//       bufferSliderColor: Colors.black54,
//       thumbColor: Colors.white,
//       progressTextStyle: const TextStyle(
//           fontWeight: FontWeight.w400, color: Colors.white, fontSize: 18
//       ),
//     ),
//   );
//
//   // Controls option for modern_player
//   var controlsOptions = ModernPlayerControlsOptions(
//     showControls: true,
//     doubleTapToSeek: true,
//     showMenu: true,
//     showMute: false,
//     showBackbutton: false,
//     enableVolumeSlider: true,
//     enableBrightnessSlider: true,
//     showBottomBar: true,
//     customActionButtons: [
//       // يمكنك إضافة أزرار مخصصة هنا إذا رغبت
//     ],
//   );
//
//   // دالة لتبديل الوضع بين ملء الشاشة والوضع الطبيعي
//   void _toggleFullScreen() {
//     setState(() {
//       _isFullScreen = !_isFullScreen;
//     });
//
//     if (_isFullScreen) {
//       // الانتقال إلى الوضع الأفقي (ملء الشاشة)
//       SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
//       SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);  // إخفاء الواجهة بالكامل (شريط الحالة والأزرار)
//     } else {
//       // العودة إلى الوضع الرأسي
//       SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//       SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);  // عرض الواجهة بالكامل
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 16),
//       child: ClipRRect(
//         borderRadius: borderRadius(),
//         child: SizedBox(
//           height: _isFullScreen ? MediaQuery.of(context).size.height : 400,  // استخدام الارتفاع الكامل في وضع ملء الشاشة
//           width: _isFullScreen ? MediaQuery.of(context).size.width : getSize().width,  // استخدام العرض الكامل في وضع ملء الشاشة
//           child: Row(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(10),
//                 child: Align(
//                   alignment: Alignment.centerRight,
//                   child: IconButton(
//                     icon: Icon(
//                       _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
//                       color: Colors.black,
//                     ),
//                     onPressed: _toggleFullScreen,
//                   ),
//                 ),
//               ),
//               Flexible(
//                 child: Stack(
//                   children: [
//                     SizedBox(
//                       height: _isFullScreen ? MediaQuery.of(context).size.height : 250,  // تعديل الارتفاع حسب الحالة
//                       width: _isFullScreen ? MediaQuery.of(context).size.width : getSize().width,  // تعديل العرض حسب الحالة
//                       child: ModernPlayer.createPlayer(
//                         controlsOptions: controlsOptions,
//                         defaultSelectionOptions: ModernPlayerDefaultSelectionOptions(
//                             defaultQualitySelectors: [DefaultSelectorLabel('360p')]
//                         ),
//                         // استخدام الرابط الممرر في الـ Constructor
//                         video: ModernPlayerVideo.youtubeWithUrl(
//                           url: widget.url, // هنا يتم استخدام الرابط الممرر
//                           fetchQualities: true,
//                         ),
//                       ),
//                     ),
//                     // إضافة العلامة المائية
//                     Positioned(
//                       top: 10,
//                       left: 10,
//                       child: Container(
//                         padding: EdgeInsets.all(8),
//                         color: Colors.transparent,
//                         child: Text(
//                           widget.name,
//                           style: TextStyle(
//                             fontSize: 20,
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
// }