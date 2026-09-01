import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/fa_icon_mapper.dart';
import '../routes/notification_deep_link.dart';

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
    final String type = (data['type'] ?? '').toString();
    final String timeAgo = (data['timeAgo'] ?? '').toString();
    final bool isRead = data['isRead'] == true;
    final config = _getStyleConfig(type);
    final String rawIcon = (data['icon'] ?? data['sourceIcon'] ?? '').toString();
    final String link = (data['link'] ?? '').toString();

    return InkWell(
      onTap: link.isEmpty ? null : () => _openLink(context, link),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: config.backgroundColor,
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 24,
                height: 24,
                child: Center(child: _buildIcon(rawIcon, config)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 Row(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Expanded(
                       child: Text(
                         title,
                         style: TextStyle(
                           fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                           fontSize: 16,
                           color: const Color(0xFF1E293B),
                         ),
                       ),
                     ),
                     if (timeAgo.isNotEmpty) ...[
                       const SizedBox(width: 12),
                       Text(
                         timeAgo,
                         style: TextStyle(
                           fontSize: 12,
                           color: Colors.blueGrey[300],
                         ),
                       ),
                     ],
                   ],
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
      ),
    );
  }

  Widget _buildIcon(String iconClass, _NotificationStyle config) {
    if (iconClass.isNotEmpty && iconClass.contains('fa-')) {
      return FaIcon(
        faIconFromClasses(iconClass, fallback: FontAwesomeIcons.bell),
        color: config.iconColor,
        size: 24,
      );
    }

    return Icon(
      config.icon,
      color: config.iconColor,
      size: 24,
    );
  }

  /// Un `link` interno abre la vista dentro de la app, igual que al tocar el
  /// push; uno http(s) sigue siendo contenido web y va al navegador.
  Future<void> _openLink(BuildContext context, String link) async {
    final location = normalizeNotificationLink(link);
    if (location != null) {
      context.push(location);
      return;
    }

    final uri = Uri.tryParse(link);
    if (uri == null || !uri.hasScheme) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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