import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/snack_bar_helper.dart';
import '../../logic/providers/auth_provider.dart';
import '../../logic/providers/enrollment_provider.dart';
import 'materials_screen.dart';

class AvailableSubjectsScreen extends StatefulWidget {
  const AvailableSubjectsScreen({super.key});

  @override
  State<AvailableSubjectsScreen> createState() => _AvailableSubjectsScreenState();
}

class _AvailableSubjectsScreenState extends State<AvailableSubjectsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      await Provider.of<EnrollmentProvider>(context, listen: false)
          .fetchAvailableSubjects(token);
    }
  }

  void _confirmUnenroll(String subjectId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Lepas Pendaftaran', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin melepas pendaftaran mata pelajaran "$title"? '
          'Seluruh progres materi, tugas yang dikumpulkan, maupun ujian yang dikerjakan akan hilang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _unenroll(subjectId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ya, Lepas'),
          ),
        ],
      ),
    );
  }

  void _enroll(String subjectId) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    final provider = Provider.of<EnrollmentProvider>(context, listen: false);
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await provider.enroll(token, subjectId);

    if (mounted) {
      Navigator.pop(context); // Close loading indicator
      if (success) {
        SnackBarHelper.show(context: context, message: 'Berhasil mendaftar mata pelajaran');
      } else {
        SnackBarHelper.show(
          context: context, 
          message: provider.errorMessage ?? 'Gagal mendaftar', 
          isError: true
        );
      }
    }
  }

  void _unenroll(String subjectId) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    final provider = Provider.of<EnrollmentProvider>(context, listen: false);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await provider.unenroll(token, subjectId);

    if (mounted) {
      Navigator.pop(context); // Close loading indicator
      if (success) {
        SnackBarHelper.show(context: context, message: 'Pendaftaran berhasil dilepas');
      } else {
        SnackBarHelper.show(
          context: context, 
          message: provider.errorMessage ?? 'Gagal melepas pendaftaran', 
          isError: true
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Daftar Mata Pelajaran', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: Consumer<EnrollmentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.availableSubjects.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.availableSubjects.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'Tidak ada mata pelajaran tersedia',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Mungkin kelas Anda belum memiliki mata pelajaran.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: provider.availableSubjects.length,
              itemBuilder: (context, index) {
                final subject = provider.availableSubjects[index];
                
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.book_outlined, color: Color(0xFF2563EB)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    subject.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    'Guru: ${subject.teacherName}',
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (subject.description != null && subject.description!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            subject.description!,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (!subject.isEnrolled)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _enroll(subject.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Daftar', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MaterialsScreen(
                                          subjectId: subject.id,
                                          subjectTitle: subject.title,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    foregroundColor: const Color(0xFF2563EB),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: const Text('Buka Mata Pelajaran', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: TextButton(
                                  onPressed: () => _confirmUnenroll(subject.id, subject.title),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red.shade600,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: const Text('Lepas', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
