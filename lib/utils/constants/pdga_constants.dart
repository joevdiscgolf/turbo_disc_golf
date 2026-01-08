// Constants for PDGA (Professional Disc Golf Association) data
//
// These definitions follow PDGA standards for disc golf divisions.

/// PDGA Divisions
/// All divisions used in PDGA disc golf tournaments.
abstract class PDGADivisions {
  // Pro divisions
  static const String mpo = 'MPO'; // Mixed Professional Open
  static const String fpo = 'FPO'; // Female Professional Open

  // Pro Masters divisions
  static const String mp40 = 'MP40'; // Mixed Professional 40+
  static const String mp50 = 'MP50'; // Mixed Professional 50+
  static const String mp60 = 'MP60'; // Mixed Professional 60+
  static const String mp65 = 'MP65'; // Mixed Professional 65+
  static const String mp70 = 'MP70'; // Mixed Professional 70+

  // Female Pro Masters divisions
  static const String fp40 = 'FP40'; // Female Professional 40+
  static const String fp50 = 'FP50'; // Female Professional 50+
  static const String fp55 = 'FP55'; // Female Professional 55+

  // Mixed Amateur divisions
  static const String ma1 = 'MA1'; // Mixed Amateur Advanced
  static const String ma2 = 'MA2'; // Mixed Amateur Intermediate
  static const String ma3 = 'MA3'; // Mixed Amateur Recreational
  static const String ma4 = 'MA4'; // Mixed Amateur Novice

  // Female Amateur divisions
  static const String fa1 = 'FA1'; // Female Amateur Advanced
  static const String fa2 = 'FA2'; // Female Amateur Intermediate
  static const String fa3 = 'FA3'; // Female Amateur Recreational
  static const String fa4 = 'FA4'; // Female Amateur Novice

  // Mixed Amateur Masters divisions
  static const String ma40 = 'MA40'; // Mixed Amateur 40+
  static const String ma50 = 'MA50'; // Mixed Amateur 50+
  static const String ma60 = 'MA60'; // Mixed Amateur 60+
  static const String ma65 = 'MA65'; // Mixed Amateur 65+
  static const String ma70 = 'MA70'; // Mixed Amateur 70+
  static const String ma75 = 'MA75'; // Mixed Amateur 75+

  // Female Amateur Masters divisions
  static const String fa40 = 'FA40'; // Female Amateur 40+
  static const String fa50 = 'FA50'; // Female Amateur 50+
  static const String fa55 = 'FA55'; // Female Amateur 55+
  static const String fa60 = 'FA60'; // Female Amateur 60+
  static const String fa65 = 'FA65'; // Female Amateur 65+

  // Mixed Junior divisions
  static const String mj18 = 'MJ18'; // Mixed Junior 18 & Under
  static const String mj15 = 'MJ15'; // Mixed Junior 15 & Under
  static const String mj12 = 'MJ12'; // Mixed Junior 12 & Under
  static const String mj10 = 'MJ10'; // Mixed Junior 10 & Under
  static const String mj08 = 'MJ08'; // Mixed Junior 8 & Under

  // Female Junior divisions
  static const String fj18 = 'FJ18'; // Female Junior 18 & Under
  static const String fj15 = 'FJ15'; // Female Junior 15 & Under
  static const String fj12 = 'FJ12'; // Female Junior 12 & Under
  static const String fj10 = 'FJ10'; // Female Junior 10 & Under
  static const String fj08 = 'FJ08'; // Female Junior 8 & Under

  /// All available divisions for dropdown selection (organized by category)
  static const List<String> all = [
    // Pro
    mpo,
    fpo,
    // Pro Masters
    mp40,
    mp50,
    mp60,
    mp65,
    mp70,
    // Female Pro Masters
    fp40,
    fp50,
    fp55,
    // Mixed Amateur
    ma1,
    ma2,
    ma3,
    ma4,
    // Female Amateur
    fa1,
    fa2,
    fa3,
    fa4,
    // Mixed Amateur Masters
    ma40,
    ma50,
    ma60,
    ma65,
    ma70,
    ma75,
    // Female Amateur Masters
    fa40,
    fa50,
    fa55,
    fa60,
    fa65,
    // Mixed Junior
    mj18,
    mj15,
    mj12,
    mj10,
    mj08,
    // Female Junior
    fj18,
    fj15,
    fj12,
    fj10,
    fj08,
  ];

  /// Display names for divisions
  static const Map<String, String> displayNames = {
    // Pro
    mpo: 'MPO – Mixed Professional Open',
    fpo: 'FPO – Female Professional Open',
    // Pro Masters
    mp40: 'MP40 – Mixed Professional 40+',
    mp50: 'MP50 – Mixed Professional 50+',
    mp60: 'MP60 – Mixed Professional 60+',
    mp65: 'MP65 – Mixed Professional 65+',
    mp70: 'MP70 – Mixed Professional 70+',
    // Female Pro Masters
    fp40: 'FP40 – Female Professional 40+',
    fp50: 'FP50 – Female Professional 50+',
    fp55: 'FP55 – Female Professional 55+',
    // Mixed Amateur
    ma1: 'MA1 – Mixed Amateur Advanced',
    ma2: 'MA2 – Mixed Amateur Intermediate',
    ma3: 'MA3 – Mixed Amateur Recreational',
    ma4: 'MA4 – Mixed Amateur Novice',
    // Female Amateur
    fa1: 'FA1 – Female Amateur Advanced',
    fa2: 'FA2 – Female Amateur Intermediate',
    fa3: 'FA3 – Female Amateur Recreational',
    fa4: 'FA4 – Female Amateur Novice',
    // Mixed Amateur Masters
    ma40: 'MA40 – Mixed Amateur 40+',
    ma50: 'MA50 – Mixed Amateur 50+',
    ma60: 'MA60 – Mixed Amateur 60+',
    ma65: 'MA65 – Mixed Amateur 65+',
    ma70: 'MA70 – Mixed Amateur 70+',
    ma75: 'MA75 – Mixed Amateur 75+',
    // Female Amateur Masters
    fa40: 'FA40 – Female Amateur 40+',
    fa50: 'FA50 – Female Amateur 50+',
    fa55: 'FA55 – Female Amateur 55+',
    fa60: 'FA60 – Female Amateur 60+',
    fa65: 'FA65 – Female Amateur 65+',
    // Mixed Junior
    mj18: 'MJ18 – Mixed Junior 18 & Under',
    mj15: 'MJ15 – Mixed Junior 15 & Under',
    mj12: 'MJ12 – Mixed Junior 12 & Under',
    mj10: 'MJ10 – Mixed Junior 10 & Under',
    mj08: 'MJ08 – Mixed Junior 8 & Under',
    // Female Junior
    fj18: 'FJ18 – Female Junior 18 & Under',
    fj15: 'FJ15 – Female Junior 15 & Under',
    fj12: 'FJ12 – Female Junior 12 & Under',
    fj10: 'FJ10 – Female Junior 10 & Under',
    fj08: 'FJ08 – Female Junior 8 & Under',
  };

  /// Get display name for a division (falls back to division code if not found)
  static String getDisplayName(String division) =>
      displayNames[division] ?? division;
}
