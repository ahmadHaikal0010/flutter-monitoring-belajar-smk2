import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../core/utils/snack_bar_helper.dart';
import '../../data/models/material_model.dart';
import '../../logic/providers/auth_provider.dart';
import '../../logic/providers/enrollment_provider.dart';
import 'pdf_viewer_screen.dart';
import 'web_view_screen.dart';
import 'package:intl/intl.dart';

class MaterialDetailScreen extends StatefulWidget {
  final MaterialModel material;

  const MaterialDetailScreen({super.key, required this.material});

  @override
  State<MaterialDetailScreen> createState() => _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends State<MaterialDetailScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isDownloading = false;
  bool _isMarkingAsComplete = false;

  @override
  void initState() {
    super.initState();
    if (widget.material.contentType == 'video') {
      _initVideoPlayer();
    }
  }

  void _initVideoPlayer() async {
    String url = widget.material.contentBodyUrl ?? widget.material.contentBody;
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
    
    await _videoPlayerController!.initialize();
    
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: false,
      looping: false,
      aspectRatio: _videoPlayerController!.value.aspectRatio,
      placeholder: const Center(child: CircularProgressIndicator()),
    );
    
    setState(() {});

    _videoPlayerController!.addListener(() {
      if (_videoPlayerController!.value.position == _videoPlayerController!.value.duration) {
        _markAsCompleted(); // OTOMATIS: Lapor selesai saat video tamat
      }
    });
  }

  Future<void> _markAsCompleted() async {
    if (_isMarkingAsComplete) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final enrollmentProvider = Provider.of<EnrollmentProvider>(context, listen: false);
    
    if (authProvider.token == null) return;

    // Cek apakah sudah pernah selesai sebelumnya
    final currentProgress = enrollmentProvider.getProgress(widget.material.subjectId);
    if (currentProgress?.isMaterialCompleted(widget.material.id) ?? false) return;

    setState(() => _isMarkingAsComplete = true);

    final success = await enrollmentProvider.markAsCompleted(
      authProvider.token!,
      widget.material.subjectId,
      widget.material.id,
    );

    if (mounted) {
      setState(() => _isMarkingAsComplete = false);
      if (success) {
        SnackBarHelper.show(
          context: context,
          message: 'Selamat! Kamu telah menyelesaikan materi ini.',
        );
      }
    }
  }

  Future<void> _openPdf() async {
    setState(() => _isDownloading = true);
    
    try {
      String url = widget.material.contentBodyUrl ?? widget.material.contentBody;
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/temp_${widget.material.id}.pdf');

      await Dio().download(url, file.path);

      if (mounted) {
        setState(() => _isDownloading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(
              path: file.path,
              title: widget.material.title,
              subjectId: widget.material.subjectId,
              materialId: widget.material.id,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        SnackBarHelper.show(
          context: context,
          message: 'Gagal membuka file PDF',
          isError: true,
        );
      }
    }
  }

  void _openWebView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewScreen(
          url: widget.material.contentBody,
          title: widget.material.title,
        ),
      ),
    ).then((_) {
      _markAsCompleted(); // Tandai selesai setelah membuka tautan
    });
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Detail Materi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: Consumer<EnrollmentProvider>(
        builder: (context, enrollmentProvider, child) {
          final isDone = enrollmentProvider.getProgress(widget.material.subjectId)?.isMaterialCompleted(widget.material.id) ?? false;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.material.subjectTitle,
                        style: const TextStyle(color: Color(0xFF2563EB), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (isDone)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 14),
                            SizedBox(width: 4),
                            Text('SELESAI', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Text(
                  widget.material.title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd MMMM yyyy').format(widget.material.createdAt),
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
                const Divider(height: 48),

                _buildNativeContent(),
                
                const SizedBox(height: 32),
                
                if (widget.material.description != null && widget.material.description!.isNotEmpty) ...[
                  const Text(
                    'Deskripsi Materi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.material.description!,
                    style: const TextStyle(fontSize: 15, color: Color(0xFF475569), height: 1.6),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNativeContent() {
    switch (widget.material.contentType) {
      case 'video':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pemutar Video', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Chewie(controller: _chewieController!),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ],
        );

      case 'document':
        return _buildActionCard(
          icon: Icons.picture_as_pdf_rounded,
          title: 'Dokumen Materi',
          subtitle: 'Tekan tombol di bawah untuk membaca materi.',
          buttonText: _isDownloading ? 'Menyiapkan File...' : 'Baca Materi Sekarang',
          color: Colors.blue,
          onTap: _isDownloading ? null : _openPdf,
          isLoading: _isDownloading,
        );

      case 'url':
        return _buildActionCard(
          icon: Icons.language_rounded,
          title: 'Tautan Referensi',
          subtitle: 'Materi ini akan dibuka di dalam aplikasi.',
          buttonText: 'Buka Halaman Web',
          color: Colors.teal,
          onTap: _openWebView,
        );

      default:
        return const Center(child: Text('Format konten tidak didukung.'));
    }
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required Color color,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 64, color: color),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.chrome_reader_mode_outlined),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
