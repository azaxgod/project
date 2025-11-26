import 'package:akimat_project/modules/dashboard/src/controller/users/akimat_users_state.dart';
import 'package:akimat_project/services/organizations/model/user_dto.dart';

/// Базовый интерфейс для контроллеров управления пользователями
abstract class UsersControllerBase {
  /// Загрузить список пользователей
  Future<void> refresh();

  /// Создать пользователя
  Future<void> createUser({
    required String phone,
    required String login,
    required String password,
  });

  /// Обновить пользователя
  Future<void> updateUser(
    String userId, {
    String? phone,
    String? login,
    String? password,
  });

  /// Заблокировать пользователя
  Future<void> blockUser(
    String userId, {
    String? blockReason,
  });

  /// Разблокировать пользователя
  Future<void> unblockUser(String userId);

  /// Сбросить пароль пользователя
  Future<String> resetPassword(String userId);

  /// Очистить отображение пароля
  void clearPassword(String userId);

  /// Получить состояние
  AkimatUsersState get state;
}

