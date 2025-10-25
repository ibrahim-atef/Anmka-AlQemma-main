import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webinar/config/colors.dart';
import '../../../../../common/utils/constants.dart';
import '../../../../../common/utils/download_manager.dart';
import '../../../../widgets/main_widget/home_widget/single_course_widget/course_video_player.dart';
import 'pdf_downloaded_offline.dart';
import 'video_player_download_offline.dart';

class DownloadsPage extends StatefulWidget {
  static const String pageName = '/downloads';
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  List<FileSystemEntity> videoFiles = [];

  @override
  void initState() {
    super.initState();
    loadDownloads();
  }

Future<void> loadDownloads() async {
  String directory = (await getApplicationSupportDirectory()).path;

  List<String> videoExtensions = ['.mp4', '.avi', '.mkv'];
  List<String> pdfExtensions = ['.pdf'];

  List<FileSystemEntity> foundFiles = [];

  // جلب ملفات الفيديو
  for (String extension in videoExtensions) {
    foundFiles.addAll(Directory(directory).listSync().where((file) => file.path.endsWith(extension)));
  }

  // جلب ملفات PDF
  for (String extension in pdfExtensions) {
    foundFiles.addAll(Directory(directory).listSync().where((file) => file.path.endsWith(extension)));
  }

  setState(() {
    videoFiles = foundFiles;
  });

  print("📂 الملفات المحملة: ${videoFiles.length}");
}


  void deleteFile(FileSystemEntity file) async {
    try {
      await file.delete();
      setState(() {
        videoFiles.remove(file);
      });
      print("🗑️ تم حذف الملف: ${file.path}");
    } catch (e) {
      print("❌ خطأ أثناء حذف الملف: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("📂 الملفات المحملة"), backgroundColor: blueF2()),
      body: videoFiles.isEmpty
          ? const Center(child: Text("لا توجد ملفات محملة"))
          : ListView.builder(
        itemCount: videoFiles.length,
        itemBuilder: (context, index) {
          FileSystemEntity file = videoFiles[index];
          String fileName = file.path.split('/').last;

          return ListTile(
            leading: Icon(
              file.path.endsWith('.mp4') ? Icons.video_collection : Icons.picture_as_pdf,
              size: 30,
              color: Colors.blue,
            ),
            title: Text(fileName, style: const TextStyle(fontSize: 16)),
            onTap: () {
              if (file.path.endsWith('.mp4')) {
//                 Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (context) => CourseVideoPlayer(
//   file.path,
//   '', // image cover
//   Constants.singleCourseRouteObserver,
//   isLoadNetwork: false,
//   localFileName: file.path.split('/').last, // فقط الاسم وليس المسار الكامل
//   name: file.path.split('/').last,
// )
//   ),
// );


                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerDownloadOfflineScreen(videoPath: file.path),
                  ),
                );
              } else if (file.path.endsWith('.pdf')) {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => 
                //     // PDFViewerDownloadedOfflineScreen(pdfPath: file.path),
                //     CourseVideoPlayer(
                //             file.path, '', Constants.singleCourseRouteObserver,
                //             isLoadNetwork: false,
                //             localFileName: file.path, name: "name",
                //           ),
                //   ),
                // );
              } else {
                // التعامل مع أنواع الملفات الأخرى
              }
            },
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                deleteFile(file);
              },
            ),
          )
          ;
        },
      ),
    );
  }
}
