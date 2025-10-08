import 'package:get_it/get_it.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_round_service.dart';

final locator = GetIt.instance;
void setUpLocator() {
  locator.registerSingleton<FirestoreRoundService>(FirestoreRoundService());
}
