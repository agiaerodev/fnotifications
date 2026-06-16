import 'package:flutter/material.dart';

class NotificationCard extends StatelessWidget {
  final String title;
  final String description;
  final Map<String, dynamic> data;

  const NotificationCard({
    super.key,
    required this.title,
    required this.description,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    // Extraemos el tipo de la data (por ejemplo: 'info', 'alert', 'success', 'cancel')
    final String type = data['type'] ?? '';

    // Configuramos el estilo basado en la imagen que pasaste
    final config = _getStyleConfig(type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // El Logo estilo circular de tu imagen
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: config.backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              config.icon,
              color: config.iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Texto de la notificación
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blueGrey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _NotificationStyle _getStyleConfig(String type) {
    switch (type) {
      case 'cancel':
        return _NotificationStyle(
          icon: Icons.airplanemode_inactive_rounded,
          iconColor: const Color(0xFFEF5350),
          backgroundColor: const Color(0xFFFFEBEE),
        );
      case 'alert':
        return _NotificationStyle(
          icon: Icons.warning_rounded,
          iconColor: const Color(0xFFFFA726),
          backgroundColor: const Color(0xFFFFF3E0),
        );
      case 'success':
        return _NotificationStyle(
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF66BB6A),
          backgroundColor: const Color(0xFFE8F5E9),
        );
      case 'info':
        return _NotificationStyle(
          icon: Icons.info_rounded,
          iconColor: const Color(0xFF039BE5),
          backgroundColor: const Color(0xFFE1F5FE),
        );
      default:
        return _NotificationStyle(
          icon: Icons.notifications_rounded,
          iconColor: const Color(0xFF0288D1),
          backgroundColor: const Color(0xFFE1F5FE),
        );
    }
  }
}

class _NotificationStyle {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  _NotificationStyle({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });
}