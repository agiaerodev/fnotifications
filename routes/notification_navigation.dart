import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/pending_deep_link.dart';
import 'notification_route_names.dart';

void openNotificationLocation(GoRouter? router, String? location) {
  final target = location == null || location.isEmpty
      ? NotificationRouteNames.notifications
      : location;

  if (router == null) {
    PendingDeepLink.save(target);
    debugPrint('[PUSH] Navigation deferred until router is ready: $target');
    return;
  }

  final currentUri = router.routerDelegate.currentConfiguration.uri;
  final targetUri = Uri.parse(target);
  debugPrint('[PUSH] Navigation current=$currentUri target=$targetUri');
  if (currentUri != targetUri) {
    router.push(target);
  }
}
