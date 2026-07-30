import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/auth_provider.dart';
import '../../logic/providers/exam_provider.dart';
import '../../data/models/exam_model.dart';
import 'package:intl/intl.dart';
import 'exam_pengerjaan_screen.dart';
import 'exam_result_screen.dart';

class ExamsTab extends StatefulWidget {
  final String subjectId;

  const ExamsTab({super.key, required this.subjectId});

  @override
  State<ExamsTab> createState() => _ExamsTabState();
}

class _ExamsTabState extends State<ExamsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchExams();
    });
  }

  void _fetchExams() {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      Provider.of<ExamProvider>(context, listen: false).fetchExams(token, widget.subjectId);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Consumer<ExamProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.exams.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.exams.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async => _fetchExams(),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: provider.exams.length,
            itemBuilder: (context, index) {
              final exam = provider.exams[index];
              return _buildExamCard(exam);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Belum ada ujian',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text('Ujian akan muncul jika sudah dijadwalkan.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildExamCard(ExamModel exam) {
    final session = exam.studentSession;
    final isSubmitted = session?.status == 'submitted' || session?.status == 'graded';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _handleExamTap(exam),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(session?.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getStatusIcon(session?.status),
                      color: _getStatusColor(session?.status),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${exam.duration} Menit • ${exam.questionCount ?? 0} Soal',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  if (isSubmitted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Nilai: ${session?.totalScore?.toStringAsFixed(1) ?? '0'}',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Jadwal Mulai', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Text(
                        exam.startTime != null 
                          ? DateFormat('dd MMM, HH:mm').format(exam.startTime!)
                          : '-',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  _buildActionButton(exam),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(ExamModel exam) {
    final session = exam.studentSession;
    final isSubmitted = session?.status == 'submitted' || session?.status == 'graded';
    final isInProgress = session?.status == 'in_progress';

    if (isSubmitted) {
      return TextButton(
        onPressed: () => _handleExamTap(exam),
        child: const Text('Lihat Hasil', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
      );
    }

    // Perhitungan Waktu Server-HP
    final now = DateTime.now();
    final startTime = exam.startTime;
    final endTime = exam.endTime;

    final isNotStartedYet = startTime != null && now.isBefore(startTime);
    final isAlreadyEnded = endTime != null && now.isAfter(endTime);

    if (isNotStartedYet) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Belum Dibuka',
          style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (isAlreadyEnded && !isInProgress) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Sudah Berakhir',
          style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ElevatedButton(
      onPressed: () => _handleExamTap(exam),
      style: ElevatedButton.styleFrom(
        backgroundColor: isInProgress ? Colors.orange : const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(isInProgress ? 'Lanjutkan' : 'Mulai Ujian', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  void _handleExamTap(ExamModel exam) async {
    final session = exam.studentSession;
    final isSubmitted = session?.status == 'submitted' || session?.status == 'graded';

    if (isSubmitted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExamResultScreen(sessionId: session!.id),
        ),
      );
      return;
    }

    // Validasi Akhir sebelum memulai/melanjutkan
    final now = DateTime.now();
    final startTime = exam.startTime;
    final endTime = exam.endTime;

    final isNotStartedYet = startTime != null && now.isBefore(startTime);
    final isAlreadyEnded = endTime != null && now.isAfter(endTime);

    if (session?.status != 'in_progress') {
      if (isNotStartedYet) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ujian ini belum dimulai.')));
        return;
      }
      if (isAlreadyEnded) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masa pengerjaan telah berakhir.')));
        return;
      }
    }

    if (session == null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mulai Ujian?'),
          content: Text('Anda akan memulai "${exam.title}". Sisa waktu akan langsung berjalan.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Mulai')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    if (!mounted) return;
    
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    final success = await Provider.of<ExamProvider>(context, listen: false).startExam(token, exam.id);
    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ExamPengerjaanScreen(),
        ),
      ).then((_) => _fetchExams());
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'submitted':
      case 'graded': return Colors.green;
      case 'in_progress': return Colors.orange;
      case 'timed_out': return Colors.red;
      default: return const Color(0xFF2563EB);
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'submitted':
      case 'graded': return Icons.check_circle_outline;
      case 'in_progress': return Icons.play_circle_outline;
      case 'timed_out': return Icons.timer_off_outlined;
      default: return Icons.assignment_outlined;
    }
  }
}
