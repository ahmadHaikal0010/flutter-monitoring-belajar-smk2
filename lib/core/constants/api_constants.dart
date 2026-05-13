class ApiConstants {
  // Jika pakai Emulator: 10.0.2.2
  // Jika pakai HP Fisik: Ganti dengan IP Lokal Laptop (misal: 192.168.1.5)
  // Jika pakai Laravel Sail dengan APP_PORT=8000
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  
  // Endpoints
  static const String login = '/login';
  static const String logout = '/logout';
  static const String register = '/register';
  static const String profile = '/user';
}
