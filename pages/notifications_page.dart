import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_card.dart';

class _NotificationCardSkeleton extends StatelessWidget {
  const _NotificationCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 12,
                  width: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NotificationProvider>();
      provider.markAsRead();
      provider.loadNotifications(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = context.read<NotificationProvider>();
    if (!provider.hasNextPage || provider.isLoadingMore || provider.isLoading) return;

    if (_scrollController.position.extentAfter < 300) {
      provider.loadNotifications(loadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.apiNotifications;
    final showInitialLoading = !provider.hasLoadedOnce || (provider.isLoading && notifications.isEmpty);

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
      body: RefreshIndicator(
        onRefresh: () => provider.loadNotifications(refresh: true),
        child: showInitialLoading
            ? ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: 6,
                itemBuilder: (context, index) => const _NotificationCardSkeleton(),
              )
            : provider.errorMessage != null && notifications.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Text(
                        provider.errorMessage!,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              )
            : notifications.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 420,
                    child: Center(
                      child: Text(
                        "No notifications yet",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: notifications.length + (provider.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == notifications.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    );
                  }

                  final notif = notifications[index];
                  return NotificationCard(
                    title: notif.title,
                    description: notif.message,
                    data: {
                      'type': notif.type,
                      'timeAgo': notif.timeAgo,
                      'icon': notif.icon ?? notif.sourceData.icon,
                      'sourceIcon': notif.sourceData.icon,
                      'link': notif.link,
                      'sourceLabel': notif.sourceData.label,
                      'sourceColor': notif.sourceData.color,
                      'sourceBackgroundColor': notif.sourceData.backgroundColor,
                      'isRead': notif.isRead,
                    },
                  );
                },
              ),
      ),
    );
  }
}