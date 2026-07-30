import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/material_model.dart';
import '../../data/services/student_service.dart';
import '../../logic/providers/auth_provider.dart';
import '../../logic/providers/enrollment_provider.dart';
import 'material_detail_screen.dart';
import 'exams_tab.dart';
import 'package:intl/intl.dart';

import 'assignments_screen.dart';

class MaterialsScreen extends StatefulWidget {
  final String subjectId;
  final String subjectTitle;

  const MaterialsScreen({
    super.key,
    required this.subjectId,
    required this.subjectTitle,
  });

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final StudentService _studentService = StudentService();
  List<MaterialModel> _materials = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMaterials();
  }

  Future<void> _fetchMaterials() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      final response = await _studentService.getMaterials(token, widget.subjectId);
      if (response.data['success'] == true) {
        final List data = response.data['data']['data'];
        setState(() {
          _materials = data.map((json) => MaterialModel.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mengambil daftar materi';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Detail Mata Pelajaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(widget.subjectTitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: const Color(0xFF1E293B),
          bottom: const TabBar(
            labelColor: Color(0xFF2563EB),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF2563EB),
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Materi'),
              Tab(text: 'Tugas'),
              Tab(text: 'Ujian'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMaterialsView(),
            AssignmentsScreen(subjectId: widget.subjectId, subjectTitle: widget.subjectTitle, isEmbedded: true),
            ExamsTab(subjectId: widget.subjectId),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialsView() {
    return Consumer<EnrollmentProvider>(
      builder: (context, enrollmentProvider, child) {
        final progress = enrollmentProvider.getProgress(widget.subjectId);

        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _fetchMaterials,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        if (_materials.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _fetchMaterials,
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _materials.length,
            itemBuilder: (context, index) {
              final material = _materials[index];
              final isCompleted = progress?.isMaterialCompleted(material.id) ?? false;

              return _buildMaterialCard(material, isCompleted);
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
          Icon(Icons.library_books_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Belum ada materi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text('Materi akan muncul setelah guru mengunggahnya.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(MaterialModel material, bool isCompleted) {
    IconData iconData;
    Color iconColor;

    switch (material.contentType) {
      case 'video':
        iconData = Icons.play_circle_outline_rounded;
        iconColor = Colors.redAccent;
        break;
      case 'document':
        iconData = Icons.picture_as_pdf_rounded;
        iconColor = Colors.blue;
        break;
      case 'url':
        iconData = Icons.link_rounded;
        iconColor = Colors.teal;
        break;
      default:
        iconData = Icons.article_outlined;
        iconColor = Colors.orange;
    }

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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(iconData, color: iconColor),
            ),
            if (isCompleted)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 10, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Text(
          material.title,
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 16,
            color: isCompleted ? Colors.grey : const Color(0xFF1E293B),
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              isCompleted ? 'Materi telah selesai dipelajari.' : (material.description ?? 'Klik untuk belajar.'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: isCompleted ? Colors.green : Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd MMM yyyy').format(material.createdAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MaterialDetailScreen(material: material),
            ),
          );
        },
      ),
    );
  }
}
