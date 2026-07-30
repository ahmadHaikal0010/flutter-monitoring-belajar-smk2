class ApiConstants {
  // Jika pakai Emulator: 10.0.2.2
  // Jika pakai HP Fisik: Ganti dengan IP Lokal Laptop (misal: 192.168.1.5)
  // Jika pakai Laravel Sail dengan APP_PORT=8000
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  static const String storageUrl = 'http://10.0.2.2:8000/storage';
  
  static String getFullStorageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    const String domainUrl = 'http://10.0.2.2:8000';
    if (path.startsWith('/storage/')) {
      return '$domainUrl$path';
    }
    if (path.startsWith('/')) {
      return '$domainUrl$path';
    }
    return '$storageUrl/$path';
  }
  
  // Endpoints
  static const String login = '/login';
  static const String logout = '/logout';
  static const String register = '/register';
  static const String profile = '/profile';
  static const String updateProfile = '/update-profile';

  // Dashboard Aggregator Endpoints
  static const String dashboardSummary = '/dashboard/summary';
  static const String dashboardSubjects = '/dashboard/enrolled-subjects';
  static const String dashboardActivities = '/dashboard/recent-activities';

  // Exam Endpoints
  static String subjectExams(String subjectId) => '/subjects/$subjectId/exams';
  static String startExam(String examId) => '/exams/$examId/start';
  static String submitAnswer(String sessionId) => '/exams/sessions/$sessionId/answer';
  static String submitAnswers(String sessionId) => '/exams/sessions/$sessionId/answers';
  static String submitExam(String sessionId) => '/exams/sessions/$sessionId/submit';
  static String examResult(String sessionId) => '/exams/sessions/$sessionId/result';
}
