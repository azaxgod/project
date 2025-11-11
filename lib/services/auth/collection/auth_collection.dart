import 'package:akimat_project/services/auth/model/user.dart';
import 'package:dio/dio.dart';
import '../model/auth_response.dart';

class AuthCollection {
  final Dio dio;
  String? _tempToken;
  AuthCollection({required this.dio});

  void setTempToken(String token){
    _tempToken =token;
  }
  

  Future<AuthResponse> login(String login, String password) async {
    final response = await dio.post('/auth/login', data: {
      'login': login,
      'password': password,
    });
    return AuthResponse.fromJson(response.data['data']);
  }

  Future<Map<String, dynamic>> sendSms(String phone) async {
    final response = await dio.post('/auth/send-code', data: {'phone': phone});
    return response.data;
  }

  Future<AuthResponse> verifySms(String phone, String code) async {
    final response =
        await dio.post('/auth/verify-code', data: {'phone': phone, 'code': code});
    return AuthResponse.fromJson(response.data['data']);
  }

  Future<void> logout(String refreshToken) async {
    await dio.post('/auth/logout', data: {'refresh_token': refreshToken});
  }

  Future<AuthResponse> refresh(String refreshToken) async {
    final response =
        await dio.post('/auth/refresh', data: {'refresh_token': refreshToken});
    return AuthResponse.fromJson(response.data['data']);
  }

  Future<User> me() async {
    final response = await dio.get(
      '/auth/me',
      options: _tempToken != null
          ? Options(headers: {'Authorization': 'Bearer $_tempToken'})
          : null,
    );
    return User.fromJson(response.data['data']);
  }
}
