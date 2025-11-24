import 'package:akimat_project/services/organizations/model/user_dto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AkimatUsersState {
  final AsyncValue<List<UserDto>> data;

  const AkimatUsersState({
    required this.data,
  });

  factory AkimatUsersState.initial() {
    return const AkimatUsersState(
      data: AsyncLoading(),
    );
  }

  AkimatUsersState copyWith({
    AsyncValue<List<UserDto>>? data,
  }) {
    return AkimatUsersState(
      data: data ?? this.data,
    );
  }
}



