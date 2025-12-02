import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  setBooleanValue(String key, bool value) async {
    SharedPreferences myPrefs = await SharedPreferences.getInstance();
    myPrefs.setBool(key, value);
  }

  Future<bool?> getBooleanValue(String key) async {
    SharedPreferences myPrefs = await SharedPreferences.getInstance();
    return myPrefs.getBool(key);
  }

  Future<void> markUserIsSetUp(bool isSetUp) async {
    SharedPreferences myPrefs = await SharedPreferences.getInstance();
    myPrefs.setBool('userIsSetUp', isSetUp);
  }

  Future<bool?> userIsSetUp() async {
    SharedPreferences myPrefs = await SharedPreferences.getInstance();
    return myPrefs.getBool('userIsSetUp');
  }
}
