import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfViewerScreen extends StatefulWidget {
  final String path;
  final String title;

  const PdfViewerScreen({super.key, required this.path, required this.title});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                '${_currentPage + 1} / $_totalPages',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.path,
            autoSpacing: true,
            pageSnap: true,
            pageFling: true,
            swipeHorizontal: false,
            onRender: (pages) {
              setState(() {
                _totalPages = pages!;
                _isReady = true;
              });
            },
            onPageChanged: (page, total) {
              setState(() {
                _currentPage = page!;
              });
              
              // LOGIC TRACKING: Jika page == total-1, tandai sebagai SELESAI
              if (page == total! - 1) {
                print('TRACKING: Siswa telah membaca hingga halaman terakhir.');
              }
            },
          ),
          if (!_isReady) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
