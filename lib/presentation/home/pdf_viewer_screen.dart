import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:provider/provider.dart';
import '../../core/utils/snack_bar_helper.dart';
import '../../logic/providers/auth_provider.dart';
import '../../logic/providers/enrollment_provider.dart';

class PdfViewerScreen extends StatefulWidget {
  final String path;
  final String title;
  final String subjectId;
  final String materialId;

  const PdfViewerScreen({
    super.key,
    required this.path,
    required this.title,
    required this.subjectId,
    required this.materialId,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  bool _isMarkingComplete = false;

  Future<void> _markAsRead() async {
    if (_isMarkingComplete) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final enrollmentProvider = Provider.of<EnrollmentProvider>(context, listen: false);

    if (token == null) return;

    // Cek apakah sudah pernah selesai sebelumnya
    final currentProgress = enrollmentProvider.getProgress(widget.subjectId);
    if (currentProgress?.isMaterialCompleted(widget.materialId) ?? false) return;

    setState(() => _isMarkingComplete = true);

    final success = await enrollmentProvider.markAsCompleted(
      token,
      widget.subjectId,
      widget.materialId,
    );

    if (mounted) {
      setState(() => _isMarkingComplete = false);
      if (success) {
        SnackBarHelper.show(
          context: context,
          message: 'Bagus! Kamu telah membaca materi ini hingga selesai.',
        );
      }
    }
  }

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
              
              // Jika page == total-1, siswa sudah mencapai halaman terakhir
              if (page == total! - 1) {
                _markAsRead();
              }
            },
          ),
          if (!_isReady) const Center(child: CircularProgressIndicator()),
          if (_isMarkingComplete)
            const Positioned(
              top: 10,
              right: 10,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}
