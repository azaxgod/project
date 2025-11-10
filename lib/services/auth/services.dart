import 'package:akimat_project/services/auth/collection/auth_collection.dart';
import 'package:akimat_project/services/auth/collection/user_collection.dart';

// import 'collections/auth_collection.dart';
// import 'collections/user_collection.dart';

class AuthServices {
  AuthServices({
    required this.auth,
    required this.users,
  });

  final AuthCollection auth;
  final UsersCollection users;
}
