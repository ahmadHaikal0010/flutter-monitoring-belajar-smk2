import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../logic/providers/auth_provider.dart';
import '../../logic/providers/exam_provider.dart';
import '../../data/models/question_model.dart';
import '../../data/models/option_model.dart';
import '../../core/utils/snack_bar_helper.dart';

class ExamPengerjaanScreen extends StatefulWidget {
  const ExamPengerjaanScreen({super.key});

  @override
  State<ExamPengerjaanScreen> createState() => _ExamPengerjaanScreenState();
}

class _ExamPengerjaanScreenState extends State<ExamPengerjaanScreen> with WidgetsBindingObserver {
  static const MethodChannel _secureChannel = MethodChannel('com.haikal.monitoring/secure_screen');

  int _currentQuestionIndex = 0;
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  final Map<String, TextEditingController> _essayControllers = {};
  final Map<String, String> _selectedOptions = {};
  bool _isSubmitting = false;

  int _violationCount = 0;
  static const int _maxViolations = 5;
  bool _isShowingWarning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setSecureScreen(true);
    _startTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setSecureScreen(false);
    _timer?.cancel();
    for (var controller in _essayControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _setSecureScreen(bool enable) async {
    try {
      if (enable) {
        await _secureChannel.invokeMethod('enableSecure');
      } else {
        await _secureChannel.invokeMethod('disableSecure');
      }
    } catch (e) {
      debugPrint('FLAG_SECURE method channel error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isSubmitting) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _violationCount++;
      if (_violationCount > _maxViolations) {
        _autoSubmitDueToCheat();
      } else {
        _showCheatWarningDialog();
      }
    }
  }

  void _showCheatWarningDialog() {
    if (_isShowingWarning || !mounted) return;
    _isShowingWarning = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Text('Peringatan ($_violationCount/$_maxViolations)'),
          ],
        ),
        content: Text(
          'Dilarang meninggalkan halaman ujian atau berpindah aplikasi!\n\n'
          'Jika Anda melakukan pelanggaran lebih dari $_maxViolations kali, ujian Anda akan otomatis dikumpulkan.',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _isShowingWarning = false;
            },
            child: const Text('Saya Mengerti'),
          ),
        ],
      ),
    ).then((_) {
      _isShowingWarning = false;
    });
  }

  void _autoSubmitDueToCheat() async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    if (mounted) {
      SnackBarHelper.show(
        context: context,
        message: 'Batas pelanggaran terlampaui. Ujian Anda otomatis dikumpulkan!',
        isError: true,
      );
    }
    await _submitExam();
  }

  void _startTimer() {
    final session = Provider.of<ExamProvider>(context, listen: false).currentSession;
    if (session == null) return;

    if (session.remainingSeconds != null) {
      _remainingTime = Duration(seconds: session.remainingSeconds!);
    } else {
      DateTime startTime;
      try {
        startTime = DateTime.parse(session.startedAtIso.replaceAll(' ', 'T')).toLocal();
      } catch (e) {
        startTime = DateTime.now();
      }
      final duration = session.duration ?? 0;
      final endTime = startTime.add(Duration(minutes: duration));
      _remainingTime = endTime.difference(DateTime.now());
    }

    if (_remainingTime.inSeconds <= 0 || session.isExpired == true) {
      _autoSubmit();
      return;
    }
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _remainingTime = _remainingTime - const Duration(seconds: 1);
      });

      if (_remainingTime.inSeconds <= 0) {
        timer.cancel();
        _autoSubmit();
      }
    });
  }

  void _autoSubmit() async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    SnackBarHelper.show(context: context, message: 'Waktu pengerjaan telah habis.', isError: true);
    await _submitExam();
  }

  Future<void> _submitExam() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final examProvider = Provider.of<ExamProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    final success = await examProvider.submitExam(token);
    if (success && mounted) {
      Navigator.pop(context);
      SnackBarHelper.show(context: context, message: 'Ujian berhasil dikumpulkan');
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return "00:00:00";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  TextEditingController _getEssayController(String questionId, String? initialValue) {
    if (!_essayControllers.containsKey(questionId)) {
      _essayControllers[questionId] = TextEditingController(text: initialValue);
    }
    return _essayControllers[questionId]!;
  }

  void _saveCurrentQuestionAnswer(QuestionModel question) {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    final examProvider = Provider.of<ExamProvider>(context, listen: false);

    if (question.questionType == 'multiple_choice') {
      final selectedOptionId = _selectedOptions[question.id];
      if (selectedOptionId != null) {
        examProvider.saveAnswer(token, questionId: question.id, selectedOptionId: selectedOptionId);
      }
    } else {
      final controller = _essayControllers[question.id];
      if (controller != null && controller.text.trim().isNotEmpty) {
        examProvider.saveAnswer(token, questionId: question.id, essayAnswer: controller.text.trim());
      }
    }
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Ujian?'),
        content: const Text('Jawaban Anda telah tersimpan secara otomatis. Waktu ujian akan tetap berjalan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExamProvider>(
      builder: (context, provider, child) {
        final questions = provider.questions;
        if (questions.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        final currentQuestion = questions[_currentQuestionIndex];
        final savedAnswer = provider.savedAnswers[currentQuestion.id];

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop || _isSubmitting) return;
            _violationCount++;
            if (_violationCount > _maxViolations) {
              _autoSubmitDueToCheat();
            } else {
              _showCheatWarningDialog();
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              title: const Text('Pengerjaan Ujian', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              foregroundColor: const Color(0xFF1E293B),
              actions: [
                _buildTimerBadge(),
              ],
            ),
            body: Column(
              children: [
                _buildQuestionNavigation(questions),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildQuestionCard(currentQuestion),
                        const SizedBox(height: 24),
                        if (currentQuestion.questionType == 'multiple_choice')
                          ...currentQuestion.options.map((opt) => _buildOptionTile(opt, currentQuestion.id, savedAnswer))
                        else
                          _buildEssayField(currentQuestion.id, savedAnswer as String?),
                      ],
                    ),
                  ),
                ),
                _buildBottomBar(questions),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimerBadge() {
    final isUrgent = _remainingTime.inMinutes < 5;
    return Container(
      margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 16, color: isUrgent ? Colors.red : const Color(0xFF2563EB)),
          const SizedBox(width: 4),
          Text(
            _formatDuration(_remainingTime),
            style: TextStyle(fontWeight: FontWeight.bold, color: isUrgent ? Colors.red : const Color(0xFF2563EB)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionNavigation(List<QuestionModel> questions) {
    return Container(
      height: 60,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final isCurrent = _currentQuestionIndex == index;
          final qId = questions[index].id;
          final isAnswered = context.watch<ExamProvider>().savedAnswers.containsKey(qId) || _selectedOptions.containsKey(qId);

          return GestureDetector(
            onTap: () {
              final currentQuestion = questions[_currentQuestionIndex];
              _saveCurrentQuestionAnswer(currentQuestion);
              setState(() => _currentQuestionIndex = index);
            },
            child: Container(
              width: 40,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrent ? const Color(0xFF2563EB) : (isAnswered ? Colors.green.shade50 : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(10),
                border: isCurrent ? null : Border.all(color: isAnswered ? Colors.green.shade200 : Colors.transparent),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCurrent ? Colors.white : (isAnswered ? Colors.green : Colors.grey.shade600),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionCard(QuestionModel question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text('Soal ${_currentQuestionIndex + 1}', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              Text('${question.score} Poin', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          if (question.imageUrl != null)
             Padding(
               padding: const EdgeInsets.only(bottom: 16),
               child: ClipRRect(
                 borderRadius: BorderRadius.circular(12),
                 child: Image.network(
                   ApiConstants.getFullStorageUrl(question.imageUrl),
                   fit: BoxFit.cover,
                   errorBuilder: (context, error, stackTrace) => Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                     child: const Row(children: [Icon(Icons.image_not_supported_outlined, color: Colors.grey), SizedBox(width: 8), Text('Gambar tidak dapat dimuat', style: TextStyle(color: Colors.grey, fontSize: 12))]),
                   ),
                 ),
               ),
             ),
          Text(question.questionText, style: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildOptionTile(OptionModel option, String questionId, dynamic savedAnswer) {
    final selectedOptionId = _selectedOptions[questionId] ?? savedAnswer;
    final isSelected = selectedOptionId == option.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? const Color(0xFF2563EB) : Colors.transparent),
      ),
      child: ListTile(
        onTap: () {
          setState(() {
            _selectedOptions[questionId] = option.id;
          });
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade100,
          ),
          child: Center(
            child: Text(
              String.fromCharCode(65 + (context.read<ExamProvider>().questions[_currentQuestionIndex].options.indexOf(option))),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        title: Text(
          option.optionText,
          style: TextStyle(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEssayField(String questionId, String? savedAnswer) {
    final controller = _getEssayController(questionId, savedAnswer);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: TextField(
            controller: controller,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Ketik jawaban Anda di sini...',
              border: InputBorder.none,
            ),
            onChanged: (val) {
              final token = Provider.of<AuthProvider>(context, listen: false).token;
              if (token != null) {
                Provider.of<ExamProvider>(context, listen: false).saveAnswer(
                  token,
                  questionId: questionId,
                  essayAnswer: val,
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(List<QuestionModel> questions) {
    final totalQuestions = questions.length;
    final currentQuestion = questions[_currentQuestionIndex];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentQuestionIndex > 0)
            OutlinedButton(
              onPressed: () {
                _saveCurrentQuestionAnswer(currentQuestion);
                setState(() => _currentQuestionIndex--);
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: Color(0xFF2563EB)),
              ),
              child: const Text('Sebelumnya'),
            )
          else
            const SizedBox(width: 100),
          if (_currentQuestionIndex < totalQuestions - 1)
            ElevatedButton(
              onPressed: () {
                _saveCurrentQuestionAnswer(currentQuestion);
                setState(() => _currentQuestionIndex++);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Selanjutnya'),
            )
          else
            ElevatedButton(
              onPressed: () {
                _saveCurrentQuestionAnswer(currentQuestion);
                _showSubmitConfirmation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Kumpulkan'),
            ),
        ],
      ),
    );
  }

  void _showSubmitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kumpulkan Ujian?'),
        content: const Text('Pastikan semua soal sudah dijawab. Anda tidak dapat mengubah jawaban setelah dikumpulkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submitExam();
            },
            child: const Text('Kumpulkan'),
          ),
        ],
      ),
    );
  }
}
