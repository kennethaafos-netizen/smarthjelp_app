import 'package:flutter/foundation.dart';

class NotificationService {
  static Future init() async {
    // 🔥 Chrome/web: gjør ingenting (unngår crash)
    if (kIsWeb) return;
  }

  static Future show(String title, String body) async {
    // 🔥 Chrome/web: bare print (debug)
    if (kIsWeb) {
      debugPrint("🔔 $title - $body");
      return;
    }

    // TODO: ekte mobil notifications senere (Firebase)
  }
}