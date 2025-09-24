import 'base_api_service.dart';

class NotificationApiService {
  // Notifications
  static Future<Map<String, dynamic>> getNotifications({
    int limit = 20,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    final route = '/notifications?limit=$limit&offset=$offset&unreadOnly=$unreadOnly';
    return BaseApiService.getWithAuth(route);
  }

  static Future<Map<String, dynamic>> getUnreadNotificationsCount() async {
    return BaseApiService.getWithAuth('/notifications/unread-count');
  }

  static Future<Map<String, dynamic>> markNotificationAsRead(String notificationId) async {
    return BaseApiService.putWithAuth('/notifications/$notificationId/read');
  }

  static Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    return BaseApiService.putWithAuth('/notifications/mark-all-read');
  }
}
