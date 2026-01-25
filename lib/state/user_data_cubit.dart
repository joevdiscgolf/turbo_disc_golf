import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/user_data/pdga_metadata.dart';
import 'package:turbo_disc_golf/models/data/user_data/user_data.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';
import 'package:turbo_disc_golf/services/firestore/fb_user_data_loader.dart';
import 'package:turbo_disc_golf/state/user_data_state.dart';

class UserDataCubit extends Cubit<UserDataState> implements ClearOnLogoutProtocol {
  UserDataCubit() : super(const UserDataInitial());

  /// Load current user data from Firestore.
  /// Called once on app startup when user is logged in.
  Future<void> loadUserData() async {
    emit(const UserDataLoading());

    try {
      final String? uid = locator.get<AuthService>().currentUid;
      if (uid == null) {
        emit(const UserDataError('No user logged in'));
        return;
      }

      final TurboUser? user = await FBUserDataLoader.getCurrentUser(uid);
      if (user == null) {
        emit(const UserDataError('User not found'));
        return;
      }

      emit(UserDataLoaded(user));
    } catch (e) {
      emit(UserDataError('Failed to load user data: $e'));
    }
  }

  /// Refresh user data from Firestore.
  Future<void> refreshUserData() async {
    await loadUserData();
  }

  /// Update the user's PDGA division.
  Future<bool> updateDivision(String division) async {
    final String? uid = locator.get<AuthService>().currentUid;
    if (uid == null) return false;

    // Optimistically update state to avoid flicker
    final UserDataState currentState = state;
    if (currentState is UserDataLoaded) {
      final TurboUser currentUser = currentState.user;
      final PDGAMetadata updatedMetadata =
          (currentUser.pdgaMetadata ?? const PDGAMetadata())
              .copyWith(division: division);
      final TurboUser updatedUser =
          currentUser.copyWith(pdgaMetadata: updatedMetadata);
      emit(UserDataLoaded(updatedUser));
    }

    final bool success = await FBUserDataLoader.updateUserDivision(
      uid,
      division,
    );

    // If save failed, refresh to get correct state from server
    if (!success) {
      await refreshUserData();
    }

    return success;
  }

  /// Update the user's PDGA rating.
  Future<bool> updateRating(int rating) async {
    final String? uid = locator.get<AuthService>().currentUid;
    if (uid == null) return false;

    // Optimistically update state to avoid flicker
    final UserDataState currentState = state;
    if (currentState is UserDataLoaded) {
      final TurboUser currentUser = currentState.user;
      final PDGAMetadata updatedMetadata =
          (currentUser.pdgaMetadata ?? const PDGAMetadata())
              .copyWith(pdgaRating: rating);
      final TurboUser updatedUser =
          currentUser.copyWith(pdgaMetadata: updatedMetadata);
      emit(UserDataLoaded(updatedUser));
    }

    final bool success = await FBUserDataLoader.updateUserRating(
      uid,
      rating,
    );

    // If save failed, refresh to get correct state from server
    if (!success) {
      await refreshUserData();
    }

    return success;
  }

  @override
  Future<void> clearOnLogout() async {
    emit(const UserDataInitial());
  }
}
