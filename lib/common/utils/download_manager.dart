import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webinar/common/common.dart';
import 'package:webinar/common/components.dart';
import 'package:webinar/common/enums/error_enum.dart';
import 'package:webinar/locator.dart';

import '../data/app_data.dart';
import '../data/app_language.dart';
import 'constants.dart';

class DownloadManager{

  static List<FileSystemEntity> files = [];


  static Future<void> download(String url,Function(int progress) onDownlaod,{CancelToken? cancelToken,String? name,Function? onLoadAtLocal, bool isOpen=true}) async {

    PermissionStatus res = await Permission.storage.request();
    PermissionStatus res2 = await Permission.photos.request();

    if(res.isGranted || res2.isGranted){
      String directory = (await getApplicationSupportDirectory()).path;


      if(! (await findFile(directory, name ?? url.split('/').last, onLoadAtLocal: onLoadAtLocal )) ){

        String token = await AppData.getAccessToken();

        Map<String, String> headers = {
          "Authorization": "Bearer $token",
          "Accept" : "application/json",
          'x-api-key' : Constants.apiKey,
          'x-locale' : locator<AppLanguage>().currentLanguage.toLowerCase(),
        };

        try{
          await locator<Dio>().download(
            url,
            '$directory/${ name ?? url.split('/').last}',
            onReceiveProgress: (count, total) {
              onDownlaod((count / total * 100).toInt());
            },
            cancelToken: cancelToken,
            options: Options(
              followRedirects: true,
              headers: headers
            )

          ).then((value) {

            if(value.statusCode == 200){
              if(navigatorKey.currentContext!.mounted){
                backRoute(arguments: '$directory/${ name ?? url.split('/').last}');
              }

              if(isOpen){
                showSnackBar(ErrorEnum.success, "Video download");
                // OpenFile.open('$directory/${ name ?? url.split('/').last}');
              }
            }

          });
        }on DioException catch (e) {
          showSnackBar(ErrorEnum.error, e.message);
        }


      }
    }


  }

  static Future<bool> findFile(String directory, String name,{Function? onLoadAtLocal, bool isOpen=true}) async {
    bool state=false;

    files = Directory(directory).listSync().toList();

    for (var i = 0; i < files.length; i++) {
      if(files[i].path.contains(name)){

        if(onLoadAtLocal != null){
          onLoadAtLocal();
        }

        if(isOpen){
          showSnackBar(ErrorEnum.success, "Video downloaded");
          // OpenFile.open(files[i].path);
        }
        return true;
      }
    }

    return state;
  }

  /// 📌 **دالة مخصصة لتنزيل وفتح ملفات PDF فقط (مستقلة بالكامل)**
  static Future<void> downloadPdf(
      {required String url,
        required Function(int progress) onDownload,
        CancelToken? cancelToken,
        String? name,
        Function? onLoadAtLocal}) async {

    // طلب إذن التخزين
    PermissionStatus res = await Permission.storage.request();
    if (!res.isGranted) {
      print("❌ الإذن مرفوض: لا يمكن تنزيل PDF بدون إذن التخزين.");
      return;
    }

    String directory = (await getApplicationSupportDirectory()).path;
    String fileName = name ?? url.split('/').last;
    String fullPath = '$directory/$fileName';

    // البحث عن الملف قبل التنزيل
    bool fileExists = await findFile(directory, fileName, onLoadAtLocal: () {
      print("📁 PDF موجود بالفعل، فتحه مباشرة...");
      OpenFile.open(fullPath);
    });

    if (!fileExists) {
      print("⬇️ جاري تنزيل PDF: $fileName...");
      String token = await AppData.getAccessToken();

      Map<String, String> headers = {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        'x-api-key': Constants.apiKey,
        'x-locale': locator<AppLanguage>().currentLanguage.toLowerCase(),
      };

      try {
        Dio dio = Dio();
        await dio.download(
          url,
          fullPath,
          onReceiveProgress: (count, total) {
            onDownload((count / total * 100).toInt());
          },
          cancelToken: cancelToken,
          options: Options(
            followRedirects: true,
            headers: headers,
          ),
        ).then((value) {
          if (value.statusCode == 200) {
            print("✅ تم تنزيل PDF بنجاح: $fullPath");
            showSnackBar(ErrorEnum.success, "تم تحميل PDF بنجاح");
            OpenFile.open(fullPath);
          }
        });
      } on DioException catch (e) {
        print("❌ خطأ أثناء تنزيل PDF: ${e.message}");
        showSnackBar(ErrorEnum.error, "فشل تحميل PDF: ${e.message}");
      }
    }
  }


  static Future<String?> findPdf(String fileName) async {
    try {
      // الحصول على مسار التخزين الداخلي للتطبيق
      String directory = (await getApplicationSupportDirectory()).path;

      // قائمة الملفات في هذا المجلد
      List<FileSystemEntity> files = Directory(directory).listSync();

      // البحث عن الملف المطلوب
      for (var file in files) {
        if (file.path.endsWith('.pdf') && file.path.contains(fileName)) {
          print("✅ ملف PDF موجود: ${file.path}");
          return file.path;
        }
      }

      print("🚫 ملف PDF غير موجود.");
      return null;
    } catch (e) {
      print("❌ خطأ أثناء البحث عن ملف PDF: $e");
      return null;
    }
  }

}