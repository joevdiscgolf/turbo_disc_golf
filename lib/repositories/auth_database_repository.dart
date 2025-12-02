import 'package:turbo_disc_golf/models/data/auth_data/auth_user.dart';
import 'package:turbo_disc_golf/models/data/user_data/user_data.dart';

abstract class AuthDatabaseRepository {
  Future<TurboUser?> setUpNewUserInDatabase(
    AuthUser authUser,
    String username,
    String displayName, {
    int? pdgaNumber,
  });
  Future<bool> saveUserInfoInDatabase(
    AuthUser authUser,
    String name,
    String? bio,
  );
  Future<bool> usernameIsAvailable(String username);
  Future<bool> userIsSetUp(String uid);
}
