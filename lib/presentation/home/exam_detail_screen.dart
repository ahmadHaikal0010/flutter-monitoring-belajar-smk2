import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/exam_model.dart';
import '../../logic/providers/auth_provider.dart';
import '../../logic/providers/exam_provider.dart';
import '../../core/utils/snack_bar_helper.dart';
import '../../core/utils/date_helper.dart';
import 'exam_pengerjaan_screen.dart';
import 'exam_result_screen.dart';

class ExamDetailScreen extends StatefulWidget {
  final ExamModel exam;

  const ExamDetailScreen({super.key, required this.exam});

  @override
  State<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends State<ExamDetailScreen> {
  bool _isStarting = false;

  Future<void> _handleStartExam() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mulai Ujian?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Anda akan memulai "${widget.exam.title}". Sisa waktu pengerjaan akan langsung berjalan secara otomatis.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Mulai Ujian', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _isStarting = true;
    });

    final success = await context.read<ExamProvider>().startExam(token, widget.exam.id);

    if (mounted) {
      setState(() {
        _isStarting = false;
      });

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ExamPengerjaanScreen()),
        );
      } else {
        final err = context.read<ExamProvider>().errorMessage;
        SnackBarHelper.show(context: context, message: err ?? 'Gagal memulai ujian.', isError: true);
      }
    }
  }

  Future<void> _handleResumeExam() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() {
      _isStarting = true;
    });

    final success = await context.read<ExamProvider>().startExam(token, widget.exam.id);

    if (mounted) {
      setState(() {
        _isStarting = false;
      });

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ExamPengerjaanScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exam = widget.exam;
    final session = exam.studentSession;
    final isSubmitted = session?.status == 'submitted' || session?.status == 'graded';
    final isInProgress = session?.status == 'in_progress';

    final now = DateTime.now();
    final startTime = exam.startTime;
    final endTime = exam.endTime;

    final isNotStartedYet = startTime != null && now.isBefore(startTime);
    final isAlreadyEnded = endTime != null && now.isAfter(endTime);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Detail Ujian', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exam.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(Icons.timer_outlined, '${exam.duration} Menit', Colors.blue),
                      _buildChip(Icons.format_list_numbered_rounded, '${exam.questionCount ?? 0} Soal', Colors.teal),
                      _buildChip(Icons.grade_outlined, 'KKM: ${exam.passScore ?? 75}', Colors.orange),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Schedule Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jadwal Pelaksanaan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.event_available, size: 18, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mulai: ${startTime != null ? DateHelper.formatDateTime(startTime.toIso8601String()) : "Langsung Bisa Diikuti"}',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.event_busy, size: 18, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Selesai: ${endTime != null ? DateHelper.formatDateTime(endTime.toIso8601String()) : "Tanpa Batas Tenggat"}',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Instructions & Description Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Petunjuk & Deskripsi Pengerjaan Ujian',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    (exam.description != null && exam.description!.isNotEmpty)
                        ? exam.description!
                        : 'Bacalah setiap soal dengan teliti dan pilih satu jawaban paling tepat.',
                    style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.security, color: Colors.amber.shade900, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Sistem Keamanan Ujian:\n• Layar diproteksi dari Screenshot & Screen Record.\n• Aplikasi akan mencatat keluar aplikasi / split screen.\n• Maksimal toleransi keluar aplikasi: 5 kali sebelum auto-submit.',
                            style: TextStyle(fontSize: 12, height: 1.5, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action / Status Area
            if (isSubmitted) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      'Ujian Telah Selesai Dikumpulkan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green.shade800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nilai Akhir: ${session?.totalScore?.toStringAsFixed(1) ?? '0'}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExamResultScreen(sessionId: session!.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('Lihat Hasil Evaluasi Ujian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ] else if (isInProgress) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isStarting ? null : _handleResumeExam,
                  icon: _isStarting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.play_circle_outline),
                  label: Text(_isStarting ? 'Memuat Ujian...' : 'Lanjutkan Ujian', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ] else if (isNotStartedYet) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'Ujian Belum Dibuka oleh Guru',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 15),
                  ),
                ),
              ),
            ] else if (isAlreadyEnded) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Center(
                  child: Text(
                    'Masa Pengerjaan Ujian Telah Berakhir',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isStarting ? null : _handleStartExam,
                  icon: _isStarting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.arrow_forward_rounded),
                  label: Text(_isStarting ? 'Menyiapkan Soal...' : 'Mulai Kerjakan Ujian', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color.shade700),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color.shade700),
          ),
        ],
      ),
    );
  }
}
