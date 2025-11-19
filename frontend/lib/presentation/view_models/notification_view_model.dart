import 'package:flutter/material.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../../data/models/fcm_token.dart';
import '../../data/services/notification_service.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationService notificationService;
  String? _fcmToken;
  bool _isSaved = false;

  String? get fcmToken => _fcmToken;
  bool get isSaved => _isSaved;

  NotificationViewModel({required this.notificationService});

  /// Lấy FCM token từ Firebase Messaging và lưu backend
  Future<void> initToken(String firebaseUid) async {
    _fcmToken = await FirebaseMessaging.instance.getToken();
    if (_fcmToken != null) {
      final success = await notificationService.saveToken(
          FcmToken(firebaseUid: firebaseUid, token: _fcmToken!));
      _isSaved = success;
      notifyListeners();
    }
  }

  /// Gửi notification
  Future<void> sendNotification({
    required String firebaseUid,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    final success = await notificationService.sendNotification(
      firebaseUid: firebaseUid,
      title: title,
      body: body,
      data: data,
    );
    if (success) {
      print("Notification sent to $firebaseUid");
    } else {
      print("Failed to send notification");
    }
  }
}
