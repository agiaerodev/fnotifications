import 'dart:convert';

String? resolveNotificationLocation(Map<String, dynamic> data) {
  final link = _readLink(data);
  if (link == null) return null;
  return normalizeNotificationLink(link);
}

String? normalizeNotificationLink(String link) {
  final trimmed = link.trim();
  return trimmed.startsWith('/') ? trimmed : null;
}

String? _readLink(Map<String, dynamic> data, [int depth = 0]) {
  final link = _nonEmpty(data['link']);
  if (link != null) return link;

  if (depth >= 3) return null;
  for (final value in data.values) {
    final nested = _asMap(value);
    if (nested == null) continue;
    final found = _readLink(nested, depth + 1);
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
