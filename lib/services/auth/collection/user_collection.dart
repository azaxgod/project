import 'package:dio/dio.dart';
import '../model/user.dart';

class UsersCollection {
  final Dio dio;

  UsersCollection({required this.dio});

  Future<List<User>> searchUsers({
    String role = 'student',
    List<int>? classIds,
  }) async {
    final response = await dio.get('/auth/api/v1/admin/users', queryParameters: {
      'role': role,
      'classIds': classIds,
    });
    final data = response.data as List<dynamic>;
    return data.map((e) => User.fromJson(e)).toList();
  }
}
