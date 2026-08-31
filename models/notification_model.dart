class NotificationListResponse {
  final List<AppNotification> data;
  final NotificationMeta meta;

  NotificationListResponse({
    required this.data,
    required this.meta,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final notifications = <AppNotification>[];
    if (rawData is List) {
      for (final item in rawData) {
        if (item is Map) {
          notifications.add(
            AppNotification.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return NotificationListResponse(
      data: notifications,
      meta: NotificationMeta.fromJson(
        Map<String, dynamic>.from(json['meta'] ?? const {}),
      ),
    );
  }
}

class AppNotification {
  final int id;
  final String type;
  final String title;
  final String message;
  final String? icon;
  final bool isRead;
  final String? link;
  final String? recipient;
  final NotificationMediaFiles mediaFiles;
  final NotificationSourceData sourceData;
  final Map<String, dynamic>? user;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? timeAgo;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
    required this.isRead,
    required this.link,
    required this.recipient,
    required this.mediaFiles,
    required this.sourceData,
    required this.user,
    required this.createdAt,
    required this.updatedAt,
    required this.timeAgo,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: _asInt(json['id']),
      type: (json['type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      icon: json['icon']?.toString(),
      isRead: json['isRead'] == true || json['is_read'] == true,
      link: json['link']?.toString(),
      recipient: json['recipient']?.toString(),
      mediaFiles: NotificationMediaFiles.fromJson(
        Map<String, dynamic>.from(json['mediaFiles'] ?? json['media_files'] ?? const {}),
      ),
      sourceData: NotificationSourceData.fromJson(
        Map<String, dynamic>.from(json['sourceData'] ?? json['source_data'] ?? const {}),
      ),
      user: json['user'] is Map ? Map<String, dynamic>.from(json['user']) : null,
      createdAt: _tryParseDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _tryParseDateTime(json['updatedAt'] ?? json['updated_at']),
      timeAgo: json['timeAgo']?.toString() ?? json['time_ago']?.toString(),
    );
  }
}

class NotificationMediaFiles {
  final NotificationMediaFile? mainimage;

  const NotificationMediaFiles({this.mainimage});

  factory NotificationMediaFiles.fromJson(Map<String, dynamic> json) {
    final rawMainImage = json['mainimage'];
    return NotificationMediaFiles(
      mainimage: rawMainImage is Map
          ? NotificationMediaFile.fromJson(Map<String, dynamic>.from(rawMainImage))
          : null,
    );
  }
}

class NotificationMediaFile {
  final int? id;
  final String? filename;
  final String? mimeType;
  final int? fileSize;
  final String? url;

  const NotificationMediaFile({
    required this.id,
    required this.filename,
    required this.mimeType,
    required this.fileSize,
    required this.url,
  });

  factory NotificationMediaFile.fromJson(Map<String, dynamic> json) {
    return NotificationMediaFile(
      id: _asNullableInt(json['id']),
      filename: json['filename']?.toString(),
      mimeType: json['mimeType']?.toString() ?? json['mime_type']?.toString(),
      fileSize: _asNullableInt(json['fileSize'] ?? json['file_size']),
      url: json['url']?.toString(),
    );
  }
}

class NotificationSourceData {
  final String label;
  final String icon;
  final String color;
  final String backgroundColor;

  const NotificationSourceData({
    required this.label,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  factory NotificationSourceData.fromJson(Map<String, dynamic> json) {
    return NotificationSourceData(
      label: (json['label'] ?? '').toString(),
      icon: (json['icon'] ?? '').toString(),
      color: (json['color'] ?? '').toString(),
      backgroundColor: (json['backgroundColor'] ?? json['background_color'] ?? '').toString(),
    );
  }
}

class NotificationMeta {
  final NotificationPageInfo page;

  const NotificationMeta({required this.page});

  factory NotificationMeta.fromJson(Map<String, dynamic> json) {
    return NotificationMeta(
      page: NotificationPageInfo.fromJson(
        Map<String, dynamic>.from(json['page'] ?? const {}),
      ),
    );
  }
}

class NotificationPageInfo {
  final int total;
  final int lastPage;
  final int perPage;
  final int currentPage;

  const NotificationPageInfo({
    required this.total,
    required this.lastPage,
    required this.perPage,
    required this.currentPage,
  });

  factory NotificationPageInfo.fromJson(Map<String, dynamic> json) {
    return NotificationPageInfo(
      total: _asInt(json['total']),
      lastPage: _asInt(json['lastPage'] ?? json['last_page']),
      perPage: _asInt(json['perPage'] ?? json['per_page']),
      currentPage: _asInt(json['currentPage'] ?? json['current_page']),
    );
  }
}

DateTime? _tryParseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final asString = value.toString().trim();
  if (asString.isEmpty) return null;
  return DateTime.tryParse(asString.replaceFirst(' ', 'T'));
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}
