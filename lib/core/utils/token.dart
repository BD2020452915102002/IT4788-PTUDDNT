import 'package:ptuddnt/core/utils/hive.dart';
class Token {
  String get() {
    return HiveService().getData('token');
  }
  Future<void> save(String token) async {
    await HiveService().saveData('token', token);
  }
  Future<void> remove() async {
    await HiveService().deleteData('token');
  }
}
