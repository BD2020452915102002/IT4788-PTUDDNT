import 'package:ptuddnt/core/config/api_class.dart';
import 'package:ptuddnt/core/utils/token.dart';

class SendNotify {
  Future<String> sendNotificationToOne(String message, int toUser, String type) async {
    try {
      final res = await ApiClass().post('/send_notification', {
        "token": Token().get(),
        "message": message,
        "to_user": toUser,
        "type": type,
      });
      if (res.statusCode == 200) {
        return 'ok';
      } else {
        return 'ohno';
      }
    } catch (e) {
      return 'ohno';
    }
  }

  Future<List<String>> sendNotificationToMulti(String message, List<int> listUser, String type) async {
    List<String> results = [];
    for (int toUser in listUser) {
      try {
        final result = await sendNotificationToOne(message, toUser, type);
        results.add(result);
      } catch (e) {
        results.add('ohno');
      }
    }
    return results;
  }
}
