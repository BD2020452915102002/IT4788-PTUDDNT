import 'package:hive/hive.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  late Box _box;

  Future<void> initBox(String boxName) async {
    _box = await Hive.openBox(boxName);
  }

  Box get box => _box;

  Future<void> closeBox() async {
    await _box.close();
  }
  Future<void> clearBox() async {
    await _box.clear();
  }

  Future<void> saveData(String key, dynamic value) async {
    await _box.put(key, value);
  }
  dynamic getData(String key) {
    return _box.get(key);
  }
  Future<void> deleteData(String key) async {
    await _box.delete(key);
  }
}
