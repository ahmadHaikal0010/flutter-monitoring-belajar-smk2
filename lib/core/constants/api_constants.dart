class ApiConstants {
  // Jika pakai Emulator: 10.0.2.2
  // Jika pakai HP Fisik: Ganti dengan IP Lokal Laptop (misal: 192.168.1.5)
  // Jika pakai Laravel Sail default: port 80
  static const String baseUrl = 'http://10.0.2.2/api';
  
  // Endpoints
  static const String login = '/login';
  static const String register = '/register';
  static const String profile = '/user';
}
