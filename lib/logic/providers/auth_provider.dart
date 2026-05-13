import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPendingApproval = false;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPendingApproval => _isPendingApproval;
  bool get isAuthenticated => _token != null;

  void resetPendingStatus() {
    _isPendingApproval = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password, String deviceName) async {
    _isLoading = true;
    _errorMessage = null;
    _isPendingApproval = false;
    notifyListeners();

    try {
      final response = await _authService.login(email, password, deviceName);
      
      if (response.data['success'] == true) {
        final data = response.data['data'];
        _token = data['token'];
        _user = UserModel.fromJson(data['user']);
        
        // Simpan token ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        // Cek jika status 403 (Forbidden) yang biasanya berarti pending di logic backend Anda
        if (e.response!.statusCode == 403) {
          _isPendingApproval = true;
        }
        _errorMessage = e.response!.data['message'] ?? 'Terjadi kesalahan sistem';
      } else {
        _errorMessage = 'Tidak dapat terhubung ke server';
      }
      print('Login Error: $_errorMessage');
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan tidak terduga';
      print('Unexpected Error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String nisn,
    required String address,
    required String password,
    required String passwordConfirmation,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.register(
        name: name,
        email: email,
        nisn: nisn,
        address: address,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      if (response.data['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        // Jika ada validation error dari Laravel
        if (e.response!.data['errors'] != null) {
          Map errors = e.response!.data['errors'];
          _errorMessage = errors.values.first[0];
        } else {
          _errorMessage = e.response!.data['message'] ?? 'Terjadi kesalahan sistem';
        }
      } else {
        _errorMessage = 'Tidak dapat terhubung ke server';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan tidak terduga';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    if (_token != null) {
      try {
        await _authService.logout(_token!);
      } catch (e) {
        print('Logout API Error: $e');
      }
    }
    
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) return;
    
    _token = prefs.getString('token');
    
    try {
      final response = await _authService.getUserProfile(_token!);
      _user = UserModel.fromJson(response.data);
      notifyListeners();
    } catch (_) {
      _token = null;
      await prefs.remove('token');
    }
  }
}
