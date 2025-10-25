import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PDFViewerDownloadedOfflineScreen extends StatelessWidget {
  final String pdfPath;

  const PDFViewerDownloadedOfflineScreen({super.key, required this.pdfPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('عارض PDF')),
      body: PDFView(
        filePath: pdfPath,
      ),
    );
  }
}
