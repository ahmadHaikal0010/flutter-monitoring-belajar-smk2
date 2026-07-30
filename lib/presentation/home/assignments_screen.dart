import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../logic/providers/auth_provider.dart';
import '../../logic/providers/assignment_provider.dart';
import '../../data/models/assignment_model.dart';
import 'assignment_detail_screen.dart';

class AssignmentsScreen extends StatefulWidget {
  final String subjectId;
  final String subjectTitle;
  final bool isEmbedded;

  const AssignmentsScreen({
    super.key,
    required this.subjectId,
    required this.subjectTitle,
    this.isEmbedded = false,
  });

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAssignments();
    });
  }

  Future<void> _loadAssignments() async {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      context.read<AssignmentProvider>().fetchSubjectAssignments(token, widget.subjectId);
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'Tidak ada tenggat';
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
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: Text(
                'Tugas: ${widget.subjectTitle}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              foregroundColor: const Color(0xFF1E293B),
            ),
      body: RefreshIndicator(
        onRefresh: _loadAssignments,
        child: Consumer<AssignmentProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.assignments.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null && provider.assignments.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    Text(provider.errorMessage!),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadAssignments,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            }

            if (provider.assignments.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'Belum ada tugas untuk mata pelajaran ini.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: provider.assignments.length,
              itemBuilder: (context, index) {
                final assignment = provider.assignments[index];
                return _buildAssignmentCard(assignment);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(AssignmentModel assignment) {
    final submission = assignment.submission;
    Color badgeBg;
    Color badgeText;
    String statusLabel;
    IconData statusIcon;

    if (submission != null) {
      if (submission.status == 'graded') {
        badgeBg = Colors.green.shade50;
        badgeText = Colors.green.shade700;
        statusLabel = 'DINILAI (${submission.score?.toStringAsFixed(0) ?? '-'}/${assignment.maxScore})';
        statusIcon = Icons.stars_rounded;
      } else if (submission.status == 'late') {
        badgeBg = Colors.orange.shade50;
        badgeText = Colors.orange.shade700;
        statusLabel = 'TERLAMBAT';
        statusIcon = Icons.warning_amber_rounded;
      } else {
        badgeBg = Colors.blue.shade50;
        badgeText = const Color(0xFF2563EB);
        statusLabel = 'TERKUMPUL';
        statusIcon = Icons.check_circle_outline_rounded;
      }
    } else {
      badgeBg = Colors.grey.shade100;
      badgeText = Colors.grey.shade700;
      statusLabel = 'BELUM DIKUMPULKAN';
      statusIcon = Icons.file_upload_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AssignmentDetailScreen(
                assignmentId: assignment.id,
                subjectTitle: widget.subjectTitle,
              ),
            ),
          ).then((_) => _loadAssignments());
        },
        title: Row(
          children: [
            Expanded(
              child: Text(
                assignment.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 14, color: badgeText),
                  const SizedBox(width: 4),
                  Text(
                    statusLabel,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: badgeText),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Tenggat: ${_formatDate(assignment.dueDate)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (assignment.description != null && assignment.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                assignment.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      ),
    );
  }
}
