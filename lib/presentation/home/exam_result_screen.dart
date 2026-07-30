import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/material_model.dart';
import '../../data/services/student_service.dart';
import '../../logic/providers/auth_provider.dart';
import '../../logic/providers/exam_provider.dart';
import '../../data/models/exam_result_model.dart';
import 'material_detail_screen.dart';

class ExamResultScreen extends StatefulWidget {
  final String sessionId;

  const ExamResultScreen({super.key, required this.sessionId});

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        Provider.of<ExamProvider>(context, listen: false).fetchExamResult(token, widget.sessionId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Hasil Ujian', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: Consumer<ExamProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final result = provider.examResult;
          if (result == null) {
            return const Center(child: Text('Data hasil ujian tidak ditemukan'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildScoreHeader(result),
                const SizedBox(height: 24),
                const Text(
                  'Detail Jawaban',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: result.answers.length,
                  itemBuilder: (context, index) {
                    final answer = result.answers[index];
                    return _buildAnswerCard(index + 1, answer);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoreHeader(ExamResultModel result) {
    final isPassed = result.isPassed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Text(
            result.examTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: result.totalScore / 100,
                  strokeWidth: 10,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(isPassed ? Colors.green : Colors.red),
                ),
              ),
              Column(
                children: [
                  Text(
                    result.totalScore.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 32, 
                      fontWeight: FontWeight.bold, 
                      color: isPassed ? Colors.green : Colors.red
                    ),
                  ),
                  Text('Skor Akhir', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoChip(Icons.flag_outlined, 'KKM: ${result.passScore}'),
              const SizedBox(width: 12),
              _buildStatusChip(isPassed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool isPassed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPassed ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isPassed ? 'LULUS' : 'TIDAK LULUS',
        style: TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.bold, 
          color: isPassed ? Colors.green : Colors.red
        ),
      ),
    );
  }

  Widget _buildAnswerCard(int number, dynamic answer) {
    final bool? isCorrect = answer.isCorrect;
    final bool isEssay = answer.questionType == 'essay';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                child: Center(child: Text('$number', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  answer.questionText,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ),
              if (isCorrect != null)
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? Colors.green : Colors.red,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            isEssay ? 'Jawaban Anda:' : 'Pilihan Anda:',
            style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            isEssay ? (answer.essayAnswer ?? '-') : (answer.selectedOptionText ?? 'Tidak menjawab'),
            style: TextStyle(
              fontSize: 13, 
              color: isCorrect == false ? Colors.red : Colors.black87,
              fontWeight: FontWeight.w500
            ),
          ),
          const SizedBox(height: 8),
          if (isCorrect == false && answer.materialId != null)
            _buildMaterialRecommendation(answer.materialTitle ?? 'Materi Terkait', answer.materialId!),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Poin: ${answer.scoreEarned} / ${answer.maxScore}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
            ),
          ),
        ],
      ),
    );
  }

  bool _isFetchingMaterial = false;

  Future<void> _openMaterial(String materialId) async {
    if (_isFetchingMaterial) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isFetchingMaterial = true);

    try {
      final response = await StudentService().getMaterialDetail(token, materialId);
      if (response.data['success'] == true) {
        final rawData = response.data['data'];
        final materialData = (rawData is Map && rawData.containsKey('material')) ? rawData['material'] : rawData;
        final material = MaterialModel.fromJson(materialData);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MaterialDetailScreen(material: material),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat materi')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingMaterial = false);
      }
    }
  }

  Widget _buildMaterialRecommendation(String title, String materialId) {
    return InkWell(
      onTap: () => _openMaterial(materialId),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 16, color: Colors.orange.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Perlu dipelajari kembali:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                  ),
                ),
                if (_isFetchingMaterial)
                   const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 13, color: Colors.orange.shade900, fontWeight: FontWeight.w500),
                  ),
                ),
                Icon(Icons.chevron_right, size: 16, color: Colors.orange.shade800),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
