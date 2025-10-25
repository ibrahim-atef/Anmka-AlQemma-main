import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:webinar/app/pages/introduction_page/intro_page.dart';
import 'package:webinar/app/pages/main_page/main_page.dart';
import 'package:webinar/app/pages/offline_page/internet_connection_page.dart';
import 'package:webinar/app/services/guest_service/guest_service.dart';
import 'package:webinar/common/common.dart';
import 'package:webinar/common/data/app_data.dart';
import 'package:webinar/common/utils/app_text.dart';
import 'package:webinar/config/assets.dart';
import 'package:webinar/config/styles.dart';

import '../../../config/colors.dart';

class SplashPage extends StatefulWidget {
  static const String pageName = '/splash';

  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> fadeAnimation;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeIn,
    );

    FlutterNativeSplash.remove();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      animationController.forward();

      Timer(const Duration(seconds: 2), () async {
        final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());

        if (connectivityResult.contains(ConnectivityResult.none)) {
          nextRoute(InternetConnectionPage.pageName, isClearBackRoutes: true);
        } else {
          String token = await AppData.getAccessToken();

          if (mounted) {
            if (token.isEmpty) {
              bool isFirst = await AppData.getIsFirst();

              if (isFirst) {
                nextRoute(IntroPage.pageName, isClearBackRoutes: true);
              } else {
                nextRoute(MainPage.pageName, isClearBackRoutes: true);
              }
            } else {
              nextRoute(MainPage.pageName, isClearBackRoutes: true);
            }
          }
        }
      });


    });

    GuestService.config();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F6C5F),
      body: Container(
        width: getSize().width,
        height: getSize().height,
        decoration:  BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          color: blueF2(),
          // image: DecorationImage(
          //   image: AssetImage(AppAssets.splashPng),
          //   fit: BoxFit.cover,
          // ),
        ),
        child:
        Center(
          child: Container(
            height: getSize().height / 2,
            width: getSize().width,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                space(30),
                Text(
                  appText.webinar,
                  style: style24Bold().copyWith(color: white()),
                ),
                space(10),
                Text(
                  appText.splashDesc,
                  style: style16Regular().copyWith(color: white()),
                ),
                space(10),
                FadeTransition(
                    opacity: fadeAnimation,
                    child: Container(
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage(AppAssets.splash_logo_png),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(50))
                      ),)
                        // child: Image.asset(AppAssets.splash_logo_png, height: 200,))
                ),
              ],
            ),
          ),
        ),

        // CustomScrollView(
        //   slivers: [
        //     Container(
        //       height: getSize().height / 3,
        //       width: getSize().width,
        //       decoration: const BoxDecoration(
        //         color: Colors.white,
        //         borderRadius: BorderRadius.only(
        //           topLeft: Radius.circular(20),
        //           topRight: Radius.circular(20),
        //         ),
        //       ),
        //       child: Column(
        //         children: [
        //           space(30),
        //           Text(
        //             appText.webinar,
        //             style: style24Bold(),
        //           ),
        //           space(10),
        //           Text(
        //             appText.splashDesc,
        //             style: style16Regular(),
        //           ),
        //           FadeTransition(
        //               opacity: fadeAnimation,
        //               child: SvgPicture.asset(AppAssets.splash_logo_svg, height: 200,)
        //           ),
        //         ],
        //       ),
        //     ),
        //     // SliverFillRemaining(
        //     //   hasScrollBody: false,
        //     //   child: SafeArea(
        //     //     child: Column(
        //     //       children: [
        //     //         // Expanded(
        //     //         //   child: Column(
        //     //         //     children: [
        //     //         //       space(20),
        //     //         //       Align(
        //     //         //         alignment: Alignment.topRight,
        //     //         //         child: Image.asset(
        //     //         //           AppAssets.penSplashScreenPng,
        //     //         //           height: 75,
        //     //         //         ),
        //     //         //       ),
        //     //         //       FadeTransition(
        //     //         //         opacity: fadeAnimation,
        //     //         //         child: Center(
        //     //         //           child: Image.asset(
        //     //         //             AppAssets.logoPng,
        //     //         //             height: getSize().height / 1.9,
        //     //         //           ),
        //     //         //         ),
        //     //         //       ),
        //     //         //     ],
        //     //         //   ),
        //     //         // ),
        //     //         Container(
        //     //           height: getSize().height / 3,
        //     //           width: getSize().width,
        //     //           decoration: const BoxDecoration(
        //     //             color: Colors.white,
        //     //             borderRadius: BorderRadius.only(
        //     //               topLeft: Radius.circular(20),
        //     //               topRight: Radius.circular(20),
        //     //             ),
        //     //           ),
        //     //           child: Column(
        //     //             children: [
        //     //               space(30),
        //     //               Text(
        //     //                 appText.webinar,
        //     //                 style: style24Bold(),
        //     //               ),
        //     //               space(10),
        //     //               Text(
        //     //                 appText.splashDesc,
        //     //                 style: style16Regular(),
        //     //               ),
        //     //               FadeTransition(
        //     //                 opacity: fadeAnimation,
        //     //                 child: SvgPicture.asset(AppAssets.splash_logo_svg, height: 200,)
        //     //               ),
        //     //             ],
        //     //           ),
        //     //         ),
        //     //       ],
        //     //     ),
        //     //   ),
        //     // )
        //   ],
        // ),


      ),
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }
}
