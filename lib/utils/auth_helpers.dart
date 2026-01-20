import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';

/// Returns true if the currently logged-in user is an admin
bool isCurrentUserAdmin() {
  final String? currentUid = locator.get<AuthService>().currentUid;
  if (currentUid == null) return false;
  return adminUserIds.contains(currentUid);
}
