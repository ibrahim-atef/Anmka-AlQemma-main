import 'package:flutter/material.dart';
import 'package:webinar/app/widgets/main_widget/home_widget/single_course_widget/course_video_player.dart';
import 'package:webinar/common/utils/constants.dart';
import 'package:webinar/config/colors.dart';

class VideoPlayerDownloadOfflineScreen extends StatelessWidget {
  final String videoPath;

  const VideoPlayerDownloadOfflineScreen({Key? key, required this.videoPath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fileName = videoPath.split('/').last;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: blueF2(),
        elevation: 0,
        title: Text(
          fileName,
          style: TextStyle(fontSize: 16),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Text(
              //   'تشغيل الفيديو',
              //   style: TextStyle(
              //     fontSize: 18,
              //     fontWeight: FontWeight.bold,
              //     color: mainColor(),
              //   ),
              // ),
              SizedBox(height: 16),
              Expanded(
                child: CourseVideoPlayer(
                  videoPath,
                  '', // صورة الغلاف
                  Constants.singleCourseRouteObserver,
                  isLoadNetwork: false,
                  localFileName: fileName,
                  name: fileName,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
