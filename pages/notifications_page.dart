import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_card.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(color: Color(0xFF1E293B)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1E293B)),
      ),
      body: provider.notifications.isEmpty
          ? const Center(
        child: Text(
          "No notifications yet",
          style: TextStyle(color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: provider.notifications.length,
        itemBuilder: (context, index) {
          final notif = provider.notifications[index];

          return NotificationCard(
            title: notif.title,
            description: notif.body,
            data: notif.data,
          );
        },
      ),
    );
  }
}