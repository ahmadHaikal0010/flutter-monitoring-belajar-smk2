import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../logic/providers/auth_provider.dart';
import '../../logic/providers/enrollment_provider.dart';
import '../../data/models/progress_model.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProgressData();
    });
  }

  Future<void> _loadProgressData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final enrollmentProvider = Provider.of<EnrollmentProvider>(context, listen: false);
    if (authProvider.token != null) {
      await enrollmentProvider.fetchDashboardData(authProvider.token!);
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('d MMM y, HH:mm', 'id_ID').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Progres Belajar', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: Consumer<EnrollmentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.subjects.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.subjects.isEmpty) {
            return RefreshIndicator(
              onRefresh: _loadProgressData,
              child: ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('Belum ada data progres.')),
                ],
              ),
            );
          }

          final avg = provider.averageProgress;
          final totalMaterials = provider.totalCompletedMaterials;

          return RefreshIndicator(
            onRefresh: _loadProgressData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall Summary Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Rata-rata Keseluruhan',
                          style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: CircularProgressIndicator(
                                value: avg / 100,
                                strokeWidth: 12,
                                backgroundColor: Colors.blue.shade50,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  avg == 100 ? Colors.green : const Color(0xFF2563EB),
                                ),
                              ),
                            ),
                            Text(
                              '${avg.toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('Mata Pelajaran', '${provider.totalSubjects}'),
                            Container(width: 1, height: 30, color: Colors.grey.shade200),
                            _buildStatItem('Materi Selesai', '$totalMaterials'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  const Text(
                    'Rincian per Mata Pelajaran',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 16),
                  
                  // List of Subject Progress
                  ...provider.subjects.map((subject) {
                    final progress = provider.getProgress(subject.id);
                    final examResults = progress?.examResults ?? [];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Subject Header & Material Progress
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  subject.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: progress?.percentage == 100 ? Colors.green.shade50 : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${progress?.percentage ?? 0}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: progress?.percentage == 100 ? Colors.green.shade700 : const Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: (progress?.percentage ?? 0) / 100,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade100,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progress?.percentage == 100 ? Colors.green : const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${progress?.completedMaterials ?? 0} dari ${progress?.totalMaterials ?? 0} materi selesai',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),

                          // Exam Evaluation Section
                          if (examResults.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            const SizedBox(height: 14),
                            const Text(
                              'Hasil Ujian & Evaluasi',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                            ),
                            const SizedBox(height: 10),
                            ...examResults.map((exam) => _buildExamEvaluationCard(exam)),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExamEvaluationCard(ExamProgressResultModel exam) {
    Color badgeBgColor;
    Color badgeTextColor;
    String badgeText;
    IconData badgeIcon;

    if (exam.sessionStatus == 'submitted') {
      if (exam.isPassed == true) {
        badgeBgColor = Colors.green.shade50;
        badgeTextColor = Colors.green.shade700;
        badgeText = 'LULUS';
        badgeIcon = Icons.check_circle_rounded;
      } else {
        badgeBgColor = Colors.red.shade50;
        badgeTextColor = Colors.red.shade700;
        badgeText = 'TIDAK LULUS';
        badgeIcon = Icons.cancel_rounded;
      }
    } else if (exam.sessionStatus == 'in_progress') {
      badgeBgColor = Colors.blue.shade50;
      badgeTextColor = const Color(0xFF2563EB);
      badgeText = 'SEDANG DIKERJAKAN';
      badgeIcon = Icons.hourglass_top_rounded;
    } else {
      badgeBgColor = Colors.grey.shade100;
      badgeTextColor = Colors.grey.shade600;
      badgeText = 'BELUM MENGIKUTI';
      badgeIcon = Icons.help_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.examTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Durasi: ${exam.duration} menit | KKM: ${exam.passScore}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 14, color: badgeTextColor),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: badgeTextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (exam.sessionStatus == 'submitted' && exam.totalScore != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nilai Akhir: ${exam.totalScore!.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: exam.isPassed == true ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
                if (exam.submittedAt != null)
                  Text(
                    _formatDate(exam.submittedAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
