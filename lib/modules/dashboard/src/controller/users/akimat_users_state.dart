import 'package:akimat_project/services/organizations/model/user_dto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AkimatUsersState {
  final AsyncValue<List<UserDto>> data;
  // Хранит сброшенные пароли: userId -> password
  final Map<String, String> resetPasswords;

  const AkimatUsersState({
    required this.data,
    this.resetPasswords = const {},
  });

  factory AkimatUsersState.initial() {
    return const AkimatUsersState(
      data: AsyncLoading(),
      resetPasswords: {},
    );
  }

  AkimatUsersState copyWith({
    AsyncValue<List<UserDto>>? data,
    Map<String, String>? resetPasswords,
  }) {
    return AkimatUsersState(
      data: data ?? this.data,
      resetPasswords: resetPasswords ?? this.resetPasswords,
    );
  }
}





