import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Modelo simple para tipar las notificaciones dentro de la app
class PushNotification {
  final String title;
  final String body;
  final DateTime receivedAt;
  final Map<String, dynamic> data;

  PushNotification({
    required this.title,
    required this.body,
    required this.receivedAt,
    this.data = const {},
  });
}

class NotificationProvider extends ChangeNotifier {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  bool _hasUnreadNotification = false;
  final List<PushNotification> _notifications = [];
  GlobalKey<ScaffoldMessengerState>? _snackbarKey;

  // Getters
  bool get hasUnreadNotification => _hasUnreadNotification;
  List<PushNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _hasUnreadNotification ? 1 : 0;

  void setSnackBarKey(GlobalKey<ScaffoldMessengerState> key) {
    _snackbarKey = key;
  }

  Future<void> initializeNotifications() async {
    try {
      await _requestPermissions();

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _onMessageOpenedApp(initialMessage);
      }
    } catch (e) {
      debugPrint('NotificationProvider Error: $e');
    }
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Estado de permisos: ${settings.authorizationStatus}');
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _addNotificationToList(message);
    _setHasUnread(true);
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    _setHasUnread(false);
    debugPrint('Navegando a través de notificación: ${message.data}');
  }

  void markAsRead() {
    if (_hasUnreadNotification) {
      _setHasUnread(false);
    }
  }

  void _setHasUnread(bool value) {
    _hasUnreadNotification = value;
    notifyListeners();
  }

  void _addNotificationToList(RemoteMessage message) {
    _notifications.insert(
      0,
      PushNotification(
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
        receivedAt: DateTime.now(),
        data: message.data,
      ),
    );
  }


  @override
  void dispose() {
    _notifications.clear();
    super.dispose();
  }
}