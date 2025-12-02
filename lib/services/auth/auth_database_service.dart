import 'package:turbo_disc_golf/models/data/auth_data/auth_user.dart';
import 'package:turbo_disc_golf/models/data/user_data/user_data.dart';
import 'package:turbo_disc_golf/repositories/auth_database_repository.dart';

class AuthDatabaseService {
  final AuthDatabaseRepository _authDatabaseRepository;

  AuthDatabaseService(this._authDatabaseRepository);

  Future<TurboUser?> setUpNewUserInDatabase(
    AuthUser authUser,
    String username,
    String displayName, {
    int? pdgaNumber,
  }) {
    return _authDatabaseRepository.setUpNewUserInDatabase(
      authUser,
      username,
      displayName,
    );
  }

  Future<bool> saveUserInfoInDatabase(
    AuthUser authUser,
    String name,
    String? bio,
  ) {
    return _authDatabaseRepository.saveUserInfoInDatabase(authUser, name, bio);
  }

  Future<bool> usernameIsAvailable(String username) {
    return _authDatabaseRepository.usernameIsAvailable(username);
  }
}
