import 'package:go_router/go_router.dart';
import 'notification_route_names.dart';
import '../pages/notifications_page.dart';


final List<RouteBase> notificationsRoutes = [
  GoRoute(
    path: NotificationRouteNames.notifications,
    builder: (context, state) => const NotificationsPage(),
  ),
];
