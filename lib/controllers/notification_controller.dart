import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class NotificationController {
  static const String _key = 'notifications';
  
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_key) ?? [];
      
      final notifications = notificationsJson
          .map((json) => NotificationModel.fromJson(jsonDecode(json)))
          .toList();
      
      // En yeni bildirimleri önce göster
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    } catch (e) {
      return [];
    }
  }

  Future<bool> addNotification(NotificationModel notification) async {
    try {
      final notifications = await getNotifications();
      notifications.insert(0, notification); // En başa ekle
      return await _saveNotifications(notifications);
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      final notifications = await getNotifications();
      final index = notifications.indexWhere((n) => n.id == notificationId);
      
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        return await _saveNotifications(notifications);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      final notifications = await getNotifications();
      notifications.removeWhere((n) => n.id == notificationId);
      return await _saveNotifications(notifications);
    } catch (e) {
      return false;
    }
  }

  Future<bool> _saveNotifications(List<NotificationModel> notifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = notifications
          .map((notification) => jsonEncode(notification.toJson()))
          .toList();
      
      return await prefs.setStringList(_key, notificationsJson);
    } catch (e) {
      return false;
    }
  }

  String generateNotificationId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Örnek bildirimler oluştur
  Future<void> createSampleNotifications() async {
    final notifications = await getNotifications();
    if (notifications.isEmpty) {
      await addNotification(NotificationModel(
        id: generateNotificationId(),
        title: 'Hoş Geldiniz!',
        message: 'QR2Cars uygulamasına hoş geldiniz. İlk aracınızı ekleyebilirsiniz.',
        createdAt: DateTime.now(),
        type: 'success',
      ));
      
      await addNotification(NotificationModel(
        id: generateNotificationId(),
        title: 'Güvenlik Uyarısı',
        message: 'Araç bilgilerinizi güncel tutmayı unutmayın.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        type: 'warning',
      ));
    }
  }
} 