import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/date_helper.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/snack_bar_helper.dart';
import '../../logic/providers/auth_provider.dart';
import '../../logic/providers/assignment_provider.dart';
import '../../data/models/assignment_model.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final String assignmentId;
  final String subjectTitle;

  const AssignmentDetailScreen({
    super.key,
    required this.assignmentId,
    required this.subjectTitle,
  });

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  static const MethodChannel _secureChannel = MethodChannel('com.haikal.monitoring/secure_screen');

  final TextEditingController _notesController = TextEditingController();
  final List<File> _selectedFiles = [];
  final ImagePicker _picker = ImagePicker();
  bool _isEditingMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetail();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      await context.read<AssignmentProvider>().fetchAssignmentDetail(token, widget.assignmentId);
      final assignment = context.read<AssignmentProvider>().currentAssignment;
      if (assignment?.submission?.notes != null) {
        _notesController.text = assignment!.submission!.notes!;
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (picked != null) {
        setState(() {
          _selectedFiles.add(File(picked.path));
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.show(context: context, message: 'Gagal memilih foto.', isError: true);
      }
    }
  }

  Future<void> _pickPdf() async {
    try {
      final List<dynamic>? paths = await _secureChannel.invokeMethod('pickPdf');
      if (paths != null && paths.isNotEmpty) {
        for (var path in paths) {
          if (path != null && path.toString().isNotEmpty) {
            setState(() {
              _selectedFiles.add(File(path.toString()));
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.show(context: context, message: 'Gagal memilih berkas PDF.', isError: true);
      }
    }
  }

  void _removeSelectedFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _submitAssignment(bool isUpdating) async {
    if (_selectedFiles.isEmpty) {
      SnackBarHelper.show(context: context, message: 'Pilih minimal 1 berkas foto atau PDF tugas.', isError: true);
      return;
    }

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final success = await context.read<AssignmentProvider>().submitAssignment(
      token,
      assignmentId: widget.assignmentId,
      notes: _notesController.text.trim(),
      files: _selectedFiles,
    );

    if (success && mounted) {
      setState(() {
        _selectedFiles.clear();
        _isEditingMode = false;
      });
      SnackBarHelper.show(
        context: context,
        message: isUpdating ? 'Pengumpulan tugas berhasil diperbarui!' : 'Tugas berhasil dikumpulkan!',
      );
    } else if (mounted) {
      final err = context.read<AssignmentProvider>().errorMessage;
      SnackBarHelper.show(context: context, message: err ?? 'Gagal mengumpulkan tugas.', isError: true);
    }
  }

  String _formatDate(String? isoDate) {
    return DateHelper.formatDateTime(isoDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Detail Tugas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: Consumer<AssignmentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.currentAssignment == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final assignment = provider.currentAssignment;
          if (assignment == null) {
            return const Center(child: Text('Tugas tidak ditemukan.'));
          }

          final submission = assignment.submission;
          final isGraded = submission?.status == 'graded';

          return SingleChildScrollView(
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
                        widget.subjectTitle,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        assignment.title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildChip(Icons.event_outlined, 'Tenggat: ${_formatDate(assignment.dueDate)}', Colors.orange),
                          _buildChip(Icons.grade_outlined, 'Maks: ${assignment.maxScore} Poin', Colors.blue),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Instruction Card
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
                        'Instruksi Tugas',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        assignment.description ?? 'Tidak ada deskripsi instruksi.',
                        style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Existing Submission Section
                if (submission != null) ...[
                  _buildExistingSubmissionCard(submission, assignment.maxScore),
                  const SizedBox(height: 20),
                ],

                // Upload Form Section (If not submitted or in edit mode)
                if (submission == null || (_isEditingMode && !isGraded))
                  _buildUploadForm(provider.isSubmitting, assignment, isUpdating: submission != null)
                else if (!isGraded)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isEditingMode = true;
                        });
                      },
                      icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB)),
                      label: const Text(
                        'Edit / Perbarui Pengumpulan Tugas',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2563EB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
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
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingSubmissionCard(AssignmentSubmissionModel submission, int maxScore) {
    final isGraded = submission.status == 'graded';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isGraded ? Colors.green.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isGraded ? Colors.green.shade200 : Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isGraded ? 'Tugas Telah Dinilai Guru' : 'Tugas Sudah Dikumpulkan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isGraded ? Colors.green.shade800 : const Color(0xFF1E3A8A),
                ),
              ),
              if (isGraded && submission.score != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Nilai: ${submission.score!.toStringAsFixed(0)} / $maxScore',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Dikumpulkan pada: ${_formatDate(submission.submittedAt)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          if (submission.notes != null && submission.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Catatan Siswa: "${submission.notes}"',
              style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Color(0xFF334155)),
            ),
          ],
          if (submission.feedback != null && submission.feedback!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Catatan/Feedback Guru:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                  const SizedBox(height: 4),
                  Text(submission.feedback!, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                ],
              ),
            ),
          ],
          if (submission.files.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Berkas Terlampir:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            ...submission.files.map((file) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final url = ApiConstants.getFullStorageUrl(file.filePath);
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: Icon(file.fileType == 'pdf' ? Icons.picture_as_pdf : Icons.image, size: 16, color: file.fileType == 'pdf' ? Colors.red : Colors.blue),
                    label: Text(file.fileName, overflow: TextOverflow.ellipsis),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadForm(bool isSubmitting, AssignmentModel assignment, {bool isUpdating = false}) {
    final allowedTypes = assignment.allowedFileTypes.map((e) => e.toString().toLowerCase()).toList();
    final allowImage = allowedTypes.isEmpty || allowedTypes.contains('image') || allowedTypes.contains('photo') || allowedTypes.contains('jpg') || allowedTypes.contains('png');
    final allowPdf = allowedTypes.isEmpty || allowedTypes.contains('pdf') || allowedTypes.contains('document');

    String allowedNoticeText = 'Pilih Berkas Tugas (Maks 10MB/file):';
    if (allowImage && allowPdf) {
      allowedNoticeText = 'Format diizinkan: Foto (JPG/PNG) & Dokumen PDF (Maks 10MB/file)';
    } else if (allowPdf) {
      allowedNoticeText = 'Format diizinkan guru: Dokumen PDF Saja (Maks 10MB/file)';
    } else if (allowImage) {
      allowedNoticeText = 'Format diizinkan guru: Foto Kamera/Galeri Saja (Maks 10MB/file)';
    }

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isUpdating ? 'Edit / Perbarui Tugas' : 'Kirim Pengumpulan Tugas',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
              ),
              if (isUpdating)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditingMode = false;
                      _selectedFiles.clear();
                    });
                  },
                  child: const Text('Batal Edit', style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
          if (isUpdating) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: Colors.amber.shade900),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pilih berkas baru di bawah ini untuk memperbarui pengumpulan tugas Anda.',
                      style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            allowedNoticeText,
            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),

          // File Picker Buttons (Kamera, Galeri, Berkas PDF)
          Row(
            children: [
              if (allowImage) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isSubmitting ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined, size: 16),
                    label: const Text('Kamera', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isSubmitting ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: const Text('Galeri', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
              if (allowImage && allowPdf) const SizedBox(width: 6),
              if (allowPdf)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isSubmitting ? null : _pickPdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16, color: Colors.red),
                    label: const Text('PDF', style: TextStyle(fontSize: 12, color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
            ],
          ),

          if (_selectedFiles.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Berkas Yang Akan Dikirim:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            ..._selectedFiles.asMap().entries.map((entry) {
              final idx = entry.key;
              final file = entry.value;
              final name = file.path.split('/').last;
              final isPdf = name.toLowerCase().endsWith('.pdf');

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isPdf ? Colors.red.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isPdf ? Colors.red.shade200 : Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                      size: 20,
                      color: isPdf ? Colors.red : const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.red),
                      onPressed: () => _removeSelectedFile(idx),
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 16),

          // Notes TextField
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Tambahkan catatan untuk guru (opsional)...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
          ),

          const SizedBox(height: 20),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: isSubmitting ? null : () => _submitAssignment(isUpdating),
              icon: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Icon(isUpdating ? Icons.sync_rounded : Icons.send_rounded),
              label: Text(
                isSubmitting
                    ? 'Mengunggah Berkas...'
                    : (isUpdating ? 'Perbarui Pengumpulan Tugas' : 'Kumpulkan Tugas'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isUpdating ? Colors.orange.shade700 : const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
