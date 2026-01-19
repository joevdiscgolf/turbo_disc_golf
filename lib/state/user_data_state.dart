import 'package:equatable/equatable.dart';
import 'package:turbo_disc_golf/models/data/user_data/user_data.dart';

abstract class UserDataState extends Equatable {
  const UserDataState();

  @override
  List<Object?> get props => [];
}

class UserDataInitial extends UserDataState {
  const UserDataInitial();
}

class UserDataLoading extends UserDataState {
  const UserDataLoading();
}

class UserDataLoaded extends UserDataState {
  const UserDataLoaded(this.user);

  final TurboUser user;

  @override
  List<Object?> get props => [user];
}

class UserDataError extends UserDataState {
  const UserDataError(this.error);

  final String error;

  @override
  List<Object?> get props => [error];
}
