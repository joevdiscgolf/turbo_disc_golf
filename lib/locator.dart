import 'package:get_it/get_it.dart';
import 'package:turbo_disc_golf/services/bag_service.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_round_service.dart';
import 'package:turbo_disc_golf/services/gemini_service.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';
import 'package:turbo_disc_golf/services/round_storage_service.dart';
import 'package:turbo_disc_golf/services/rounds_service.dart';

final locator = GetIt.instance;
void setUpLocator() {
  // Register core services first
  locator.registerSingleton<GeminiService>(GeminiService());
  locator.registerSingleton<BagService>(BagService());
  locator.registerSingleton<RoundStorageService>(RoundStorageService());
  locator.registerSingleton<FirestoreRoundService>(FirestoreRoundService());

  // Register RoundsService which depends on FirestoreRoundService
  locator.registerSingleton<RoundsService>(
    RoundsService(locator.get<FirestoreRoundService>()),
  );

  // Register RoundParser which depends on other services
  locator.registerSingleton<RoundParser>(
    RoundParser(
      geminiService: locator.get<GeminiService>(),
      bagService: locator.get<BagService>(),
      storageService: locator.get<RoundStorageService>(),
    ),
  );
}
