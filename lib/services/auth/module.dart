import 'package:akimat_project/core/di.dart';
import 'package:akimat_project/services/auth/collection/auth_collection.dart';
import 'package:akimat_project/services/auth/collection/user_collection.dart';
import 'package:akimat_project/services/auth/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'auth/services.dart';
// import 'auth/collections/auth_collection.dart';
// import 'auth/collections/user_collection.dart';
// import '../core/di.dart';

final authServicesProvider = Provider<AuthServices>((ref) => ref.read(_authServices));

final _authServices = Provider<AuthServices>(
  (ref) => AuthServices(
    auth: ref.read(_authCollection),
    users: ref.read(_usersCollection),
  ),
);

final _authCollection = Provider<AuthCollection>(
  (ref) => AuthCollection(dio: ref.read(dioProvider)),
);

final _usersCollection = Provider<UsersCollection>(
  (ref) => UsersCollection(dio: ref.read(dioProvider)),
);
