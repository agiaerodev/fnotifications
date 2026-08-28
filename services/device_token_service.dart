import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/services/base_api_service.dart';

class DeviceTokenService extends BaseApiService {
  static final DeviceTokenService _instance = DeviceTokenService._internal();
  factory DeviceTokenService() => _instance;
  DeviceTokenService._internal();

  /// Obtiene el FCM token y lo registra en el backend asociado al [userId].
  Future<void> registerDeviceToken(int userId) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('[DeviceTokenService] FCM token no disponible');
        return;
      }

      debugPrint('[DeviceTokenService] Registrando token para userId=$userId');

      final String device = Platform.isIOS ? 'ios' : 'android';

      await postRaw(
        '/notification/v1/devices',
        {
          'attributes': {
            'user_id': userId,
            'device': device,
            'token': fcmToken,
            'provider': 'firebase',
          },
        },
      );

      debugPrint('[DeviceTokenService] Token registrado correctamente');
    } catch (e) {
      debugPrint('[DeviceTokenService] Error al registrar token: $e');
    }
  }
}
