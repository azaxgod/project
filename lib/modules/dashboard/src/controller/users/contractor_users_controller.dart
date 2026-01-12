import 'package:akimat_project/modules/dashboard/src/controller/users/akimat_users_state.dart';
import 'package:akimat_project/modules/dashboard/src/controller/users/users_controller_base.dart';
import 'package:akimat_project/services/organizations/module.dart';
import 'package:akimat_project/services/organizations/model/user_dto.dart';
import 'package:akimat_project/services/organizations/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final contractorUsersControllerProvider =
    StateNotifierProvider<ContractorUsersController, AkimatUsersState>((ref) {
  final services = ref.watch(organizationsServicesProvider);
  return ContractorUsersController(services: services);
});

class ContractorUsersController extends StateNotifier<AkimatUsersState> implements UsersControllerBase {
  ContractorUsersController({
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
        final users = await _services.rolesCollection.getContractorUsers();
        return users;
      }),
    );
  }

  @override
  Future<void> refresh() => _loadData();

  @override
  Future<void> createUser({
    required String phone,
    required String login,
    required String password,
    bool skipReload = false,
  }) async {
    try {
      await _services.rolesCollection.createContractorUser(
        phone: phone,
        login: login,
        password: password,
      );
      if (!skipReload) {
        await refresh();
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateUser(
    String userId, {
    String? phone,
    String? login,
    String? password,
    bool skipReload = false,
  }) async {
    try {
      if (userId.isEmpty) {
        throw Exception('ID пользователя не может быть пустым');
      }
      await _services.rolesCollection.updateUser(
        userId,
        phone: phone,
        login: login,
        password: password,
      );
      if (!skipReload) {
        await refresh();
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> blockUser(
    String userId, {
    String? blockReason,
  }) async {
    try {
      if (userId.isEmpty) {
        throw Exception('ID пользователя не может быть пустым');
      }
      await _services.rolesCollection.blockUser(userId, blockReason: blockReason);
      await refresh();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> unblockUser(String userId) async {
    try {
      if (userId.isEmpty) {
        throw Exception('ID пользователя не может быть пустым');
      }
      await _services.rolesCollection.unblockUser(userId);
      await refresh();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> resetPassword(String userId) async {
    try {
      if (userId.isEmpty) {
        throw Exception('ID пользователя не может быть пустым');
      }
      // Генерируем случайный пароль
      final newPassword = _generateRandomPassword();
      await _services.rolesCollection.updateUser(
        userId,
        password: newPassword,
      );
      
      // Сохраняем пароль в состоянии для отображения в таблице
      final updatedPasswords = Map<String, String>.from(state.resetPasswords);
      updatedPasswords[userId] = newPassword;
      state = state.copyWith(resetPasswords: updatedPasswords);
      
      await refresh();
      return newPassword;
    } catch (e) {
      rethrow;
    }
  }

  @override
  void clearPassword(String userId) {
    final updatedPasswords = Map<String, String>.from(state.resetPasswords);
    updatedPasswords.remove(userId);
    state = state.copyWith(resetPasswords: updatedPasswords);
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



