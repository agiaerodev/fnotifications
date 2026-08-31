import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/base_api_service.dart';
import '../../../core/routes/app_routes.dart';
import '../models/notification_model.dart';
import '../routes/notification_route_names.dart';

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
  final BaseApiService _apiService = BaseApiService();
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final String _route = '/notification/v1/notifications';
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'airport_butler_channel',
    'Airport Butler',
    description: 'Notificaciones de Airport Butler',
    importance: Importance.max,
    playSound: true,
  );

  bool _hasUnreadNotification = false;
  final List<PushNotification> _notifications = [];
  List<AppNotification> _apiNotifications = [];
  GlobalKey<ScaffoldMessengerState>? _snackbarKey;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _lastPage = 1;
  bool _hasLoadedOnce = false;
  int? _currentUserId;

  // Getters
  bool get hasUnreadNotification => _hasUnreadNotification;
  List<PushNotification> get notifications => List.unmodifiable(_notifications);
  List<AppNotification> get apiNotifications => List.unmodifiable(_apiNotifications);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isRefreshing => _isRefreshing;
  bool get hasLoadedOnce => _hasLoadedOnce;
  bool get hasNextPage => _currentPage < _lastPage;
  String? get errorMessage => _errorMessage;
  int get unreadCount {
    final apiUnreadCount = _apiNotifications.where((item) => !item.isRead).length;
    if (apiUnreadCount > 0) return apiUnreadCount;
    return _hasUnreadNotification ? 1 : 0;
  }

  void setSnackBarKey(GlobalKey<ScaffoldMessengerState> key) {
    _snackbarKey = key;
  }

  void setCurrentUser(dynamic user) {
    if (user is Map && user['id'] != null) {
      _currentUserId = int.tryParse(user['id'].toString());
    } else {
      _currentUserId = null;
    }
  }

  Future<void> initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        _openNotifications();
      },
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _requestLocalNotificationPermissions();
  }

  Future<void> _requestLocalNotificationPermissions() async {
    final androidImplementation = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    final iosImplementation = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> initializeNotifications() async {
    try {
      await _requestPermissions();
      await initializeLocalNotifications();

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

  Future<void> loadNotifications({bool refresh = false, bool loadMore = false}) async {
    if (_isLoading || _isLoadingMore) return;
    if (loadMore && !hasNextPage) return;

    if (refresh) {
      _isRefreshing = true;
      _currentPage = 1;
      _lastPage = 1;
    } else if (loadMore) {
      _isLoadingMore = true;
    } else {
      _isLoading = true;
    }

    _errorMessage = null;
    notifyListeners();

    try {
      if (_currentUserId == null) {
        _errorMessage = 'User ID is not available';
        return;
      }

      final page = refresh ? 1 : (_currentPage + 1);
      final response = await _apiService.index(
        _route,
        config: {
          'refresh': true,
          'params': {
            'page': page,
            'take': 20,
            'filter': {'recipient': _currentUserId, 'type': 'push'},
          },
        },
      );

      final parsed = NotificationListResponse.fromJson(
        Map<String, dynamic>.from(response as Map),
      );

      final incoming = parsed.data;
      if (refresh || page == 1) {
        _apiNotifications = incoming;
      } else {
        for (final item in incoming) {
          final exists = _apiNotifications.any((existing) => existing.id == item.id);
          if (!exists) {
            _apiNotifications.add(item);
          }
        }
      }

      _currentPage = parsed.meta.page.currentPage;
      _lastPage = parsed.meta.page.lastPage;
      _hasUnreadNotification = unreadCount > 0;
      _hasLoadedOnce = true;
    } catch (e) {
      _errorMessage = 'Error loading notifications';
      debugPrint('NotificationProvider loadNotifications Error: $e');
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      _isRefreshing = false;
      notifyListeners();
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

    _showLocalNotification(message);
    _addNotificationToList(message);
    _setHasUnread(true);
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    _setHasUnread(false);
    unawaited(_clearLocalNotifications());
    _openNotifications();
    debugPrint('Navegando a través de notificación: ${message.data}');
  }

  void markAsRead() {
    if (_hasUnreadNotification) {
      _setHasUnread(false);
    }
    unawaited(_clearLocalNotifications());
  }

  void _openNotifications() {
    final context = rootNavigatorKey.currentState?.context;
    if (context == null) return;

    final router = GoRouter.of(context);
    final currentLocation = router.routerDelegate.currentConfiguration.uri.toString();
    if (currentLocation != NotificationRouteNames.notifications) {
      router.push(NotificationRouteNames.notifications);
    }
  }

  Future<void> _clearLocalNotifications() async {
    await _localNotificationsPlugin.cancelAll();
  }

  void _setHasUnread(bool value) {
    _hasUnreadNotification = value;
    notifyListeners();
  }

  void _addNotificationToList(RemoteMessage message) {
    final now = DateTime.now();
    final title = message.notification?.title ?? message.data['title'] ?? 'New notification';
    final body = message.notification?.body ?? message.data['message'] ?? '';

    final appNotification = AppNotification(
      id: int.tryParse(message.data['id']?.toString() ?? '') ?? now.millisecondsSinceEpoch,
      type: message.data['type']?.toString() ?? 'push',
      title: title,
      message: body,
      icon: message.data['icon']?.toString() ?? 'far fa-bell',
      isRead: false,
      link: message.data['link']?.toString(),
      recipient: message.data['recipient']?.toString(),
      mediaFiles: NotificationMediaFiles(),
      sourceData: NotificationSourceData(
        label: 'General',
        icon: 'fa-light fa-bell',
        color: '#2196f3',
        backgroundColor: '#D9D9D9',
      ),
      user: null,
      createdAt: now,
      updatedAt: now,
      timeAgo: 'just now',
    );

    _notifications.insert(
      0,
      PushNotification(
        title: title,
        body: body,
        receivedAt: now,
        data: message.data,
      ),
    );

    _apiNotifications.removeWhere((item) => item.id == appNotification.id);
    _apiNotifications.insert(0, appNotification);
    notifyListeners();
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'] ?? 'New notification';
    final body = message.notification?.body ?? message.data['message'] ?? '';

    await _localNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          ticker: title,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: NotificationRouteNames.notifications,
    );
  }

  @override
  void dispose() {
    _notifications.clear();
    _apiNotifications = [];
    super.dispose();
  }
}