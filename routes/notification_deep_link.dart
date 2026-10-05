import 'dart:convert';

import '../../chat/routes/chat_route_names.dart';

String? resolveNotificationLocation(Map<String, dynamic> data) {
  final source = _findLinkSource(data);
  if (source == null) return null;
  return normalizeNotificationLink(
    _nonEmpty(source['link'])!,
    message: _nonEmpty(source['message']),
  );
}

// Converts the `link` into an internal route (`reminder/3` -> `/reminder/3`).
// Returns `null` for external links (http/https), which are handled by the browser.
// The [message] is passed as a query parameter so that the destination view has it
// even when the URL is stored as text (local payload, PendingDeepLink).
String? normalizeNotificationLink(String link, {String? message}) {
  final uri = Uri.tryParse(link.trim());
  if (uri == null || uri.hasScheme || uri.hasAuthority || uri.path.isEmpty) {
    return null;
  }

  final normalizedChatRoute = _normalizeChatRoute(uri);
  if (normalizedChatRoute != null) {
    return normalizedChatRoute;
  }

  final path = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
  final query = Map<String, String>.from(uri.queryParameters);
  if (message != null && message.isNotEmpty) {
    query.putIfAbsent('message', () => message);
  }
  return Uri(path: path, queryParameters: query.isEmpty ? null : query).toString();
}

String? _normalizeChatRoute(Uri uri) {
  final pathSegments = uri.path.split('/').where((segment) => segment.trim().isNotEmpty).toList();
  if (pathSegments.length < 2 || pathSegments.first.toLowerCase() != 'chat') {
    return null;
  }

  final conversationId = pathSegments[1];
  final contextId = pathSegments.length > 2 ? pathSegments[2] : null;
  if (conversationId.isEmpty) {
    return null;
  }

  final query = <String, String>{'conversationId': conversationId};
  if (contextId != null && contextId.isNotEmpty) {
    query['contextId'] = contextId;
  }
  if (uri.queryParameters.isNotEmpty) {
    query.addAll(uri.queryParameters);
  }

  return Uri(path: ChatRouteNames.chat, queryParameters: query).toString();
}

Map<String, dynamic>? _findLinkSource(Map<String, dynamic> data, [int depth = 0]) {
  if (_nonEmpty(data['link']) != null) return data;

  if (depth >= 3) return null;
  for (final value in data.values) {
    final nested = _asMap(value);
    if (nested == null) continue;
    final found = _findLinkSource(nested, depth + 1);
    if (found != null) return found;
  }
  return null;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is String && value.trim().startsWith('{')) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }
  return null;
}

String? _nonEmpty(dynamic value) {
  if (value is Map || value is List) return null;
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}
