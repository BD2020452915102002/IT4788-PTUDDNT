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
  Future<void> updateField(String key, String field, dynamic newValue) async {
    // Lấy dữ liệu hiện tại từ Hive
    final existingData = _box.get(key);

    // Kiểm tra nếu dữ liệu hiện tại là Map
    if (existingData is Map) {
      existingData[field] = newValue; // Cập nhật trường cụ thể
      await _box.put(key, existingData); // Lưu lại dữ liệu đã cập nhật
    } else {
      throw Exception('Data is not a Map. Unable to update field.');
    }
  }
  Future<void> addToList(String key, dynamic value) async {
    final existingData = _box.get(key);
    if (existingData is List) {
      await _box.put(key, existingData + value);
    } else {
      throw Exception('Data is not a List. Unable to add value.');
    }
  }

}
