import 'package:akimat_project/modules/dashboard/src/controller/users/akimat_users_state.dart';
import 'package:akimat_project/services/organizations/module.dart';
import 'package:akimat_project/services/organizations/model/user_dto.dart';
import 'package:akimat_project/services/organizations/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final akimatUsersControllerProvider =
    StateNotifierProvider<AkimatUsersController, AkimatUsersState>((ref) {
  final services = ref.watch(organizationsServicesProvider);
  return AkimatUsersController(services: services);
});

class AkimatUsersController extends StateNotifier<AkimatUsersState> {
  AkimatUsersController({
    required OrganizationsServices services,
  })  : _services = services,
        super(AkimatUsersState.initial()) {
    _loadData();
  }

  final OrganizationsServices _services;

  Future<void> _loadData() async {
    state = state.copyWith(data: const AsyncLoading());
    state = state.copyWith(
      data: await AsyncValue.guard(() async {
        final users = await _services.rolesCollection.getAkimatUsers();
        return users;
      }),
    );
  }

  Future<void> refresh() => _loadData();

  Future<void> createUser({
    required String phone,
    required String login,
    required String password,
  }) async {
    try {
      await _services.rolesCollection.createAkimatUser(
        phone: phone,
        login: login,
        password: password,
      );
      await refresh();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUser(
    String userId, {
    String? phone,
    String? login,
    String? password,
  }) async {
    try {
      await _services.rolesCollection.updateUser(
        userId,
        phone: phone,
        login: login,
        password: password,
      );
      await refresh();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> blockUser(
    String userId, {
    String? blockReason,
  }) async {
    try {
      await _services.rolesCollection.blockUser(
        userId,
        blockReason: blockReason,
      );
      await refresh();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unblockUser(String userId) async {
    try {
      await _services.rolesCollection.unblockUser(userId);
      await refresh();
    } catch (e) {
      rethrow;
    }
  }

  Future<String> resetPassword(String userId) async {
    try {
      // Генерируем случайный пароль
      final newPassword = _generateRandomPassword();
      await _services.rolesCollection.updateUser(
        userId,
        password: newPassword,
      );
      await refresh();
      return newPassword;
    } catch (e) {
      rethrow;
    }
  }

  String _generateRandomPassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();
    for (int i = 0; i < 12; i++) {
      buffer.write(chars[(random + i) % chars.length]);
    }
    return buffer.toString();
  }
}



