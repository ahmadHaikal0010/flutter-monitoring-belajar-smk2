import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/enrollment_provider.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

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
          if (provider.subjects.isEmpty) {
            return const Center(child: Text('Belum ada data progres.'));
          }

          final avg = provider.averageProgress;
          final totalMaterials = provider.totalCompletedMaterials;

          return SingleChildScrollView(
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
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                subject.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            Text(
                              '${progress?.percentage ?? 0}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: progress?.percentage == 100 ? Colors.green : Colors.blue,
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
                        const SizedBox(height: 12),
                        Text(
                          '${progress?.completedMaterials ?? 0} dari ${progress?.totalMaterials ?? 0} materi selesai',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
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
