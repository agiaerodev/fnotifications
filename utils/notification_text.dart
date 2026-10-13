import 'package:firebase_messaging/firebase_messaging.dart';

String extractNotificationTitle(RemoteMessage message) {
  final title = message.notification?.title ??
      message.data['title']?.toString() ??
      'New notification';
  return stripNotificationHtml(title);
}

String extractNotificationBody(RemoteMessage message) {
  final dataMessage = message.data['message']?.toString().trim();
  if (dataMessage != null && dataMessage.isNotEmpty) {
    return stripNotificationHtml(dataMessage);
  }

  final notificationBody = message.notification?.body?.trim();
  if (notificationBody != null && notificationBody.isNotEmpty) {
    return stripNotificationHtml(notificationBody);
  }

  return '';
}

String stripNotificationHtml(String value) {
  final withoutTags = value.replaceAll(RegExp(r'<[^>]*>'), ' ');
  return withoutTags.replaceAll(RegExp(r'\s+'), ' ').trim();
}
